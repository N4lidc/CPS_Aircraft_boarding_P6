function events = push(events, time, prio, type, pid)
% Append an event to the event list
events(end+1,:) = [time prio type pid];
end
