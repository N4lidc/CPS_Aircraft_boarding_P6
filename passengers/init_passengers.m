function P = init_passengers(N, J, has_luggage, luggage_time, assigned_row, seat_number, eligibility)
% Initialize passenger struct array

for i = 1:N
    P(i).state = "AtGate";
    P(i).current_row = NaN;
    P(i).assigned_row = assigned_row(i);
    P(i).seat_number = seat_number(i);
    P(i).has_luggage = has_luggage(i);
    P(i).luggage_time = luggage_time(i);
    P(i).t_move = NaN;
    P(i).t_luggage = NaN;
    P(i).t_seat_wait = NaN;
    P(i).t_seated = NaN;
    P(i).eligibility = eligibility(i);
end

end
