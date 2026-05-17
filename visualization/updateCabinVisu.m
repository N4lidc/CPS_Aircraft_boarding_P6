function updateCabinVisu(cabinVisu, P, seat_occupied, aisle_occupied, t, global_state, gate_queue, corridor_wait)
% Update visualization based on current simulation state

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
