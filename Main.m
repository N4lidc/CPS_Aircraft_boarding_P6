clear; clc;

rng(69); % fixed seed for reproducibility

% Parameters: change/edit/add to these whenever needed

% Gate times

time_general = 120;
time_finalcall = 720;
time_close = 900;

% Cadence enum
cadence = struct('low', 0.15, 'mid', 0.3, 'high', 0.45);

N = 20; % nb of pax
J = 10; % how many rows : 0, 1, ..., J
scan_time = 2.0; % scan time en secondes
lambda = cadence.low; % poisson cadence rate : you decide on this if u want to have low/mid/high. I only took mid as an example
walking_time = 1.5; % again i took the same walking time for all pax, so remember to edit if u take varying walking times
corridor_time = 4+4*rand(1,N); % between 4 and 8 seconds - IMPORTANT: AT THE MOMENT OVERTAKING IS ALLOWED , if u dont want overtaking then take the same corridor time for everyone - dont be surprised if pax 13 appears before pax 12 ye
assigned_row = randi([1,J],1,N); % threesome tehee
has_luggage = rand(1,N) < 0.75; % which passengers have luggage - i took 75% here
luggage_time = 1+6*rand(1,N); % how long to stow luggage - between 1 and 7 seconds
seat_number = randi([0,5],1,N); % seat positions within row (0-5) - please make sure that multiple ppl dont get the same seat assigned to them (I only took random here, and it happens here, maybe cuz the seed is 69 tehee)
seat_interference_time = 2.0; % time to resolve seat interference
eligibility = repmat("All",1,N); eligibility(1:3) = "PreboardList"; % which boarding group is each passenger in? This is for filtering passengers during different boarding phases. ( i put only the first three, make sure to try other possibilities)

delta_idx = 1; % just to keep track of the index when we will have a lot of pax

% global state parameters

t = 0;
scan_busy_until = 0;
aisle_occupied = zeros(1,J+1); % get it? cuz we start from 0 but cant use index 0 in matlab
gate_queue = 1:N; % just the order of the queue in gate. I took 1 to 3 cuz I cba doing randomly. The point is that this is the order of passage of passengers
corridor_wait = []; % I am sure that there are multiple ways of handling this better. So u dont have to stick to this. What i mean by this is just for pax who finished corridoring but cant enter aisle cuz entry is blocked

number_incorridor = 0;
max_incorridor = 3; % i took 3 and 1 to have a hysterisis effect
resume_incorridor = 1;

cadence_pending = false;

% global states 
global_state = "Init";

%TODO: Un-comment: 
cadence_delta = []; % I took the same as in the example I sent u last time (the one in red)


% passengers states

for i = 1:N
    P(i).state = "AtGate"; % they do be waitin at da gate
    P(i).current_row = NaN; % DONT initialize this to 0 CUZ THEY HAVENT REACHED ROW 0 OK ????
    P(i).assigned_row = assigned_row(i); % dis wont change ja?
    P(i).seat_number = seat_number(i); % which seat in the row
    P(i).has_luggage = has_luggage(i); % does passenger have luggage
    P(i).luggage_time = luggage_time(i); % how long to stow
    P(i).t_move = NaN; % same tehee!
    P(i).t_luggage = NaN; % time luggage stowing completes
    P(i).t_seat_wait = NaN; % time seat interference resolves
    P(i).eligibility = eligibility(i); % which boarding group is the passenger in? This is for filtering passengers during different boarding phases. You can set it however you want, I just put None as default
end

% seat occupancy tracking: seat_occupied(row, seat_number)
seat_occupied = zeros(J+1, 6);

% event list

events = zeros(0,4); % here is where you will assign the events in order of happening. I suggest u do it structured : [time, priority, type_id, passenger]. the type_id can be taken as: 1 (cadence release), 2 (scan_done), 3 (corridor_done), 4 (move_done), 5 (luggage_done), 6 (seat_done)

PRIO.GLOBAL = 0;    
PRIO.MOVE = 1; % order of prio. you dont have to stick to this order so change if u need ja?
PRIO.CORR = 2;
PRIO.SCAN = 3;
PRIO.CAD = 4; % CAD is cadence btw ja?
PRIO.LUGGAGE = 5; % luggage stowing done
PRIO.SEAT = 6; % seat interference resolved

% push is a local function to push events with the adequate variables (time, prio, type, pid)
events = push(events,0,PRIO.GLOBAL,7,0);

