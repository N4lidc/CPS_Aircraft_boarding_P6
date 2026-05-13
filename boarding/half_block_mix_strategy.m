function gate_queue = half_block_mix_strategy(P, N, J)
% Half-block mix boarding:
% The aircraft is divided into 10 zones based on:
%   1. row group: front -> back divided into 5 blocks
%   2. side of aisle: left side or right side
%
% The boarding order alternates side while moving diagonally from back to front.
%
% Seat numbers:
% 0 = A, 1 = B, 2 = C, 3 = D, 4 = E, 5 = F
%
% Left side:  A, B, C = seats 0, 1, 2
% Right side: D, E, F = seats 3, 4, 5

    passenger_ids = 1:N;
    rows = [P.assigned_row];
    seats = [P.seat_number];

    % Divide rows into 5 row groups.
    % row_group = 1 means front group.
    % row_group = 5 means back group.
    row_group = min(5, floor((rows - 1) * 5 / J) + 1);

    % Define side of aisle.
    % 1 = left side: A/B/C
    % 2 = right side: D/E/F
    side = zeros(1, N);

    for i = 1:N
        if seats(i) == 0 || seats(i) == 1 || seats(i) == 2
            side(i) = 1;   % left side
        elseif seats(i) == 3 || seats(i) == 4 || seats(i) == 5
            side(i) = 2;   % right side
        else
            error("Invalid seat number for passenger %d: %d", i, seats(i));
        end
    end

    % Each row is one boarding zone:
    % [row_group, side]
    %
    % This follows the diagonal half-block mix pattern:
    % back-left, second-back-right, middle-left, middle-front-right, front-left,
    % then back-right, second-back-left, middle-right, middle-front-left, front-right.
    zone_order = [
        5 1
        4 2
        3 1
        2 2
        1 1
        5 2
        4 1
        3 2
        2 1
        1 2
    ];

    gate_queue = [];

    for z = 1:size(zone_order, 1)
        target_row_group = zone_order(z, 1);
        target_side = zone_order(z, 2);

        zone_passengers = passenger_ids(row_group == target_row_group & side == target_side);

        % Mix passengers inside the same zone
        if ~isempty(zone_passengers)
            zone_passengers = zone_passengers(randperm(length(zone_passengers)));
        end

        gate_queue = [gate_queue, zone_passengers];
    end
end
