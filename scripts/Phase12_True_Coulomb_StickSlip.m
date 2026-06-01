% Phase12_True_Coulomb_StickSlip.m
% ---------------------------------------------------------
% 1. Initialization & Parameters
% ---------------------------------------------------------
% Physical parameters for soft silicone actuator
k1 = 500;       % Linear stiffness (N/m)
k3 = 15000;     % Cubic hyperelastic stiffness (N/m^3)
b  = 5;         % Structural viscous damping (N.s/m)
A0 = 0.001;     % Internal cross-sectional area (m^2)
alpha = 0.1;    % Radial Poisson expansion coefficient
g = 9.81;       % Gravity (m/s^2)

% Masses
mp = 0.2;       % Payload mass at the front (kg)
mf = 0.05;      % Foot mass at the rear (kg)

% Friction Coefficients (Mechanical Diode)
mu_s = 0.8;     % High static friction (grip)
mu_k = 0.4;     % Kinetic friction (slide)

% Initial Conditions: [X_payload, V_payload, X_foot, V_foot]
Y0 = [0, 0, 0, 0]; 
t_start = 0;
t_final = 5; % Total simulation time (5 seconds)
current_state = 'STICK'; % The robot starts anchored

% Arrays to store the combined results
T_out = [];
Y_out = [];

% ---------------------------------------------------------
% 2. The Hybrid State Machine (Main Loop)
% ---------------------------------------------------------
while t_start < t_final
    
    if strcmp(current_state, 'STICK')
        options = odeset('Events', @(t,Y) event_trigger_slip(t, Y, k1, k3, A0, alpha, mu_s, mf, g));
        [t, y, te, ye, ie] = ode45(@(t,Y) ode_stick(t, Y, k1, k3, b, A0, alpha, mp), [t_start t_final], Y0, options);
        
        T_out = [T_out; t];
        Y_out = [Y_out; y];
        
        if ~isempty(te)
            current_state = 'SLIP';
            t_start = te(end);
            Y0 = ye(end, :); 
        else
            break; 
        end
        
    elseif strcmp(current_state, 'SLIP')
        options = odeset('Events', @event_trigger_stick);
        [t, y, te, ye, ie] = ode45(@(t,Y) ode_slip(t, Y, k1, k3, b, A0, alpha, mp, mf, mu_k, g), [t_start t_final], Y0, options);
        
        T_out = [T_out; t];
        Y_out = [Y_out; y];
        
        if ~isempty(te)
            current_state = 'STICK';
            t_start = te(end);
            Y0 = ye(end, :); 
            Y0(4) = 0; % Hard-lock foot velocity to zero to prevent numerical drift
        else
            break; 
        end
    end
end

% ---------------------------------------------------------
% Plot the Stick-Slip Locomotion Results
% ---------------------------------------------------------
figure('Name', 'True Coulomb Stick-Slip Locomotion', 'Color', 'w');
plot(T_out, Y_out(:,1), 'b-', 'LineWidth', 2); hold on;
plot(T_out, Y_out(:,3), 'r--', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Global Position (m)');
legend('Payload Position (X_p)', 'Foot Position (X_f)', 'Location', 'NorthWest');
title('Macroscopic Translation via Stick-Slip Friction');
grid on;

% ---------------------------------------------------------
% 3. The ODE Functions
% ---------------------------------------------------------
function dYdt = ode_stick(t, Y, k1, k3, b, A0, alpha, mp)
    Xp = Y(1); Vp = Y(2); Xf = Y(3); Vf = Y(4);
    
    z = Xp - Xf;
    dz = Vp - Vf;
    P_val = get_pressure(t); 
    F_int = P_val*A0*(1 + alpha*z) - k1*z - k3*(z^3) - b*dz;
    
    dXp_dt = Vp;
    dVp_dt = F_int / mp;
    dXf_dt = 0; 
    dVf_dt = 0; 
    
    dYdt = [dXp_dt; dVp_dt; dXf_dt; dVf_dt];
end

function dYdt = ode_slip(t, Y, k1, k3, b, A0, alpha, mp, mf, mu_k, g)
    Xp = Y(1); Vp = Y(2); Xf = Y(3); Vf = Y(4);
    
    z = Xp - Xf;
    dz = Vp - Vf;
    P_val = get_pressure(t); 
    F_int = P_val*A0*(1 + alpha*z) - k1*z - k3*(z^3) - b*dz;
    
    dXp_dt = Vp;
    dVp_dt = F_int / mp;
    dXf_dt = Vf;
    dVf_dt = (-F_int - (mu_k * mf * g)) / mf; 
    
    dYdt = [dXp_dt; dVp_dt; dXf_dt; dVf_dt];
end

% ---------------------------------------------------------
% 4. Thermodynamic Pressure Input
% ---------------------------------------------------------
function P = get_pressure(t)
    % 1 Hz pneumatic pulsing to drive the robot
    Pmax = 120000; % 120 kPa
    freq = 1;      % 1 Hz
    
    % Rectified sine wave mimics the physical charging/discharging valve
    P = Pmax * max(0, sin(2 * pi * freq * t)); 
end

% ---------------------------------------------------------
% 5. The Event Triggers (Boundary Crossings)
% ---------------------------------------------------------
function [value, isterminal, direction] = event_trigger_slip(t, Y, k1, k3, A0, alpha, mu_s, mf, g)
    Xp = Y(1); Xf = Y(3);
    z = Xp - Xf;
    P_val = get_pressure(t);
    
    % Static internal force ignoring velocity-dependent damping
    F_int = P_val*A0*(1 + alpha*z) - k1*z - k3*(z^3); 
    
    F_pull = -F_int; 
    F_static_limit = mu_s * mf * g;
    
    value = F_pull - F_static_limit; 
    isterminal = 1; 
    direction = 1;  
end

function [value, isterminal, direction] = event_trigger_stick(t, Y)
    Vf = Y(4);
    
    value = Vf; 
    isterminal = 1; 
    direction = -1; 
end
% ---------------------------------------------------------
% 6. Export Data and Save Figure
% ---------------------------------------------------------
% Save the high-resolution figure for the IEEE manuscript
if ~exist('results/figures', 'dir')
    mkdir('results/figures');
end
exportgraphics(gcf, 'results/figures/Fig1_TrueCoulomb_StickSlip.pdf', 'ContentType', 'vector');
exportgraphics(gcf, 'results/figures/Fig1_TrueCoulomb_StickSlip.png', 'Resolution', 300);

% Export the raw time and state data for SINDy Python analysis
if ~exist('results/data', 'dir')
    mkdir('results/data');
end
% Columns: [Time, X_payload, V_payload, X_foot, V_foot]
writematrix([T_out, Y_out], 'results/data/Phase12_StickSlipData.csv');
disp('Simulation complete. Figure and Data successfully exported.');