% now comes the sim. I suggest you take it as a guide so u can have a clear
% structure. Let me know if you have any issues while adapting it ye?

scanner = 0;
filter = "None";

show_visu=(J<=10); % this part is for the visualization, it will help you spot anomalities, at the moment I only do it for a number of rows lower than 10
if show_visu
    visu=initCabinVisu(J,N);
    updateCabinVisu(visu,P,seat_occupied,aisle_occupied,t,global_state,gate_queue,corridor_wait);
    drawnow;
end


fprintf("\n=== Lets start getting those retards in ===\n")

while ~isempty(events)
    events = sortrows(events,[1 2]); % so time and priority
    e = events(1,:); events(1,:) = [];
    t = e(1); type = e(3); i = e(4); % so we extract time, type of event, and id of passengerino

    switch type
        case 1
            cadence_pending=false;
            fprintf("\nt=%.1f cadence_release\n",t);
            if scanner==0
                fprintf(" scanner down (down haha... get it?)");
                continue;
            end
            if isempty(gate_queue)
                fprintf(" no retard left\n");
                continue;
            end
            if t<scan_busy_until
                events=push(events,scan_busy_until,PRIO.CAD,1,0);
                cadence_pending=true;
                continue;
            end
            eligList=string({P(gate_queue).eligibility});
            eligibleMask=(filter=="All")|(eligList==filter);
            idx=find(eligibleMask,1,'first');
            if isempty(idx)
                fprintf(" No eligible retardr (filter=%s)\n",filter);
                continue;
            end
            pid=gate_queue(idx);
            gate_queue(idx)=[];
            fprintf("  START_SCAN Pax%d\n",pid);
            scan_busy_until=t+scan_time;
            events=push(events,scan_busy_until,PRIO.SCAN,2,pid);
            dt=-log(max(rand(),eps))/lambda;
            events=push(events,t+dt,PRIO.CAD,1,0);
            cadence_pending=true;

        case 2 % scan done ye?
            fprintf("\nt=%.1f SCAN_DONE Pax%d\n",t,i);
            number_incorridor = number_incorridor + 1;
            if strcmp(global_state, "General") && number_incorridor >= max_incorridor
                events = push(events, t, PRIO.GLOBAL, 7, 0);
            end
            events = push(events,t+corridor_time(i),PRIO.CORR,3,i); % cuz 3 is corridor done ye?

        case 3 % corriiiiiidoooooooooooooooooooor
            fprintf("\nt=%.1f CORRIDOR_DONE Pax%d\n",t,i);
            if aisle_occupied(1) == 0
                number_incorridor = number_incorridor - 1;
                if strcmp(global_state, "Hold") && number_incorridor <= resume_incorridor
                    events = push(events, t, PRIO.GLOBAL, 7, 0);
                end
                P(i).state = "InAisle"; % update updateson
                P(i).current_row = 0;
                aisle_occupied(1) = 1;
                fprintf("  ENTER_AISLE Pax%d\n",i)
                [P, events, aisle_occupied, seat_occupied] = try_advance(P, events, aisle_occupied, seat_occupied, t, i, walking_time, J, PRIO, seat_interference_time);
            else
                P(i).state = "Waiting";
                corridor_wait(end+1) = i;
                fprintf("  BLOCKED_AT_ENTRY Pax%d\n",i);
            end

        case 4 % I like to move it move it
            old = P(i).current_row;
            aisle_occupied(old+1) = 0;
            P(i).current_row = old + 1;
            aisle_occupied(P(i).current_row+1)=1; % +1 cuz we cant have index 0 remember?
            fprintf("\nt=%.1f MOVE_DONE Pax%d %d->%d\n",t,i,old,P(i).current_row);
            if aisle_occupied(1) == 0 && ~isempty(corridor_wait)
                j = corridor_wait(1); corridor_wait(1) = [];
                number_incorridor=number_incorridor-1;
                if strcmp(global_state,"Hold")&&number_incorridor<=resume_incorridor
                    events=push(events,t,PRIO.GLOBAL,7,0);
                end
                P(j).state = "InAisle";
                P(j).current_row = 0;
                aisle_occupied(1) = 1;
                fprintf("  UNBLOCK_ENTRY Pax%d\n",j);
                [P, events, aisle_occupied, seat_occupied] = try_advance(P, events, aisle_occupied, seat_occupied, t, j, walking_time, J, PRIO, seat_interference_time);
            end

            for k = 1:N
                if P(k).state == "Waiting" && P(k).current_row < P(k).assigned_row && aisle_occupied(P(k).current_row+2) == 0
                    [P, events, aisle_occupied, seat_occupied] = try_advance(P, events, aisle_occupied, seat_occupied, t, k, walking_time, J, PRIO, seat_interference_time);
                end
            end

            [P, events, aisle_occupied, seat_occupied] = try_advance(P, events, aisle_occupied, seat_occupied, t, i, walking_time, J, PRIO, seat_interference_time);

        case 5 % luggage stowing done
            fprintf("\nt=%.1f LUGGAGE_DONE Pax%d\n",t,i);
            P(i).state = "Seating";
            [P, events, seat_occupied, aisle_occupied] = try_seat(P, events, seat_occupied, aisle_occupied, i, seat_interference_time, PRIO, t);
            for k=1:N
                if P(k).state=="Waiting" && P(k).current_row<P(k).assigned_row && aisle_occupied(P(k).current_row+2)==0
                    [P, events, aisle_occupied, seat_occupied] = try_advance(P,events,aisle_occupied,seat_occupied,t,k,walking_time,J,PRIO,seat_interference_time);
                end
            end

        case 6 % seat interference resolved
            fprintf("\nt=%.1f SEAT_INTERFERENCE_RESOLVED Pax%d\n",t,i);
            seat_occupied(P(i).assigned_row+1, P(i).seat_number+1) = 1;
            P(i).state = "Seated";
            aisle_occupied(P(i).current_row+1) = 0;
            fprintf("  SEATED Pax%d at row %d seat %d\n",i,P(i).assigned_row,P(i).seat_number);

            for k = 1:N
                if P(k).state == "Waiting" && P(k).current_row < P(k).assigned_row && aisle_occupied(P(k).current_row+2) == 0
                    [P, events, aisle_occupied, seat_occupied] = try_advance(P, events, aisle_occupied, seat_occupied, t, k, walking_time, J, PRIO, seat_interference_time);
                end
            end

        case 7  % Global state transition check
        fprintf("\nt=%.1f GLOBAL_STATE_CHECK (current: %s)\n", t, global_state);
        switch global_state 
            case "Init" 
                scanner = 1; lambda = cadence.low; filter = "PreboardList";
                global_state = "Preboard";
                fprintf("Init -> Preboard\n");
                events = push(events,time_general,PRIO.GLOBAL,7,0);
                events = push(events,0,PRIO.CAD,1, 0);
            case "Preboard"
                scanner = 1; lambda = cadence.mid; filter = "All";
                global_state = "General";
                fprintf(" Preboard -> General\n");
                events = push(events,time_finalcall,PRIO.GLOBAL,7,0);
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
                if  t >= time_finalcall
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
                % scanner = 0; lambda = 0; filter = "None";
                % global_state = "Closed";
                % fprintf("Final Call -> Gate Closed\n");
                if t>=time_close
                    scanner=0;lambda=0;filter="None";
                    global_state="Closed";
                    fprintf("Final Call -> Gate Closed\n");
                else
                    scanner=1;lambda=cadence.high;filter="All";
                    events=push(events,time_close,PRIO.GLOBAL,7,0);
                    if cadence_pending==false
                        events=push(events,t,PRIO.CAD,1,0);
                        cadence_pending=true;
                    end
                    fprintf("We remain in FinalCall\n");
                end
            case "Closed"
                scanner = 0; lambda = 0; filter = "None";
        end
    end
    fprintf("  aisle: %s\n",mat2str(aisle_occupied));
    pause(0.2);
    if show_visu&&exist('visu','var')&&isfield(visu,'fig')&&isvalid(visu.fig) %for visualization
        updateCabinVisu(visu,P,seat_occupied,aisle_occupied,t,global_state,gate_queue,corridor_wait);
        drawnow limitrate;
        pause(0.05);
    end
