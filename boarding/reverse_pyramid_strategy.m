function gate_queue = reverse_pyramid_strategy(P, N)
% Reverse pyramid boarding:

    passenger_ids = 1:N;
    seat_numbers = [P.seat_number];
    rows = [P.assigned_row];

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

    % Sort first by seat priority ascending:
    % window -> middle -> aisle
    %
    % Then sort by row descending:
    % back rows -> front rows
    [~, order] = sortrows([seat_priority(:), -rows(:)], [1 2]);

    gate_queue = passenger_ids(order);
end
