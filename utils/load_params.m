function params = load_params(seed)
% Load all simulation parameters into a struct

% rng seed
if nargin >= 1 && ~isempty(seed)
	params.seed = seed;
else
	params.seed = 69;
end
rng(params.seed)

% Gate times
params.time_general = 120;
params.time_finalcall = 720;
params.time_close = 900;

% Cadence enum
params.cadence = struct('low', 0.15, 'mid', 0.3, 'high', 0.45);

% Passenger and cabin settings
params.N = 60; % number of passengers
params.J = 10; % number of rows (0, 1, ..., J)
params.lambda = params.cadence.low; % poisson cadence rate

% Truncated normal parameters (passenger-dependent)
params.walking_time_mu = 1.5;
params.walking_time_sigma = 0.3;
params.walking_time_min = 0.8;
params.walking_time_max = 2.5;
params.luggage_time_mu = 4.0;
params.luggage_time_sigma = 1.5;
params.luggage_time_min = 1.0;
params.luggage_time_max = 7.0;

% Uniform parameters (interaction delays)
params.scan_time_min = 1.5;
params.scan_time_max = 2.5;
params.corridor_time_min = 4.0;
params.corridor_time_max = 8.0;
params.seat_interference_time_min = 1.0;
params.seat_interference_time_max = 3.0;

% Passenger-dependent samples
params.walking_time = truncnorm_sample(params.walking_time_mu, params.walking_time_sigma, params.walking_time_min, params.walking_time_max, params.N);
params.scan_time = params.scan_time_min + (params.scan_time_max - params.scan_time_min) * rand(1, params.N);
params.corridor_time = params.corridor_time_min + (params.corridor_time_max - params.corridor_time_min) * rand(1, params.N);
params.has_luggage = rand(1, params.N) < 0.75; % 75% have luggage
params.luggage_time = truncnorm_sample(params.luggage_time_mu, params.luggage_time_sigma, params.luggage_time_min, params.luggage_time_max, params.N);
params.seat_interference_time = params.seat_interference_time_min + (params.seat_interference_time_max - params.seat_interference_time_min) * rand(1, params.N);

% Boarding eligibility (boarding groups)
params.eligibility = repmat("All", 1, params.N);
params.eligibility(1:3) = "PreboardList";

% Corridor congestion thresholds
params.max_incorridor = 3;
params.resume_incorridor = 1;

% Boarding strategy: "random", "back_to_front", "outside_in"
params.boarding_strategy = "steffen";

% Visualization
params.show_visu = (params.J <= 10);

end
