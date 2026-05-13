function params = load_params()
% Load all simulation parameters into a struct

% Gate times
params.time_general = 120;
params.time_finalcall = 720;
params.time_close = 900;

% Cadence enum
params.cadence = struct('low', 0.15, 'mid', 0.3, 'high', 0.45);

% Passenger and cabin settings
params.N = 20; % number of passengers
params.J = 10; % number of rows (0, 1, ..., J)
params.scan_time = 2.0; % scan time in seconds
params.lambda = params.cadence.low; % poisson cadence rate
params.walking_time = 1.5; % walking time per row
params.corridor_time = 4 + 4*rand(1, params.N); % between 4-8 seconds (random per passenger)
params.has_luggage = rand(1, params.N) < 0.75; % 75% have luggage
params.luggage_time = 1 + 6*rand(1, params.N); % 1-7 seconds to stow luggage
params.seat_interference_time = 2.0; % time to resolve seat interference

% Boarding eligibility (boarding groups)
params.eligibility = repmat("All", 1, params.N);
params.eligibility(1:3) = "PreboardList";

% Corridor congestion thresholds
params.max_incorridor = 3;
params.resume_incorridor = 1;

% Boarding strategy: "random", "back_to_front", "front_to_back", "outside_in"
params.boarding_strategy = "outside_in";

% Visualization
params.show_visu = (params.J <= 10);

end
