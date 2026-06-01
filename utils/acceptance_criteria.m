%% acceptance_criteria.m
% Rigid constraints for phase validation.

function criteria = acceptance_criteria()
    criteria = struct();
    
    % Thermodynamic constraints
    criteria.Phase2.jarzynski_tol = 0.02;     % Max deviation for free energy convergence
    criteria.Phase2.min_ensemble = 500;       % Minimum trajectories for valid estimator
    
    % Dynamic/RC constraints
    criteria.Phase3.hysteresis_error = 0.15;  % Max NMSE against published cyclic data
    criteria.Phase5.NMSE_threshold = 0.10;    % Required accuracy for read-out layer
    
    % Numerical constraints
    criteria.Phase8.max_energy_drift = 1e-6;  % J/s allowable drift in conservative test
end