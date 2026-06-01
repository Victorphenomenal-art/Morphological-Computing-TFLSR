% =========================================================================
% PHASE 8: LATIN HYPERCUBE MONTE CARLO SWEEP OF DIMENSIONLESS SOFT ROBOT
% Description: Simulates the 5-Dimensional \Pi parameter space under 
% pseudo-random binary pneumatic forcing to evaluate Reservoir capability.
% =========================================================================
clear; clc; close all;

disp('--- INITIALIZING PHASE 8: \Pi-SPACE MONTE CARLO SWEEP ---');

%% 1. DEFINE PARAMETER BOUNDS (The Physics Space)
% We sweep the 5 dimensionless groups across physically viable ranges.
N_sims = 500; % Number of Monte Carlo runs (PRX standard: 500-1000)

% Bounds: [Min, Max]
Pi1_bounds = [0.01, 10.0];  % Duffing Parameter (Hyperelasticity)
Pi2_bounds = [0.05, 0.50];  % Damping Ratio (\zeta)
Pi3_bounds = [0.10, 5.00];  % Pneumatic Forcing Ratio
Pi4_bounds = [0.10, 2.00];  % Deborah Number (Fluid Lag vs Mech Period)
Pi5_bounds = [0.00, 0.20];  % Radial Coupling (Ballooning effect)

%% 2. LATIN HYPERCUBE SAMPLING (LHS)
% LHS ensures a beautifully uniform spread across the 5D parameter space
disp('Generating Latin Hypercube Samples...');
rng(42); % Seed for reproducibility
lhs_samples = lhsdesign(N_sims, 5);

% Scale LHS samples to our physical bounds
Pi_matrix = zeros(N_sims, 5);
Pi_matrix(:,1) = Pi1_bounds(1) + lhs_samples(:,1) * (Pi1_bounds(2) - Pi1_bounds(1));
Pi_matrix(:,2) = Pi2_bounds(1) + lhs_samples(:,2) * (Pi2_bounds(2) - Pi2_bounds(1));
Pi_matrix(:,3) = Pi3_bounds(1) + lhs_samples(:,3) * (Pi3_bounds(2) - Pi3_bounds(1));
Pi_matrix(:,4) = Pi4_bounds(1) + lhs_samples(:,4) * (Pi4_bounds(2) - Pi4_bounds(1));
Pi_matrix(:,5) = Pi5_bounds(1) + lhs_samples(:,5) * (Pi5_bounds(2) - Pi5_bounds(1));

%% 3. DEFINE THE INPUT WAVEFORM (Information Injection)
% For Reservoir Computing, we need rich, chaotic input. 
% We use a Pseudo-Random Binary Sequence (PRBS) for the valve u(t).
t_end = 100;       % Total dimensionless time
dt = 0.01;         % Time step
t_span = 0:dt:t_end;
N_steps = length(t_span);

disp('Generating Pseudo-Random Binary Valve Sequence...');
switch_rate = 0.5; % Probability of valve switching state per unit time
u_input = zeros(N_steps, 1);
current_state = 0;
for i = 1:N_steps
    if rand() < (switch_rate * dt)
        current_state = 1 - current_state; % Flip valve state
    end
    u_input(i) = current_state;
end

% Interpolation function for the ODE solver
u_interp = @(t) interp1(t_span, u_input, t, 'previous', 'extrap');

%% 4. EXECUTE MONTE CARLO ODE SIMULATIONS
disp(['Executing ', num2str(N_sims), ' Dimensionless Simulations...']);

% Preallocate storage for Phase 9 Analysis
Z_history = zeros(N_sims, N_steps);
V_history = zeros(N_sims, N_steps);
P_history = zeros(N_sims, N_steps);

tic;
% Use parfor (Parallel For) if you have the Parallel Computing Toolbox
for i = 1:N_sims
    % Extract Pi parameters for this specific run
    p1 = Pi_matrix(i,1); p2 = Pi_matrix(i,2); p3 = Pi_matrix(i,3); 
    p4 = Pi_matrix(i,4); p5 = Pi_matrix(i,5);
    
    % The Master Dimensionless ODE System (Eqs from Phase 7)
    % State vector: Y = [z_tilde; v_tilde; P_tilde]
    % Note: Origin is left at unloaded state; gravity (-1) drives it to static sag.
    soft_robot_ode = @(t, Y) [
        Y(2); % d(z_tilde)/dt
        -2*p2*Y(2) - Y(1) - p1*Y(1)^3 + p3*Y(3)*(1 + p5*Y(1)) - 1; % d(v_tilde)/dt
        (-Y(3) + u_interp(t)) / p4 % d(P_tilde)/dt
    ];
    
    % Initial Conditions: [Static Sag Approx, Zero Vel, Zero Pres]
    Y0 = [-1; 0; 0]; 
    
    % Solve using a stiff solver (ode15s) because fluid/mech timescales vary
    options = odeset('RelTol', 1e-4, 'AbsTol', 1e-5);
    [t_out, Y_out] = ode15s(soft_robot_ode, t_span, Y0, options);
    
    % Interpolate back to fixed time grid to ensure matrix alignment
    Z_history(i,:) = interp1(t_out, Y_out(:,1), t_span);
    V_history(i,:) = interp1(t_out, Y_out(:,2), t_span);
    P_history(i,:) = interp1(t_out, Y_out(:,3), t_span);
    
    if mod(i, 50) == 0
        disp(['Completed run ', num2str(i), '/', num2str(N_sims)]);
    end
end
toc;

%% 5. SAVE THE DATA UNIVERSE FOR PHASE 9
disp('Saving the Simulation Universe...');
% Save one directory up, into the data folder!
save('../data/Phase8_Dimensionless_Universe.mat', 't_span', 'u_input', 'Pi_matrix', ...
    'Z_history', 'V_history', 'P_history');
disp('SUCCESS: Data packaged for Thermodynamic and Lyapunov Analysis.');

%% 6. QUICK VISUALIZATION (Sanity Check)
figure('Color', 'w', 'Position', [100, 100, 900, 400]);
subplot(2,1,1);
plot(t_span, u_input, 'k', 'LineWidth', 1.5);
title('Input: Pseudo-Random Binary Valve Sequence u(\tau)');
ylabel('Valve State'); ylim([-0.2, 1.2]); grid on;

subplot(2,1,2);
% Plot the first 5 Monte Carlo runs to ensure diversity
plot(t_span, Z_history(1:5, :), 'LineWidth', 1);
title('Output: Dimensionless Displacement \tilde{z}(\tau)');
xlabel('Dimensionless Time \tau'); ylabel('\tilde{z}'); grid on;