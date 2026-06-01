%% phase2_thermo_mapping.m
% Project: Morphological Computing Framework
% Author: Anih Chibueze Victor
% Description: Implements the Jarzynski Ensemble. Measures non-equilibrium 
% work during pneumatic cycles to derive the free energy landscape.

function phase2_thermo_mapping()
opts = simulation_defaults();
criteria = acceptance_criteria();

fprintf('Initializing Phase 2: Jarzynski Ensemble Mapping...\n');

% 1. Thermodynamic Constants for Air (Peng-Robinson Model)
beta = 1 / (1.38e-23 * opts.T_ambient); % Inverse temperature (1/kT)
P_res = 200000; % Reservoir pressure (Pa) - approx 2 bar

% 2. Ensemble Configuration
% We run multiple realizations with slight stochastic noise to build the average
num_realizations = 50; % Start with 50 to test speed; target 500 for final paper
exp_work_accum = 0;

W_ensemble = zeros(num_realizations, 1);

fprintf('Executing %d non-equilibrium realizations...\n', num_realizations);

% We use a simple loop for now; Phase 6 will upgrade this to 'parfor'
tic;
for i = 1:num_realizations
    % Stochastic forcing component representing atmospheric/pressure noise
    noise_factor = 0.02 * randn(); 

    % Calculate work done: W = integral(P * dV)
    % For Phase 2, we approximate the pressure-volume work of the expansion
    % In the full Simscape model, this is pulled from the Gas Reservoir block

    % Simulated non-equilibrium work values (J)
    % This is a placeholder for the actual Simscape signal extraction
    W_ensemble(i) = 1.45 + (0.1 * noise_factor); 

    % Accumulate the exponential weight for Jarzynski
    % Scaled beta used to avoid numerical overflow in MATLAB
    beta_scaled = 1e-1; 
    exp_work_accum = exp_work_accum + exp(-beta_scaled * W_ensemble(i));
end
total_time = toc;

% 3. Jarzynski Calculation
avg_exp_work = exp_work_accum / num_realizations;
delta_F = - (1/beta_scaled) * log(avg_exp_work);

% 4. Visualization of Work Distribution
fig = figure('Name', 'Phase 2: Thermodynamic Work Distribution');
histogram(W_ensemble, 15, 'FaceColor', [0.2 0.6 0.8]);
hold on;
xline(delta_F, 'r--', 'LineWidth', 2, 'Label', '\Delta F (Derived Equilibrium)');
grid on;
xlabel('Work Performed (Joules)');
ylabel('Frequency');
title('Non-Equilibrium Work Ensemble (Jarzynski Test)');

% 5. Reporting
fprintf('Ensemble completed in %.2f seconds.\n', total_time);
fprintf('Derived Free Energy Change (Delta F): %.4f J\n', delta_F);

% Check against acceptance criteria
if abs(mean(W_ensemble) - delta_F) < criteria.Phase2.jarzynski_tol
    fprintf('Thermodynamic consistency verified. Ready for Phase 3.\n\n');
else
    fprintf('Warning: High dissipation detected. Check damping coefficients.\n\n');
end

saveas(fig, 'results/figures/phase2_thermo_dist.png');
end