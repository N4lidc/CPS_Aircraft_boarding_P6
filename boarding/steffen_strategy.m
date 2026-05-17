function gate_queue = steffen_strategy(P, N, J)
% Steffen boarding:
% Passengers board individually using row position, seat position, and row spacing.
%
% Main idea:
%   1. Back rows before front rows
%   2. Window seats before middle seats
%   3. Middle seats before aisle seats
%   4. Passengers are spaced by row so nearby passengers do not board directly after each other
%
% Seat numbers:
%   0 = A, 1 = B, 2 = C, 3 = D, 4 = E, 5 = F
%
% Window seats: A and F = seats 0 and 5
% Middle seats: B and E = seats 1 and 4
% Aisle seats:  C and D = seats 2 and 3

    passenger_ids = 1:N;
    rows = [P.assigned_row];
    seats = [P.seat_number];

    gate_queue = [];

    % Seat order follows window -> middle -> aisle.
    % For each seat type, we handle one side, then the other side.
    seat_order = [0 5 1 4 2 3];

    % First use one row parity, then the other.
    % This creates row spacing.
    %
    % Example for J = 10:
    % parity 0 gives rows 10, 8, 6, 4, 2
    % parity 1 gives rows 9, 7, 5, 3, 1
    parity_order = [mod(J, 2), 1 - mod(J, 2)];

    for s = 1:length(seat_order)
        target_seat = seat_order(s);

        for p = 1:length(parity_order)
            target_parity = parity_order(p);

            for r = J:-1:1
                if mod(r, 2) == target_parity
                    idx = find(rows == r & seats == target_seat);

                    if ~isempty(idx)
                        gate_queue = [gate_queue, passenger_ids(idx)];
                    end
                end
            end
        end
    end
end
