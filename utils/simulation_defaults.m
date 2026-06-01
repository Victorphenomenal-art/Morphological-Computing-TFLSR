%% simulation_defaults.m
% Global simulation parameters and physical constants

function opts = simulation_defaults()
    opts = struct();
    
    % Solver configuration for stiff thermodynamic/mechanical coupled systems
    opts.solver = 'ode15s';      
    opts.max_step = 1e-3;        
    opts.rel_tol = 1e-5;         
    opts.abs_tol = 1e-6;         
    opts.FastRestart = 'on';
    
    % Gas domain constants (Real Gas definition)
    opts.gas_model = 'PengRobinson';   
    opts.T_ambient = 300;               % K
    opts.P_atm = 101325;                % Pa
    
    % Ecoflex 00-30 Hyperelastic parameters
    opts.rho_silicone = 1070;           % kg/m^3
    opts.E_young = 125e3;               % Pa
    opts.nu_poisson = 0.48;             % Incompressible assumption
    
    % Reservoir computing metrics
    opts.readout_lambda = 1e-4;         % Ridge regression regularization
end