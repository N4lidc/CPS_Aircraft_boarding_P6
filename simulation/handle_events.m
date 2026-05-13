function [P, events, aisle_occupied, seat_occupied, corridor_wait, number_incorridor, scan_busy_until, cadence_pending, KPI] = handle_events(type, i, t, P, events, aisle_occupied, seat_occupied, corridor_wait, number_incorridor, gate_queue, global_state, scanner, scan_busy_until, cadence_pending, filter, walking_time, J, PRIO, seat_interference_time, max_incorridor, resume_incorridor, lambda, scan_time, corridor_time, N, KPI)
% Dispatcher for event types 1-6
% Note: gate_queue is passed but should be modified in Main.m since it needs persistent updates

switch type
    case 1 % Cadence release
        cadence_pending = false;
        fprintf("\nt=%.1f cadence_release\n",t);
        if scanner == 0
            fprintf(" scanner down (down haha... get it?)");
        elseif isempty(gate_queue)
            fprintf(" no retard left\n");
        elseif t < scan_busy_until
            events = push(events, scan_busy_until, PRIO.CAD, 1, 0);
            cadence_pending = true;
        else
            eligList = string({P(gate_queue).eligibility});
            eligibleMask = (filter == "All") | (eligList == filter);
            idx = find(eligibleMask, 1, 'first');
            if isempty(idx)
                fprintf(" No eligible pax (filter=%s)\n", filter);
            else
                pid = gate_queue(idx);
                gate_queue(idx) = [];
                fprintf("  START_SCAN Pax%d\n", pid);
                scan_busy_until = t + scan_time;
                events = push(events, scan_busy_until, PRIO.SCAN, 2, pid);
                dt = -log(max(rand(), eps)) / lambda;
                events = push(events, t + dt, PRIO.CAD, 1, 0);
                cadence_pending = true;
            end
        end

    case 2 % Scan done
        fprintf("\nt=%.1f SCAN_DONE Pax%d\n", t, i);
        KPI.n_scanned = KPI.n_scanned + 1;
        number_incorridor = number_incorridor + 1;
        if strcmp(global_state, "General") && number_incorridor >= max_incorridor
            events = push(events, t, PRIO.GLOBAL, 7, 0);
        end
        events = push(events, t + corridor_time(i), PRIO.CORR, 3, i);

    case 3 % Corridor done
        fprintf("\nt=%.1f CORRIDOR_DONE Pax%d\n", t, i);
        if aisle_occupied(1) == 0
            number_incorridor = number_incorridor - 1;
            if number_incorridor < 0
                KPI.negative_counter_violations = KPI.negative_counter_violations + 1;
            end
            if strcmp(global_state, "Hold") && number_incorridor <= resume_incorridor
                events = push(events, t, PRIO.GLOBAL, 7, 0);
            end
            P(i).state = "InAisle";
            P(i).current_row = 0;
            aisle_occupied(1) = 1;
            fprintf("  ENTER_AISLE Pax%d\n", i);
            [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, i, walking_time, J, PRIO, seat_interference_time, KPI);
        else
            P(i).state = "Waiting";
            corridor_wait(end+1) = i;
            if isnan(KPI.waitStartEntry(i))
                KPI.waitStartEntry(i) = t;
            end
            fprintf("  BLOCKED_AT_ENTRY Pax%d\n", i);
        end

    case 4 % Move done
        old = P(i).current_row;
        aisle_occupied(old+1) = 0;
        P(i).current_row = old + 1;
        aisle_occupied(P(i).current_row+1) = 1;
        fprintf("\nt=%.1f MOVE_DONE Pax%d %d->%d\n", t, i, old, P(i).current_row);
        if aisle_occupied(1) == 0 && ~isempty(corridor_wait)
            j = corridor_wait(1); corridor_wait(1) = [];
            number_incorridor = number_incorridor - 1;
            if number_incorridor < 0
                KPI.negative_counter_violations = KPI.negative_counter_violations + 1;
            end
            if strcmp(global_state, "Hold") && number_incorridor <= resume_incorridor
                events = push(events, t, PRIO.GLOBAL, 7, 0);
            end
            P(j).state = "InAisle";
            P(j).current_row = 0;
            aisle_occupied(1) = 1;
            if ~isnan(KPI.waitStartEntry(j))
                KPI.waitTimeEntry(j) = KPI.waitTimeEntry(j) + (t - KPI.waitStartEntry(j));
                KPI.waitStartEntry(j) = NaN;
            end
            fprintf("  UNBLOCK_ENTRY Pax%d\n", j);
            [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, j, walking_time, J, PRIO, seat_interference_time, KPI);
        end

        for k = 1:N
            if P(k).state == "Waiting" && P(k).current_row < P(k).assigned_row && aisle_occupied(P(k).current_row+2) == 0
                [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, k, walking_time, J, PRIO, seat_interference_time, KPI);
            end
        end

        [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, i, walking_time, J, PRIO, seat_interference_time, KPI);

    case 5 % Luggage stowing done
        fprintf("\nt=%.1f LUGGAGE_DONE Pax%d\n", t, i);
        P(i).state = "Seating";
        [P, events, seat_occupied, aisle_occupied, KPI] = try_seat(P, events, seat_occupied, aisle_occupied, i, seat_interference_time, PRIO, t, KPI);
        for k = 1:N
            if P(k).state == "Waiting" && P(k).current_row < P(k).assigned_row && aisle_occupied(P(k).current_row+2) == 0
                [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, k, walking_time, J, PRIO, seat_interference_time, KPI);
            end
        end

    case 6 % Seat interference resolved
        fprintf("\nt=%.1f SEAT_INTERFERENCE_RESOLVED Pax%d\n", t, i);
        if seat_occupied(P(i).assigned_row+1, P(i).seat_number+1) == 1
            KPI.seat_duplicate_violations = KPI.seat_duplicate_violations + 1;
        end
        seat_occupied(P(i).assigned_row+1, P(i).seat_number+1) = 1;
        P(i).state = "Seated";
        P(i).t_seated = t;
        KPI.t_seated(i) = t;
        aisle_occupied(P(i).current_row+1) = 0;
        fprintf("  SEATED Pax%d at row %d seat %d\n", i, P(i).assigned_row, P(i).seat_number);

        if ~isnan(KPI.waitStartSeat(i))
            KPI.waitTimeSeat(i) = KPI.waitTimeSeat(i) + (t - KPI.waitStartSeat(i));
            KPI.waitStartSeat(i) = NaN;
        end

        for k = 1:N
            if P(k).state == "Waiting" && P(k).current_row < P(k).assigned_row && aisle_occupied(P(k).current_row+2) == 0
                [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, k, walking_time, J, PRIO, seat_interference_time, KPI);
            end
        end
end

end
