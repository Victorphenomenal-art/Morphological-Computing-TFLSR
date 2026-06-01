%% phase1_duffing_benchmark.m
% Project: Morphological Computing Framework
% Author: Anih Chibueze Victor
% Description: Isolates a single segment of the soft arm as a forced Duffing 
% oscillator to benchmark numerical solver stability against hyperelasticity.

function phase1_duffing_benchmark()
% Pull baseline solver tolerances from Phase 0 setup
opts = simulation_defaults();

fprintf('Initializing Phase 1: Nonlinear Duffing Benchmark...\n');

% 1. System Parameters (Lumped approximation for Ecoflex 00-30 segment)
m = 0.05;           % Segment mass (kg)
c = 0.15;           % Viscoelastic damping coefficient (N.s/m)
k1 = 180;           % Linear stiffness (N/m) derived from Young's Modulus
k3 = 6500;          % Nonlinear stiffness (N/m^3) representing hyperelastic hardening

% Pneumatic pressure wave modeled as harmonic forcing
F0 = 3.0;           % Forcing amplitude (N)
omega = 1.1 * sqrt(k1/m); % Driving frequency slightly above linear resonance (rad/s)

% 2. Simulation Environment
t_span = [0 60];    % Simulate 60 seconds to capture steady-state
y0 = [0; 0];        % Initial states [displacement; velocity]

% Stiff solver required due to k3 dominance at high displacements
options = odeset('RelTol', opts.rel_tol, 'AbsTol', opts.abs_tol);

% State-space formulation: y(1) = x, y(2) = dx/dt
duffing_ode = @(t, y) [
    y(2);
    (F0*cos(omega*t) - c*y(2) - k1*y(1) - k3*y(1)^3) / m
    ];

% 3. Execute Numerical Benchmark
fprintf('Running ODE15s integration...\n');
tic;
[t, y] = ode15s(duffing_ode, t_span, y0, options);
solve_time = toc;
fprintf('Integration complete: %.3f seconds.\n', solve_time);

x = y(:, 1);
v = y(:, 2);

% 4. Thermodynamic / Energy Analysis
% Total mechanical energy (E = Kinetic + Linear Potential + Nonlinear Potential)
energy = 0.5*m.*v.^2 + 0.5*k1.*x.^2 + 0.25*k3.*x.^4;

% 5. Data Visualization
fig = figure('Name', 'Phase 1: Segment Dynamics', 'Position', [100, 100, 900, 600]);

% Time Series (Transient to Steady State)
subplot(2, 2, [1 2]);
plot(t, x, 'b', 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Displacement (m)');
title('Single Segment Viscoelastic Response');

% Phase Portrait (Checking for chaotic vs. limit cycle behavior)
subplot(2, 2, 3);
plot(x, v, 'r', 'LineWidth', 1);
grid on;
xlabel('Displacement (x)');
ylabel('Velocity (v)');
title('Phase Portrait');

% Energy Dissipation
subplot(2, 2, 4);
plot(t, energy, 'k', 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Total Energy (J)');
title('System Energy Trajectory');

% 6. Save Data and Validate
saveas(fig, 'results/figures/phase1_benchmark.png');
fprintf('Benchmark visualization saved to /results/figures/.\n');

max_disp = max(abs(x));
fprintf('Peak displacement recorded: %.4f m\n', max_disp);

if max_disp > 0.2
    warning('Displacement exceeds physical segment limits. Adjust forcing amplitude (F0).');
else
    fprintf('Phase 1 passed. Solver is stable for hyperelastic integration.\n\n');
end
end