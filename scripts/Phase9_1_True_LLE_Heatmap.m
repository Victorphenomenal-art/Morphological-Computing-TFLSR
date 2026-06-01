% =========================================================================
% PHASE 9.1: TRUE LARGEST LYAPUNOV EXPONENT (LLE) 2D CHAOS HEATMAP (TOOLBOX-FREE)
% Method: Twin-Trajectory Renormalization Method
% Description: Maps the exact boundary of the "Edge of Chaos" (\lambda = 0)
% =========================================================================
clear; clc; close all;

disp('--- INITIALIZING PHASE 9.1: TRUE LLE CHAOS MAP ---');

%% 1. GRID CONFIGURATION (PRX High-Resolution)
N_grid = 30; % 30x30 resolution = 900 physical configurations
pi1_vec = linspace(0.01, 10.0, N_grid); % Duffing parameter range
pi4_vec = linspace(0.1, 2.0, N_grid);   % Deborah fluid parameter range

[Pi1_Mesh, Pi4_Mesh] = meshgrid(pi1_vec, pi4_vec);
LLE_Results = zeros(N_grid, N_grid);

% Nominal values for remaining parameters
p2_nominal = 0.15;  % Viscous damping (\zeta)
p3_nominal = 2.50;  % Pneumatic forcing amplitude
p5_nominal = 0.05;  % Radial ballooning coupling

%% 2. SIMULATION TIMESTEP SETTINGS
t_end = 60; 
dt = 0.01;
t_span = 0:dt:t_end;
N_steps = length(t_span);

% THE TOOLBOX FIX: Generating a perfect square wave using pure trigonometry!
omega = 2 * pi * 4.39; 
u_input = double(sin(omega * t_span) >= 0); 
u_interp = @(t) interp1(t_span, u_input, t, 'previous', 'extrap');

%% 3. TWIN-TRAJECTORY ALGORITHM LOOP
disp('Calculating state-space trajectory divergences...');
d0 = 1e-8; % Microscopic initial perturbation separation
options = odeset('RelTol', 1e-5, 'AbsTol', 1e-6);

tic;
for r = 1:N_grid
    for c = 1:N_grid
        p1 = Pi1_Mesh(r,c);
        p4 = Pi4_Mesh(r,c);
        
        % Define the Master Dimensionless System Function
        soft_robot_ode = @(t, Y) [
            Y(2); ...
            -2*p2_nominal*Y(2) - Y(1) - p1*Y(1)^3 + p3_nominal*Y(3)*(1 + p5_nominal*Y(1)) - 1; ...
            (-Y(3) + u_interp(t)) / p4
        ];
        
        % Track divergence step-by-step using renormalization intervals
        Y_base = [-1; 0; 0]; 
        Y_pert = [-1 + d0; 0; 0]; 
        
        lyap_sum = 0;
        eval_intervals = 10; 
        step_len = eval_intervals * dt;
        
        for k = 1:eval_intervals:(N_steps - eval_intervals)
            t_chunk = t_span(k):dt:t_span(k + eval_intervals);
            
            % Simulate Baseline Trajectory
            [~, Y_b_out] = ode15s(soft_robot_ode, t_chunk, Y_base, options);
            % Simulate Perturbed Trajectory
            [~, Y_p_out] = ode15s(soft_robot_ode, t_chunk, Y_pert, options);
            
            % Extract end states of this chunk
            Y_base = Y_b_out(end, :)';
            Y_pert = Y_p_out(end, :)';
            
            % Measure current separation distance
            d_current = norm(Y_base - Y_pert);
            
            if d_current > 0
                lyap_sum = lyap_sum + log(d_current / d0);
                % Renormalize
                Y_pert = Y_base + (d0 / d_current) * (Y_pert - Y_base);
            end
        end
        
        % Final average LLE
        LLE_Results(r,c) = lyap_sum / (N_steps * dt);
    end
    if mod(r, 5) == 0
        disp(['Completed row ', num2str(r), '/', num2str(N_grid)]);
    end
end
toc;

%% 4. SAVE COMPUTE MATRICES
save('../data/Phase9_1_LLE_Landscape.mat', 'Pi1_Mesh', 'Pi4_Mesh', 'LLE_Results');

%% 5. GENERATE HIGH-IMPACT PRX HEATMAP VISUALIZATION
figure('Color', 'w', 'Position', [150, 150, 650, 500]);

% Plot the smooth contour field
[~, hContour] = contourf(Pi1_Mesh, Pi4_Mesh, LLE_Results, 100, 'LineColor', 'none');
hold on;

% Highlight the critical "Edge of Chaos" Boundary Line explicitly (\lambda = 0)
[C, hLine] = contour(Pi1_Mesh, Pi4_Mesh, LLE_Results, [0 0], 'w--', 'LineWidth', 2.5);

hC = colorbar;
ylabel(hC, 'Largest Lyapunov Exponent ($\lambda_{\max}$)', 'Interpreter', 'latex', 'FontSize', 12);

% THE COLORMAP FIX: Custom mathematical symmetric Blue-White-Red matrix layout
col_blue  = [0.15, 0.35, 0.75]; % Stable regime
col_white = [0.95, 0.95, 0.95]; % Edge of Chaos transition
col_red   = [0.75, 0.15, 0.15]; % Chaotic regime
custom_map = [linspace(col_blue(1), col_white(1), 50)', linspace(col_blue(2), col_white(2), 50)', linspace(col_blue(3), col_white(3), 50)';
              linspace(col_white(1), col_red(1), 50)',  linspace(col_white(2), col_red(2), 50)',  linspace(col_white(3), col_red(3), 50)'];
colormap(custom_map);

set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);
xlabel('$\Pi_1$ (Duffing Nonlinearity Parameter)', 'Interpreter', 'latex', 'FontSize', 13);
ylabel('$\Pi_4$ (Deborah Fluid Number)', 'Interpreter', 'latex', 'FontSize', 13);
title('Dynamical Chaos Landscape ($\Pi_1$ vs. $\Pi_4$)', 'Interpreter', 'latex', 'FontSize', 14);

% Add text annotation to the white line
text(4.0, 1.1, 'Edge of Chaos ($\lambda_{\max} \approx 0$)', 'Color', 'w', ...
     'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold', 'Rotation', 15);

grid on;
%% 6. EXPORT HIGH-RES PRX FIGURES
disp('Exporting Chaos Map to results/figures/ ...');
exportgraphics(gcf, '../results/figures/Fig2_ChaosMap.pdf', 'ContentType', 'vector');
exportgraphics(gcf, '../results/figures/Fig2_ChaosMap.png', 'Resolution', 300);