function cabinVisu = initCabinVisu(J, N)
% Initialize cabin visualization figure and graphics objects

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
