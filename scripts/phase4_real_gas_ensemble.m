%% phase4_real_gas_ensemble.m
function phase4_real_gas_ensemble()
fprintf('Initializing Phase 4: Simscape Real Gas Ensemble...\n');

if ~exist('results/figures', 'dir')
    mkdir('results/figures');
end

T_ambient = 300; 
beta = 1 / (1.38e-23 * T_ambient);
beta_scaled = 1e-1; 

M = 100; % Reduced to 100 for the first run, real gas is computationally heavy
W_all = zeros(M, 1);

if isempty(gcp('nocreate'))
    parpool('local'); 
end

model = 'phase4_real_gas';
load_system(model);

fprintf('Running %d parallel simulations with Peng-Robinson fluid dynamics...\n', M);

tic;
parfor i = 1:M
    simIn = Simulink.SimulationInput(model);
    simIn = simIn.setModelParameter('StopTime', '2.0');

    % Injecting thermodynamic noise into the mass flow step time
    noise_time = 0.1 + (0.02 * randn());
    simIn = simIn.setBlockParameter([model '/Step'], 'Time', num2str(noise_time));

    warning('off', 'all'); 
    out = sim(simIn);
    warning('on', 'all');

    work_array = out.sim_W;
    W_all(i) = work_array(end); 
end
sim_time = toc;

% --- Jarzynski Calculations ---
exp_neg_beta_W = exp(-beta_scaled * W_all);
avg_exp = mean(exp_neg_beta_W);
Delta_F = - (1/beta_scaled) * log(avg_exp);
avg_W = mean(W_all);
W_diss = avg_W - Delta_F;

% --- Plotting ---
fig = figure('Name', 'Phase 4: Real Gas Thermodynamic Distribution');
histogram(W_all, 15, 'FaceColor', [0.4 0.7 0.4]); % Green for real gas
hold on;
xline(Delta_F, 'r--', 'LineWidth', 2);
xline(avg_W, 'k-', 'LineWidth', 1.5);
legend('Work Distribution', 'Free Energy (\Delta F)', 'Avg Work (\langle W \rangle)');
xlabel('Work Performed (Joules)');
ylabel('Frequency');
title('Jarzynski Equality (Peng-Robinson Gas + Bouc-Wen)');
grid on;

fprintf('\n--- Phase 4 Results ---\n');
fprintf('Delta F:      %.4e J\n', Delta_F);
fprintf('Average Work: %.4e J\n', avg_W);
fprintf('Dissipation:  %.4e J\n', W_diss);
fprintf('Total execution time: %.2f seconds\n', sim_time);

saveas(fig, 'results/figures/phase4_real_gas_hist.png');
end