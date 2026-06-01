% =========================================================================
% PHASE 9: THERMODYNAMIC & RESERVOIR COMPUTING ANALYSIS SUITE
% Description: Extracts Work distributions, Memory Capacity (MC), and
% dynamic complexity proxies across the 5D \Pi-parameter space.
% =========================================================================
clear; clc; close all;

disp('--- INITIALIZING PHASE 9: THERMODYNAMIC & MORPHOLOGICAL ANALYSIS ---');

%% 1. LOAD THE SIMULATION DATASET
data_path = '../data/Phase8_Dimensionless_Universe.mat';
if ~exist(data_path, 'file')
    error('Simulation data not found! Please run Phase 8 first.');
end
disp('Loading Dimensionless Universe dataset...');
load(data_path);

[N_sims, N_steps] = size(Z_history);
dt = t_span(2) - t_span(1);

%% 2. PREALLOCATE PERFORMANCE METRICS
Work_done = zeros(N_sims, 1);       % Total thermodynamic work per run
Memory_Capacity = zeros(N_sims, 1); % Reservoir short-term memory capacity
Dynamic_Complexity = zeros(N_sims, 1); % Standard deviation of velocity (Chaos proxy)
Is_Stable = true(N_sims, 1);        % Stability tracker

%% 3. EXECUTE ADVANCED ANALYSIS SUITE
disp('Analyzing 500 trajectories for Energy and Information metrics...');

% Ridge Regression Regularization Parameter (\lambda) from PRX Checklist
lambda_ridge = 1e-4; 

% Define Reservoir Computing parameters
max_delay = 20; % Track memory up to 20 steps back
N_train = round(0.7 * N_steps); % 70% Training split
N_test = N_steps - N_train;     % 30% Testing split

for i = 1:N_sims
    % Extract parameters for the current run
    p1 = Pi_matrix(i,1); p2 = Pi_matrix(i,2); p3 = Pi_matrix(i,3);
    p4 = Pi_matrix(i,4); p5 = Pi_matrix(i,5);
    
    % Grab state histories
    z = Z_history(i, :);
    v = V_history(i, :);
    P = P_history(i, :);
    
    %% CRITERION A: RUN-TIME DIVERGENCE DETECTION
    if max(abs(z)) > 15 || any(isnan(z))
        Is_Stable(i) = false;
        continue;
    end
    
    %% CRITERION B: THERMODYNAMIC WORK CALCULATION (W = \int F_p * dZ)
    P_fluid = p3 .* P .* (1 + p5 .* z);
    Power = P_fluid .* v;
    Work_done(i) = trapz(t_span, Power); 
    
    %% CRITERION C: CHAOTIC LOG-DIVERGENCE METRIC
    Dynamic_Complexity(i) = std(v);
    
    %% CRITERION D: MORPHOLOGICAL COMPUTING (MEMORY CAPACITY)
    States = [z; v]'; 
    
    MC_total = 0;
    for d = 1:max_delay
        target = zeros(N_steps, 1);
        target((d+1):end) = u_input(1:(end-d));
        
        X_train = States(1:N_train, :);
        Y_train = target(1:N_train);
        X_test = States((N_train+1):end, :);
        Y_test = target((N_train+1):end);
        
        W_out = (X_train' * X_train + lambda_ridge * eye(size(X_train,2))) \ (X_train' * Y_train);
        
        Y_pred = X_test * W_out;
        
        mean_test = mean(Y_test);
        mean_pred = mean(Y_pred);
        num = sum((Y_test - mean_test) .* (Y_pred - mean_pred));
        den = sqrt(sum((Y_test - mean_test).^2) * sum((Y_pred - mean_pred).^2));
        
        if den > 0
            r2 = (num / den)^2;
            MC_total = MC_total + r2;
        end
    end
    Memory_Capacity(i) = MC_total;
end

%% 4. FILTER UNSTABLE TRAJECTORIES
Stable_Indices = find(Is_Stable);
disp(['Analysis Complete. Unstable runs discarded: ', num2str(N_sims - length(Stable_Indices))]);

%% 5. GENERATE HIGH-IMPACT PRX VISUALIZATIONS
figure('Color', 'w', 'Position', [100, 100, 1100, 450]);

% PLOT 1: Thermodynamic Space Map
subplot(1,2,1);
scatter(Pi_matrix(Stable_Indices, 1), Work_done(Stable_Indices), 35, Memory_Capacity(Stable_Indices), 'filled');
colorbar; colormap(gca, 'parula');
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);
xlabel('$\Pi_1$ (Duffing Nonlinearity Parameter)', 'Interpreter', 'latex', 'FontSize', 13);
ylabel('Total Thermodynamic Work ($W$)', 'Interpreter', 'latex', 'FontSize', 13);
title('Energy-Information Landscape', 'Interpreter', 'latex', 'FontSize', 14);
grid on;

% PLOT 2: Morphological Computing Edge of Chaos
subplot(1,2,2);
scatter(Dynamic_Complexity(Stable_Indices), Memory_Capacity(Stable_Indices), 35, Pi_matrix(Stable_Indices, 4), 'filled');
hC = colorbar;
ylabel(hC, '$\Pi_4$ (Deborah Fluid Number)', 'Interpreter', 'latex', 'FontSize', 12);
% THE FIX: Changed from custom 'magma' to native native 'hot' colormap
colormap(gca, 'hot'); 
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);
xlabel('Dynamic Volatility ($\sigma_v$)', 'Interpreter', 'latex', 'FontSize', 13);
ylabel('Memory Capacity ($MC$)', 'Interpreter', 'latex', 'FontSize', 13);
title('The "Edge of Chaos" Computation Domain', 'Interpreter', 'latex', 'FontSize', 14);
grid on;

%% 6. SAVE GLOBAL METRICS
save('../data/Phase9_Analyzed_Metrics.mat', 'Work_done', 'Memory_Capacity', 'Dynamic_Complexity', 'Stable_Indices');
disp('Phase 9 complete. Analytical data saved to data folder.');
%% 7. EXPORT HIGH-RES PRX FIGURES
disp('Exporting Energy Landscape to results/figures/ ...');
exportgraphics(gcf, '../results/figures/Fig1_EnergyLandscape.pdf', 'ContentType', 'vector');
exportgraphics(gcf, '../results/figures/Fig1_EnergyLandscape.png', 'Resolution', 300);