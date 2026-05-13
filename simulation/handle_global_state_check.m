function [global_state, scanner, lambda, filter, events, cadence_pending] = handle_global_state_check(global_state, t, time_finalcall, time_close, scanner, lambda, filter, cadence, number_incorridor, max_incorridor, resume_incorridor, cadence_pending, events, PRIO)
% Handle global state transitions (case 7 event type)

fprintf("\nt=%.1f GLOBAL_STATE_CHECK (current: %s)\n", t, global_state);

switch global_state
    case "Init"
        scanner = 1; lambda = cadence.low; filter = "PreboardList";
        global_state = "Preboard";
        fprintf("Init -> Preboard\n");
        events = push(events, 120, PRIO.GLOBAL, 7, 0);
        events = push(events, 0, PRIO.CAD, 1, 0);

    case "Preboard"
        scanner = 1; lambda = cadence.mid; filter = "All";
        global_state = "General";
        fprintf(" Preboard -> General\n");
        events = push(events, time_finalcall, PRIO.GLOBAL, 7, 0);
        if ~cadence_pending
            events = push(events, t, PRIO.CAD, 1, 0);
            cadence_pending = true;
        end

    case "General"
        if t >= time_finalcall
            scanner = 1; lambda = cadence.high; filter = "All";
            global_state = "FinalCall";
            fprintf("General -> Final Call\n");
            events = push(events, time_close, PRIO.GLOBAL, 7, 0);
        elseif number_incorridor >= max_incorridor
            scanner = 0; lambda = 0; filter = "None";
            global_state = "Hold";
            fprintf("General -> Hold\n");
        end

    case "Hold"
        if t >= time_finalcall
            scanner = 1; lambda = cadence.high; filter = "All";
            global_state = "FinalCall";
            fprintf("Hold -> Final Call\n");
            events = push(events, time_close, PRIO.GLOBAL, 7, 0);
        elseif number_incorridor <= resume_incorridor
            scanner = 1; lambda = cadence.mid; filter = "All";
            global_state = "General";
            fprintf("Hold -> General\n");
            if ~cadence_pending
                events = push(events, t, PRIO.CAD, 1, 0);
                cadence_pending = true;
            end
            events = push(events, t, PRIO.GLOBAL, 7, 0);
        end

    case "FinalCall"
        if t >= time_close
            scanner = 0; lambda = 0; filter = "None";
            global_state = "Closed";
            fprintf("Final Call -> Gate Closed\n");
        else
            scanner = 1; lambda = cadence.high; filter = "All";
            events = push(events, time_close, PRIO.GLOBAL, 7, 0);
            if cadence_pending == false
                events = push(events, t, PRIO.CAD, 1, 0);
                cadence_pending = true;
            end
            fprintf("We remain in FinalCall\n");
        end

    case "Closed"
        scanner = 0; lambda = 0; filter = "None";
end

end
