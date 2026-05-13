function gate_queue = create_gate_queue(boarding_strategy, P, N, J)
% Dispatcher for different boarding strategies

    switch lower(string(boarding_strategy))
        case "random"
            gate_queue = random_strategy(N);
        case "back_to_front"
            gate_queue = back_to_front_strategy(P, N);
        case "outside_in"
            gate_queue = outside_in_strategy(P, N);
        case "reverse_pyramid"
            gate_queue = reverse_pyramid_strategy(P, N);
        case "half_block_mix"
            gate_queue = half_block_mix_strategy(P, N, J);
        case "steffen"
            gate_queue = steffen_strategy(P, N, J);
        otherwise
            error("Unknown boarding strategy: %s", boarding_strategy);
    end
end