end

fprintf("\n=== THE RETARDS ARE IN ===\n"); % Ofc you need to add the other states and events ye?

seatedCount=sum(arrayfun(@(p)p.state=="Seated",P));
fprintf("Number of retards seated: %d/%d\n",seatedCount,N);

% I used a local function (the one called try_advance). local functions as
% a rule go at the end of the script

function [P, events, aisle_occupied, seat_occupied] = try_advance(P, events, aisle_occupied, seat_occupied, t, pid, walking_time, J, PRIO, seat_interference_time)

if P(pid).current_row == P(pid).assigned_row
    P(pid).state = "AtRow";
    fprintf("  AT_ROW Pax%d\n",pid);

    % check if passenger has luggage to stow
    if P(pid).has_luggage == 1
        P(pid).state = "StowingLuggage";
        P(pid).t_luggage = t + P(pid).luggage_time;
        events = push(events, P(pid).t_luggage, PRIO.LUGGAGE, 5, pid); % 5 is luggage done
        fprintf("STOWING_LUGGAGE Pax%d (done=%.1f)\n", pid, P(pid).t_luggage);
    else
        % no luggage, go directly to seating
        P(pid).state = "Seating";
        [P, events, seat_occupied, aisle_occupied] = try_seat(P, events, seat_occupied, aisle_occupied, pid, seat_interference_time, PRIO, t);
        % try to seat immediately (will wait if seat is blocked)
    end
    return;
