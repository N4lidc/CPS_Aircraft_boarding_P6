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
