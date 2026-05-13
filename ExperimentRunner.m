clear; clc;

% Add current directory and all subdirectories to path
addpath(pwd, ...
    fullfile(pwd, 'simulation'), ...
    fullfile(pwd, 'passengers'), ...
    fullfile(pwd, 'boarding'), ...
    fullfile(pwd, 'visualization'), ...
    fullfile(pwd, 'utils'));

% Experiment controls
runs_per_config = 1;
base_seed = 7; %7 og 9 be retarded stefen
show_visualization = true;
show_progress = true;

% Base params for defaults
base_params = load_params(base_seed);

% TODO: replace placeholders with actual sweeps
strategies = {base_params.boarding_strategy};
N_values = base_params.N;
J_values = base_params.J;
lambda_values = base_params.lambda;

summary_rows = struct([]);
summary_idx = 0;
run_rows = struct([]);
run_row_idx = 0;

for s = 1:numel(strategies)
    for n = 1:numel(N_values)
        for j = 1:numel(J_values)
            for l = 1:numel(lambda_values)
                strat = strategies{s};
                N = N_values(n);
                J = J_values(j);
                lambda = lambda_values(l);

                boarding_times = nan(runs_per_config, 1);
                all_seated = false(runs_per_config, 1);
                event_starvation = false(runs_per_config, 1);

                for run_idx = 1:runs_per_config
                    seed = base_seed + run_idx - 1;
                    params = load_params(seed);

                    params.show_visu = show_visualization;
                    params.boarding_strategy = strat;
                    params.N = N;
                    params.J = J;
                    params.lambda = lambda;

                    % Reinitialize passenger-dependent arrays if N changes
                    if numel(params.corridor_time) ~= params.N
                        params.corridor_time = 4 + 4*rand(1, params.N);
                        params.has_luggage = rand(1, params.N) < 0.75;
                        params.luggage_time = 1 + 6*rand(1, params.N);
                        params.eligibility = repmat("All", 1, params.N);
                        params.eligibility(1:min(3, params.N)) = "PreboardList";
                    end

                    options = struct('verbose', false, 'enable_pauses', show_visualization);
                    KPI = run_simulation(params, options);

                    boarding_times(run_idx) = KPI.boarding_time;
                    all_seated(run_idx) = KPI.all_seated;
                    event_starvation(run_idx) = KPI.event_starvation;

                    run_row_idx = run_row_idx + 1;
                    run_rows(run_row_idx).strategy = string(strat);
                    run_rows(run_row_idx).N = N;
                    run_rows(run_row_idx).J = J;
                    run_rows(run_row_idx).lambda = lambda;
                    run_rows(run_row_idx).run_idx = run_idx;
                    run_rows(run_row_idx).seed = KPI.seed;
                    run_rows(run_row_idx).t_start = KPI.t_start;
                    run_rows(run_row_idx).t_end = KPI.t_end;
                    run_rows(run_row_idx).boarding_time = KPI.boarding_time;
                    run_rows(run_row_idx).gate_close_time = KPI.gate_close_time;
                    run_rows(run_row_idx).scan_busy_time = KPI.scan_busy_time;
                    run_rows(run_row_idx).n_scanned = KPI.n_scanned;
                    run_rows(run_row_idx).aisle_occ_total = KPI.aisle_occ_total;
                    run_rows(run_row_idx).aisle_occ_max = KPI.aisle_occ_max;
                    run_rows(run_row_idx).corridor_load_total = KPI.corridor_load_total;
                    run_rows(run_row_idx).corridor_load_max = KPI.corridor_load_max;
                    run_rows(run_row_idx).hold_time = KPI.hold_time;
                    run_rows(run_row_idx).hold_episodes = KPI.hold_episodes;
                    run_rows(run_row_idx).seat_interference_count = KPI.seat_interference_count;
                    run_rows(run_row_idx).aisle_interference_count = KPI.aisle_interference_count;
                    run_rows(run_row_idx).aisle_binary_violations = KPI.aisle_binary_violations;
                    run_rows(run_row_idx).seat_binary_violations = KPI.seat_binary_violations;
                    run_rows(run_row_idx).seat_duplicate_violations = KPI.seat_duplicate_violations;
                    run_rows(run_row_idx).negative_counter_violations = KPI.negative_counter_violations;
                    run_rows(run_row_idx).time_backward_violations = KPI.time_backward_violations;
                    run_rows(run_row_idx).count_seated = KPI.count_seated;
                    run_rows(run_row_idx).all_seated = KPI.all_seated;
                    run_rows(run_row_idx).no_upstream_left = KPI.no_upstream_left;
                    run_rows(run_row_idx).scanner_utilization = KPI.scanner_utilization;
                    run_rows(run_row_idx).avg_scan_rate = KPI.avg_scan_rate;
                    run_rows(run_row_idx).aisle_occ_mean = KPI.aisle_occ_mean;
                    run_rows(run_row_idx).corridor_load_mean = KPI.corridor_load_mean;
                    run_rows(run_row_idx).event_starvation = KPI.event_starvation;

                    run_rows(run_row_idx).t_seated = mat2str(KPI.t_seated);
                    run_rows(run_row_idx).waitStartAisle = mat2str(KPI.waitStartAisle);
                    run_rows(run_row_idx).waitStartSeat = mat2str(KPI.waitStartSeat);
                    run_rows(run_row_idx).waitStartEntry = mat2str(KPI.waitStartEntry);
                    run_rows(run_row_idx).waitTimeAisle = mat2str(KPI.waitTimeAisle);
                    run_rows(run_row_idx).waitTimeSeat = mat2str(KPI.waitTimeSeat);
                    run_rows(run_row_idx).waitTimeEntry = mat2str(KPI.waitTimeEntry);

                    if show_progress && mod(run_idx, 100) == 0
                        fprintf("%s N=%d J=%d lambda=%.3f run %d/%d\n", strat, N, J, lambda, run_idx, runs_per_config);
                    end
                end

                summary_idx = summary_idx + 1;
                summary_rows(summary_idx).strategy = string(strat);
                summary_rows(summary_idx).N = N;
                summary_rows(summary_idx).J = J;
                summary_rows(summary_idx).lambda = lambda;
                summary_rows(summary_idx).runs = runs_per_config;
                summary_rows(summary_idx).seed_base = base_seed;
                summary_rows(summary_idx).boarding_time_mean = mean(boarding_times, 'omitnan');
                summary_rows(summary_idx).boarding_time_std = std(boarding_times, 'omitnan');
                summary_rows(summary_idx).all_seated_rate = mean(all_seated);
                summary_rows(summary_idx).event_starvation_rate = mean(event_starvation);
            end
        end
    end
end

summary_table = struct2table(summary_rows);
run_table = struct2table(run_rows);
output_dir = fullfile(pwd, 'results');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
output_path = fullfile(output_dir, ['experiment_summary_' stamp '.csv']);
writetable(summary_table, output_path);

run_output_path = fullfile(output_dir, ['experiment_runs_' stamp '.csv']);
writetable(run_table, run_output_path);

fprintf("\nSaved summary: %s\n", output_path);
fprintf("Saved runs: %s\n", run_output_path);
