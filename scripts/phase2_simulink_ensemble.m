%% phase2_simulink_ensemble.m
function phase2_simulink_ensemble()
fprintf('Initializing Pure Simulink Jarzynski Ensemble...\n');

% Ensure directory exists to prevent saveas error
if ~exist('results/figures', 'dir')
    mkdir('results/figures');
end

T_ambient = 300; 
beta = 1 / (1.38e-23 * T_ambient);
beta_scaled = 1e-1; 

M = 1000; 
W_all = zeros(M, 1);

if isempty(gcp('nocreate'))
    parpool('local'); 
end

model = 'phase2_pure_simulink';
load_system(model);

fprintf('Running %d parallel simulations...\n', M);

tic;
parfor i = 1:M
    simIn = Simulink.SimulationInput(model);
    simIn = simIn.setModelParameter('StopTime', '2.0');

    % Prevent the parallel workers from fighting over the cache file 

    simIn = simIn.setVariable('noise_seed', randi(100000));

    % Temporarily suppress warnings during the loop to keep the console clean
    warning('off', 'all'); 
    out = sim(simIn);
    warning('on', 'all');

    work_array = out.sim_W;
    W_all(i) = work_array(end); 
end
sim_time = toc;

fprintf('Ensemble complete in %.2f seconds.\n', sim_time);

% --- Jarzynski Calculations ---
exp_neg_beta_W = exp(-beta_scaled * W_all);
avg_exp = mean(exp_neg_beta_W);
Delta_F = - (1/beta_scaled) * log(avg_exp);
avg_W = mean(W_all);
W_diss = avg_W - Delta_F;

% --- Plotting ---
fig = figure('Name', 'Phase 2: Thermodynamic Work Distribution');
histogram(W_all, 25, 'FaceColor', [0.2 0.6 0.8]);
hold on;
xline(Delta_F, 'r--', 'LineWidth', 2);
xline(avg_W, 'k-', 'LineWidth', 1.5);
legend('Work Distribution', 'Free Energy (\Delta F)', 'Avg Work (\langle W \rangle)');
xlabel('Work Performed (Joules)');
ylabel('Frequency');
title(sprintf('Jarzynski Equality (M = %d)', M));
grid on;

fprintf('\n--- Results ---\n');
% Changed formatting to scientific notation (%e) to capture any magnitude
fprintf('Delta F:      %.4e J\n', Delta_F);
fprintf('Average Work: %.4e J\n', avg_W);
fprintf('Dissipation:  %.4e J\n', W_diss);

saveas(fig, 'results/figures/phase2_pure_simulink_hist.png');
end