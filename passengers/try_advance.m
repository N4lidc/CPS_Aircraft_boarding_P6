function [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, pid, walking_time, J, PRIO, seat_interference_time, KPI)
% Attempt to move a passenger forward in the aisle or start luggage stowing

if P(pid).current_row == P(pid).assigned_row
    P(pid).state = "AtRow";
    fprintf("  AT_ROW Pax%d\n",pid);

    % Check if passenger has luggage to stow
    if P(pid).has_luggage == 1
        P(pid).state = "StowingLuggage";
        P(pid).t_luggage = t + P(pid).luggage_time;
        events = push(events, P(pid).t_luggage, PRIO.LUGGAGE, 5, pid);
        fprintf("STOWING_LUGGAGE Pax%d (done=%.1f)\n", pid, P(pid).t_luggage);
    else
        % No luggage, go directly to seating
        P(pid).state = "Seating";
        [P, events, seat_occupied, aisle_occupied, KPI] = try_seat(P, events, seat_occupied, aisle_occupied, pid, seat_interference_time, PRIO, t, KPI);
        if P(pid).state == "Seated"
            % Aisle opened immediately; re-check waiting passengers now.
            for k = 1:numel(P)
                if P(k).state == "Waiting" && P(k).current_row < P(k).assigned_row && aisle_occupied(P(k).current_row+2) == 0
                    [P, events, aisle_occupied, seat_occupied, KPI] = try_advance(P, events, aisle_occupied, seat_occupied, t, k, walking_time, J, PRIO, seat_interference_time, KPI);
                end
            end
        end
    end
    return;
end

nextPos = P(pid).current_row + 1;
if nextPos <= J && aisle_occupied(nextPos+1) == 0
    P(pid).state = "Advance";
    if ~isnan(KPI.waitStartAisle(pid))
        KPI.waitTimeAisle(pid) = KPI.waitTimeAisle(pid) + (t - KPI.waitStartAisle(pid));
        KPI.waitStartAisle(pid) = NaN;
    end
    P(pid).t_move = t + walking_time;
    events = push(events, P(pid).t_move, PRIO.MOVE, 4, pid);
    fprintf("  ADVANCE_START Pax%d %d->%d (move_done=%.1f)\n", pid, P(pid).current_row, nextPos, P(pid).t_move);
else
    P(pid).state = "Waiting";
    if ~isnan(P(pid).current_row) && isnan(KPI.waitStartAisle(pid))
        KPI.waitStartAisle(pid) = t;
        KPI.aisle_interference_count = KPI.aisle_interference_count + 1;
    end
    fprintf("  WAITING_IN_DA_AISLE Pax%d at %d\n", pid, P(pid).current_row);
end
end
