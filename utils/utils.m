function events = push(events, time, prio, type, pid)
% Append an event to the event list
events(end+1,:) = [time prio type pid];
end

function [assigned_row, seat_number] = assign_unique_seats(N, J)
% Sample unique seat slots from the full cabin (J rows x 6 seats)
all_slots = randperm(J*6, N); % sample without replacement

assigned_row = ceil(all_slots / 6); % rows are 1..J
seat_number = mod(all_slots - 1, 6); % seats are 0..5
end
