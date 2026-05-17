function gate_queue = outside_in_strategy(P, N)
% Outside-in boarding: Window seats → middle seats → aisle seats.
% Seat numbers: 0=A, 1=B, 2=C, 3=D, 4=E, 5=F
% Window seats: 0, 5 | Middle seats: 1, 4 | Aisle seats: 2, 3

    passenger_ids = 1:N;
    seat_numbers = [P.seat_number];
    seat_priority = zeros(1, N);

    for i = 1:N
        seat = seat_numbers(i);
        if seat == 0 || seat == 5
            seat_priority(i) = 1;   % window seats first
        elseif seat == 1 || seat == 4
            seat_priority(i) = 2;   % middle seats second
        elseif seat == 2 || seat == 3
            seat_priority(i) = 3;   % aisle seats last
        else
            error("Invalid seat number for passenger %d: %d", i, seat);
        end
    end

    [~, order] = sort(seat_priority, "ascend");
    gate_queue = passenger_ids(order);
end