end

nextPos = P(pid).current_row + 1;
if nextPos <= J && aisle_occupied(nextPos+1) == 0
    P(pid).state = "Advance";
    P(pid).t_move = t + walking_time;
    events = push(events, P(pid).t_move, PRIO.MOVE, 4, pid); % 4 cuz move done ye?
    fprintf("  ADVANCE_START Pax%d %d->%d (move_done=%.1f)\n", pid, P(pid).current_row, nextPos, P(pid).t_move);
else
    P(pid).state = "Waiting";
    fprintf("  WAITING_IN_DA_AISLE Pax%d at %d\n", pid, P(pid).current_row);
end
end

function [P, events, seat_occupied, aisle_occupied] = try_seat(P, events, seat_occupied, aisle_occupied, pid, seat_interference_time, PRIO, t)
% Try to seat a passenger; if seat is blocked by others, schedule wait event

row = P(pid).assigned_row;
seat = P(pid).seat_number;

% check if seat is blocked by adjacent passengers (seat interference)
% A passenger blocks if theyre already seated in an adjacent seat
seat_blocked = 0;

% Window seats (0, 5) can be blocked by middle seats (1, 4) if passenger is in aisle seat position
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
    % seat is blocked, wait for interference to resolve
    P(pid).state = "WaitingForSeat";
    P(pid).t_seat_wait = t + seat_interference_time;
    events = push(events, P(pid).t_seat_wait, PRIO.SEAT, 6, pid); % 6 is seat done
    fprintf("  BLOCKED_AT_SEAT Pax%d row %d seat %d (wait=%.1f)\n", pid, row, seat, P(pid).t_seat_wait);
else
    % seat is available, sit down immediately
    seat_occupied(row+1, seat+1) = 1;
    P(pid).state = "Seated";
    aisle_occupied(P(pid).current_row+1) = 0; % free the aisle
    fprintf("  SEATED Pax%d at row %d seat %d\n", pid, row, seat);
end
end

function events = push(events, time, prio, type, pid)
events(end+1,:) = [time prio type pid];
end

