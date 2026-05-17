function gate_queue = random_strategy(N)
% Random boarding: Passengers board in completely random order.
    gate_queue = randperm(N);
end
