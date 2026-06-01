% =========================================================================
% PHASE 9.2: JARZYNZKI EQUALITY ENSEMBLE CHECK
% Description: Simulates 100 stochastic trajectories with input noise to
% verify the fluctuation theorems of non-equilibrium soft robotics.
% =========================================================================
clear; clc; close all;

disp('--- INITIALIZING PHASE 9.2: JARZYNZKI THERMODYNAMIC ENSEMBLE ---');

%% 1. CHOOSE THE OPTIMAL BASELINE PARAMETERS (From Edge of Chaos Boundary)
p1 = 4.00;   % Duffing Parameter
p2 = 0.15;   % Damping Ratio
p3 = 2.50;   % Pneumatic forcing
p4 = 0.95;   % Deborah Fluid Number (Locked on the white line transition!)
p5 = 0.05;   % Radial ballooning coupling

%% 2. ENSEMBLE AND STOCHASTIC SETTINGS
N_trajectories = 100; % PRX statistical ensemble minimum
t_end = 40; 
dt = 0.01;
t_span = 0:dt:t_end;
N_steps = length(t_span);

% Generate basic periodic valve signal
omega = 2 * pi * 4.39; 
u_base = double(sin(omega * t_span) >= 0);

% Define fluctuation parameter beta (Inverse variance of environmental noise)
beta_fluid = 2.0; 
noise_intensity = sqrt(2 / beta_fluid);

Work_Ensemble = zeros(N_trajectories, 1);

%% 3. EXECUTE THE FLUCTUATING TRAJECTORIES
disp('Running 100 stochastic thermodynamic simulations...');
options = odeset('RelTol', 1e-4, 'AbsTol', 1e-5);

% Use a standard loop or parfor if parallel tools are active
tic;
for i = 1:N_trajectories
    % Inject a unique noisy fluctuation profile into the valve execution per run
    rng(i); % Unique seed per trajectory
    u_noisy = u_base + noise_intensity * 0.1 * randn(1, N_steps);
    u_interp = @(t) interp1(t_span, u_noisy, t, 'previous', 'extrap');
    
    % Dimensionless System Function
    soft_robot_ode = @(t, Y) [
        Y(2); ...
        -2*p2*Y(2) - Y(1) - p1*Y(1)^3 + p3*Y(3)*(1 + p5*Y(1)) - 1; ...
        (-Y(3) + u_interp(t)) / p4
    ];
    
    Y0 = [-1; 0; 0];
    [t_out, Y_out] = ode15s(soft_robot_ode, t_span, Y0, options);
    
    % Realign grids
    z = interp1(t_out, Y_out(:,1), t_span);
    v = interp1(t_out, Y_out(:,2), t_span);
    P = interp1(t_out, Y_out(:,3), t_span);
    
    % Calculate Thermodynamic Power and Integrate to find Work
    F_p = p3 .* P .* (1 + p5 .* z);
    Power = F_p .* v;
    Work_Ensemble(i) = trapz(t_span, Power);
end
toc;

%% 4. EVALUATE THE JARZYNSKI EQUALITY
% Exponential average of non-equilibrium work
exp_neg_beta_W = mean(edge_exp(-beta_fluid * Work_Ensemble));

% Since we start and stop at identical macroscopic configurations, delta F = 0
delta_F = 0.0; 
jarzynski_residual = abs(log(exp_neg_beta_W) + beta_fluid * delta_F);

disp('==================================================');
disp('THERMODYNAMIC FLUCTUATION INTEGRITY:');
disp(['Average Work Dissipated <W>: ', num2str(mean(Work_Ensemble)), ' Joules']);
disp(['Jarzynski Exp-Average <e^(-beta*W)>: ', num2str(exp_neg_beta_W)]);
disp(['Theoretical Target e^(-beta*DF): ', num2str(exp(-beta_fluid * delta_F))]);
disp(['Jarzynski Statistical Residual Error: ', num2str(jarzynski_residual)]);
disp('==================================================');

%% 5. GENERATE PUBLICATION HISTOGRAM VISUALIZATION
figure('Color', 'w', 'Position', [200, 200, 600, 400]);
hHist = histogram(Work_Ensemble, 15, 'FaceColor', [0.75, 0.15, 0.15], 'EdgeColor', 'w', 'Normalization', 'pdf');
hold on;

% Add labels using the LaTeX interpreter
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);
xlabel('Dissipated Non-Equilibrium Work ($W$)', 'Interpreter', 'latex', 'FontSize', 13);
ylabel('Probability Density Function ($P(W)$)', 'Interpreter', 'latex', 'FontSize', 13);
title('Thermodynamic Work Distribution ($N=100$ runs)', 'Interpreter', 'latex', 'FontSize', 14);

% Draw a vertical line showing the average work done on the soft leg
plot([mean(Work_Ensemble) mean(Work_Ensemble)], [0 max(hHist.Values)*1.1], 'k--', 'LineWidth', 2);
text(mean(Work_Ensemble)*1.02, max(hHist.Values)*0.8, 'Average Work $\langle W \rangle$', ...
     'Interpreter', 'latex', 'FontSize', 11);

grid on;

%% LOCAL PROTECTION FUNCTION
function out = edge_exp(in)
    % Prevents arithmetic overflow scaling errors during massive exponentiation
    in(in > 700) = 700;
    in(in < -700) = -700;
    out = exp(in);
end
%% 6. EXPORT HIGH-RES PRX FIGURES
disp('Exporting Jarzynski Histogram to results/figures/ ...');
exportgraphics(gcf, '../results/figures/Fig3_Jarzynski.pdf', 'ContentType', 'vector');
exportgraphics(gcf, '../results/figures/Fig3_Jarzynski.png', 'Resolution', 300);