function cabinVisu = initCabinVisu(J, N) %handler for visualization
    cabinVisu.J = J;
    cabinVisu.N = N;
    cabinVisu.xSeat = [1 2 3 5 6 7];
    cabinVisu.xAisle = 4;
    cabinVisu.fig = figure('Name','Cabin Layout Visualization','Color','w');
    cabinVisu.ax = axes(cabinVisu.fig); hold(cabinVisu.ax,'on');
    axis(cabinVisu.ax,'equal'); box(cabinVisu.ax,'on');
    xlim(cabinVisu.ax, [0.2 7.8]);
    ylim(cabinVisu.ax, [-0.5 J+0.8]);
    cabinVisu.ax.XTick = 1:7;
    cabinVisu.ax.YTick = 0:J;
    cabinVisu.ax.YDir = 'reverse';
    colLabels = {'A','B','C','|','D','E','F'};
    for x = 1:7
        text(cabinVisu.ax, x, -0.35, colLabels{x}, 'HorizontalAlignment','center','FontWeight','bold', 'FontSize', 10);
    end
    xlabel(cabinVisu.ax, 'Seat columns (3-3) and aisle');
    title(cabinVisu.ax, 't = 0.0 s');
    cabinVisu.seatRect = gobjects(J,6);
    for r = 1:J
        for s = 1:6
            xs = cabinVisu.xSeat(s);
            cabinVisu.seatRect(r,s) = rectangle(cabinVisu.ax,'Position', [xs-0.40, r-0.40, 0.80, 0.80],'EdgeColor', [0 0 0],'FaceColor', [0.96 0.96 0.96],'LineWidth', 1.0);
        end
        text(cabinVisu.ax, 0.35, r, sprintf('%d', r),'HorizontalAlignment','center', 'FontSize', 9);
    end
    cabinVisu.aisleStrip = rectangle(cabinVisu.ax,'Position', [cabinVisu.xAisle-0.25, 0.6, 0.50, J-0.2],'FaceColor', [0.98 0.98 0.98],'EdgeColor', [0.8 0.8 0.8],'LineStyle', '--');
    cmap = lines(max(N,3));
    cabinVisu.pDot  = gobjects(1,N);
    cabinVisu.pText = gobjects(1,N);
    for i = 1:N
        cabinVisu.pDot(i) = scatter(cabinVisu.ax, NaN, NaN, 180, cmap(i,:),'filled', 'MarkerEdgeColor','k', 'LineWidth',1.0);
        cabinVisu.pText(i) = text(cabinVisu.ax, NaN, NaN, sprintf('P%d', i),'HorizontalAlignment','center', 'VerticalAlignment','middle','Color','w', 'FontWeight','bold', 'FontSize', 8);
    end
    cabinVisu.statusText = text(cabinVisu.ax, 0.35, 0.20, '','FontSize', 10, 'FontWeight','bold', 'Color', [0.1 0.1 0.1]);
    cabinVisu.gateText = text(cabinVisu.ax, 0.35, 0.45, '','FontSize', 10, 'FontWeight','bold', 'Color', [0.1 0.1 0.1]);
    cabinVisu.corrText = text(cabinVisu.ax, 0.35, 0.70, '','FontSize', 10, 'FontWeight','bold', 'Color', [0.1 0.1 0.1]);
end




function updateCabinVisu(cabinVisu, P, seat_occupied, aisle_occupied, t, global_state, gate_queue, corridor_wait) %handler for visualization
    J = cabinVisu.J;
    N = cabinVisu.N;
    title(cabinVisu.ax, sprintf('t = %.1f s    Global: %s', t, string(global_state)));
    for r = 1:J
        for s = 1:6
            if seat_occupied(r+1, s) == 1
                cabinVisu.seatRect(r,s).FaceColor = [0.75 0.90 0.75];
            else
                cabinVisu.seatRect(r,s).FaceColor = [0.96 0.96 0.96];
            end
        end
    end
    occCount = sum(aisle_occupied);
    cabinVisu.statusText.String = sprintf('Total aisle occupancy n_{fa} = %d', occCount);
    cabinVisu.gateText.String = sprintf('Gate queue: %d', numel(gate_queue));
    cabinVisu.corrText.String = sprintf('Corridor wait: %d', numel(corridor_wait));
    for i = 1:N
        show = false;
        x = NaN; y = NaN;
        if isfield(P(i),'state')
            st = P(i).state;
        else
            st = "";
        end
        if st == "Seated"
            r = P(i).assigned_row;
            s0 = P(i).seat_number;
            s = s0 + 1;
            if r >= 1 && r <= J && s >= 1 && s <= 6
                x = cabinVisu.xSeat(s);
                y = r;
                show = true;
            end
        elseif isfield(P(i),'current_row') && ~isnan(P(i).current_row)
            y = max(0.6, P(i).current_row);
            x = cabinVisu.xAisle;
            show = true;
        end
        if show
            cabinVisu.pDot(i).XData = x;
            cabinVisu.pDot(i).YData = y;
            cabinVisu.pText(i).Position = [x, y, 0];
            if st == "Waiting" || st == "WaitingForSeat"
                cabinVisu.pDot(i).MarkerEdgeColor = [0.85 0.2 0.2];
                cabinVisu.pDot(i).LineWidth = 2.0;
            elseif st == "Advance"
                cabinVisu.pDot(i).MarkerEdgeColor = [0.2 0.6 0.2];
                cabinVisu.pDot(i).LineWidth = 2.0;
            else
                cabinVisu.pDot(i).MarkerEdgeColor = 'k';
                cabinVisu.pDot(i).LineWidth = 1.0;
            end
            cabinVisu.pDot(i).Visible = 'on';
            cabinVisu.pText(i).Visible = 'on';
        else
            cabinVisu.pDot(i).Visible = 'off';
            cabinVisu.pText(i).Visible = 'off';
        end
    end
end