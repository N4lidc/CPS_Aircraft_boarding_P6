clear; clc;

% Add current directory and all subdirectories to path
addpath(pwd, ...
    fullfile(pwd, 'simulation'), ...
    fullfile(pwd, 'passengers'), ...
    fullfile(pwd, 'boarding'), ...
    fullfile(pwd, 'visualization'), ...
    fullfile(pwd, 'utils'));

seed = 69;
rng(seed); % fixed seed for reproducibility

% ===== PARAMETERS (inline to avoid path issues) =====
% Gate times
time_general = 120;
time_finalcall = 720;
time_close = 900;

% Cadence enum
cadence = struct('low', 0.15, 'mid', 0.3, 'high', 0.45);

% Passenger and cabin settings
N = 20; % number of passengers
J = 10; % number of rows (0, 1, ..., J)
scan_time = 2.0; % scan time in seconds
lambda = cadence.low; % poisson cadence rate
walking_time = 1.5; % walking time per row
corridor_time = 4 + 4*rand(1, N); % between 4-8 seconds (random per passenger)
has_luggage = rand(1, N) < 0.75; % 75% have luggage
luggage_time = 1 + 6*rand(1, N); % 1-7 seconds to stow luggage
seat_interference_time = 2.0; % time to resolve seat interference

% Boarding eligibility (boarding groups)
eligibility = repmat("All", 1, N);
eligibility(1:3) = "PreboardList";

% Corridor congestion thresholds
max_incorridor = 3;
resume_incorridor = 1;

% Boarding strategy: "random", "back_to_front", "front_to_back", "outside_in"
boarding_strategy = "back_to_front";

% Visualization
show_visu = (J <= 10);
% ===== END PARAMETERS =====

% Validate cabin capacity
if N > J*6
    error('Cannot assign unique seats: N=%d exceeds total capacity=%d.', N, J*6);
end

% Assign unique seats
[assigned_row, seat_number] = assign_unique_seats(N, J);

% Initialize passengers
P = init_passengers(N, J, has_luggage, luggage_time, assigned_row, seat_number, eligibility);

% KPI tracking
KPI = struct();
KPI.seed = seed;
KPI.params = struct( ...
    'N', N, 'J', J, 'scan_time', scan_time, 'lambda', lambda, ...
    'walking_time', walking_time, 'corridor_time', corridor_time, ...
    'luggage_time', luggage_time, 'seat_interference_time', seat_interference_time, ...
    'time_general', time_general, 'time_finalcall', time_finalcall, 'time_close', time_close, ...
    'max_incorridor', max_incorridor, 'resume_incorridor', resume_incorridor, ...
    'boarding_strategy', boarding_strategy, 'cadence', cadence);
KPI.t_start = NaN;
KPI.t_end = NaN;
KPI.t_seated = nan(1, N);
KPI.boarding_time = NaN;
KPI.gate_close_time = time_close;
KPI.scan_busy_time = 0;
KPI.n_scanned = 0;
KPI.aisle_occ_total = 0;
KPI.aisle_occ_max = 0;
KPI.corridor_load_total = 0;
KPI.corridor_load_max = 0;
KPI.hold_time = 0;
KPI.hold_episodes = 0;
KPI.waitStartAisle = nan(1, N);
KPI.waitStartSeat = nan(1, N);
KPI.waitStartEntry = nan(1, N);
KPI.waitTimeAisle = zeros(1, N);
KPI.waitTimeSeat = zeros(1, N);
KPI.waitTimeEntry = zeros(1, N);
KPI.seat_interference_count = 0;
KPI.aisle_interference_count = 0;
KPI.aisle_binary_violations = 0;
KPI.seat_binary_violations = 0;
KPI.seat_duplicate_violations = 0;
KPI.negative_counter_violations = 0;
KPI.time_backward_violations = 0;
KPI.event_starvation = false;

% Create gate queue
gate_queue = create_gate_queue(boarding_strategy, P, N);

fprintf("\nBoarding strategy: %s\n", boarding_strategy);
fprintf("Gate queue passenger IDs: %s\n", mat2str(gate_queue));
fprintf("Gate queue rows: %s\n", mat2str([P(gate_queue).assigned_row]));
fprintf("Gate queue eligibility: %s\n", strjoin(string({P(gate_queue).eligibility}), ", "));

% Seat occupancy tracking
seat_occupied = zeros(J+1, 6);

% Event list and priorities
events = zeros(0,4);
PRIO.GLOBAL = 0;
PRIO.MOVE = 1;
PRIO.CORR = 2;
PRIO.SCAN = 3;
PRIO.CAD = 4;
PRIO.LUGGAGE = 5;
PRIO.SEAT = 6;

% Push initial event
events = push(events, 0, PRIO.GLOBAL, 7, 0);

% Global state variables
t = 0;
t_prev = 0;
scan_busy_until = 0;
aisle_occupied = zeros(1, J+1);
corridor_wait = [];
number_incorridor = 0;
cadence_pending = false;
global_state = "Init";
scanner = 0;
filter = "None";

% Visualization
if show_visu
    visu = initCabinVisu(J, N);
    updateCabinVisu(visu, P, seat_occupied, aisle_occupied, t, global_state, gate_queue, corridor_wait);
    drawnow;
end

fprintf("\n=== Lets start getting those retards in ===\n")

