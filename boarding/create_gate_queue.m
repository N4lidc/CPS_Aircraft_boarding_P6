function gate_queue = create_gate_queue(boarding_strategy, P, N)
% Dispatcher for different boarding strategies

    switch lower(string(boarding_strategy))
        case "random"
            gate_queue = random_strategy(N);
        case "back_to_front"
            gate_queue = back_to_front_strategy(P, N);
        case "outside_in"
            gate_queue = outside_in_strategy(P, N);
        otherwise
            error("Unknown boarding strategy: %s", boarding_strategy);
    end
end
