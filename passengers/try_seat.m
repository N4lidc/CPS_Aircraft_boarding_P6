function [P, events, seat_occupied, aisle_occupied, KPI] = try_seat(P, events, seat_occupied, aisle_occupied, pid, seat_interference_time, PRIO, t, KPI)
% Try to seat a passenger; if seat is blocked by others, schedule wait event

row = P(pid).assigned_row;
seat = P(pid).seat_number;

% Check if seat is blocked by adjacent passengers (seat interference)
% A passenger blocks if they're already seated in an adjacent seat
seat_blocked = 0;

% Window seats (0, 5) can be blocked by middle seats (1, 4)
if seat == 0
    seat_blocked = (seat_occupied(row+1,2)==1)||(seat_occupied(row+1,3)==1);
elseif seat == 1
    seat_blocked = (seat_occupied(row+1,3)==1);
elseif seat == 4
    seat_blocked = (seat_occupied(row+1,4)==1);
elseif seat == 5
    seat_blocked = (seat_occupied(row+1,4)==1)||(seat_occupied(row+1,5)==1);
end

if seat_blocked == 1
    % Seat is blocked, wait for interference to resolve
    P(pid).state = "WaitingForSeat";
    P(pid).t_seat_wait = t + seat_interference_time;
    if isnan(KPI.waitStartSeat(pid))
        KPI.waitStartSeat(pid) = t;
    end
    KPI.seat_interference_count = KPI.seat_interference_count + 1;
    events = push(events, P(pid).t_seat_wait, PRIO.SEAT, 6, pid);
    fprintf("  BLOCKED_AT_SEAT Pax%d row %d seat %d (wait=%.1f)\n", pid, row, seat, P(pid).t_seat_wait);
else
    % Seat is available, sit down immediately
    if seat_occupied(row+1, seat+1) == 1
        KPI.seat_duplicate_violations = KPI.seat_duplicate_violations + 1;
    end
    seat_occupied(row+1, seat+1) = 1;
    P(pid).state = "Seated";
    P(pid).t_seated = t;
    KPI.t_seated(pid) = t;
    aisle_occupied(P(pid).current_row+1) = 0;
    fprintf("  SEATED Pax%d at row %d seat %d\n", pid, row, seat);
end
end