% Main event loop
while ~isempty(events)
    events = sortrows(events, [1 2]); % sort by time and priority
    e = events(1,:); events(1,:) = [];
    t = e(1); type = e(3); i = e(4);

    dt = t - t_prev;
    if dt < 0
        KPI.time_backward_violations = KPI.time_backward_violations + 1;
        error('Event time went backwards: t=%.3f < t_prev=%.3f', t, t_prev);
    end
    KPI.scan_busy_time = KPI.scan_busy_time + dt * (t_prev < scan_busy_until);
    n_fa = sum(aisle_occupied);
    KPI.aisle_occ_total = KPI.aisle_occ_total + n_fa * dt;
    KPI.aisle_occ_max = max(KPI.aisle_occ_max, n_fa);
    KPI.corridor_load_total = KPI.corridor_load_total + number_incorridor * dt;
    KPI.corridor_load_max = max(KPI.corridor_load_max, number_incorridor);
    if global_state == "Hold"
        KPI.hold_time = KPI.hold_time + dt;
    end

    prev_global_state = global_state;

    if type == 7
        % Handle global state check
        [global_state, scanner, lambda, filter, events, cadence_pending] = handle_global_state_check(global_state, t, time_finalcall, time_close, scanner, lambda, filter, cadence, number_incorridor, max_incorridor, resume_incorridor, cadence_pending, events, PRIO);
    elseif type == 1
        % Cadence release - handle gate_queue locally since it needs modification
        cadence_pending = false;
        fprintf("\nt=%.1f cadence_release\n",t);
        if scanner == 0
            fprintf(" scanner down (down haha... get it?)");
        elseif isempty(gate_queue)
            fprintf(" no retard left\n");
        elseif t < scan_busy_until
            events = push(events, scan_busy_until, PRIO.CAD, 1, 0);
            cadence_pending = true;
        else
            eligList = string({P(gate_queue).eligibility});
            eligibleMask = (filter == "All") | (eligList == filter);
            idx = find(eligibleMask, 1, 'first');
            if isempty(idx)
                fprintf(" No eligible pax (filter=%s)\n", filter);
            else
                pid = gate_queue(idx);
                gate_queue(idx) = [];
                if isnan(KPI.t_start)
                    KPI.t_start = t;
                end
                fprintf("  START_SCAN Pax%d\n", pid);
                scan_busy_until = t + scan_time;
                events = push(events, scan_busy_until, PRIO.SCAN, 2, pid);
                dt = -log(max(rand(), eps)) / lambda;
                events = push(events, t + dt, PRIO.CAD, 1, 0);
                cadence_pending = true;
            end
        end
    else
        % Handle events types 2-6
        [P, events, aisle_occupied, seat_occupied, corridor_wait, number_incorridor, scan_busy_until, cadence_pending, KPI] = handle_events(type, i, t, P, events, aisle_occupied, seat_occupied, corridor_wait, number_incorridor, gate_queue, global_state, scanner, scan_busy_until, cadence_pending, filter, walking_time, J, PRIO, seat_interference_time, max_incorridor, resume_incorridor, lambda, scan_time, corridor_time, N, KPI);
    end

    if prev_global_state ~= "Hold" && global_state == "Hold"
        KPI.hold_episodes = KPI.hold_episodes + 1;
    end

    KPI.aisle_binary_violations = KPI.aisle_binary_violations + sum(~(aisle_occupied == 0 | aisle_occupied == 1));
    KPI.seat_binary_violations = KPI.seat_binary_violations + sum(~(seat_occupied == 0 | seat_occupied == 1), 'all');

    t_prev = t;

    fprintf("  aisle: %s\n", mat2str(aisle_occupied));
    pause(0.2);
    if show_visu && exist('visu', 'var') && isfield(visu, 'fig') && isvalid(visu.fig)
        updateCabinVisu(visu, P, seat_occupied, aisle_occupied, t, global_state, gate_queue, corridor_wait);
        drawnow limitrate;
        pause(0.05);
    end
end

fprintf("\n=== THE RETARDS ARE IN ===\n");

count_seated = sum([P.state] == "Seated");
KPI.count_seated = count_seated;
KPI.all_seated = (count_seated == N);
KPI.no_upstream_left = isempty(gate_queue) && isempty(corridor_wait);

if ~isnan(KPI.t_start)
    if all(~isnan(KPI.t_seated))
        KPI.t_end = max(KPI.t_seated);
    else
        KPI.t_end = t;
    end
else
    KPI.t_end = t;
end

if ~isnan(KPI.t_start) && KPI.t_end >= KPI.t_start
    KPI.boarding_time = KPI.t_end - KPI.t_start;
else
    KPI.boarding_time = NaN;
end

if ~isnan(KPI.boarding_time) && KPI.boarding_time > 0
    KPI.scanner_utilization = KPI.scan_busy_time / KPI.boarding_time;
    KPI.avg_scan_rate = KPI.n_scanned / KPI.boarding_time;
    KPI.aisle_occ_mean = KPI.aisle_occ_total / KPI.boarding_time;
    KPI.corridor_load_mean = KPI.corridor_load_total / KPI.boarding_time;
else
    KPI.scanner_utilization = NaN;
    KPI.avg_scan_rate = NaN;
    KPI.aisle_occ_mean = NaN;
    KPI.corridor_load_mean = NaN;
end

if ~KPI.all_seated && scanner == 1 && ~isempty(gate_queue)
    KPI.event_starvation = (sum(events(:,3) == 1) == 0);
end

fprintf("\nKPI summary: seated=%d/%d, upstream_clear=%d, boarding_time=%.2f\n", KPI.count_seated, N, KPI.no_upstream_left, KPI.boarding_time);
