% =========================================================================
% MASTER EXECUTION SUITE: PRX MANUSCRIPT VALIDATION
% Description: Automatically builds directory architecture, logs all console 
% outputs, and runs the entire Phase 8-9 simulation pipeline sequentially.
% =========================================================================
clear; clc; close all;

disp('--- VERIFYING DIRECTORY ARCHITECTURE ---');

% 1. Automatically create the results folders if they do not exist
if ~exist('results/logs', 'dir'), mkdir('results/logs'); end
if ~exist('results/figures', 'dir'), mkdir('results/figures'); end
if ~exist('results/tables', 'dir'), mkdir('results/tables'); end

% 2. Start logging directly into the root's result folder
% (Notice we removed the '../' because this script is already in the root!)
diary('results/logs/PRX_Execution_Log.txt');
disp(['--- STARTING PRX SIMULATION SUITE: ', datestr(now), ' ---']);

% 3. Step inside the scripts folder so all internal relative paths work
cd('scripts');

% 4. Execute the full PRX Pipeline
try
    disp('>> Initiating Phase 8: Parameter Universe...');
    run('Phase8_PiSpace_MonteCarlo.m');

    disp('>> Initiating Phase 9: Energy-Information Landscape...');
    run('Phase9_Thermodynamics_Reservoir.m');

    disp('>> Initiating Phase 9.1: Chaos Map...');
    run('Phase9_1_True_LLE_Heatmap.m');

    disp('>> Initiating Phase 9.2: Jarzynski Thermodynamics...');
    run('Phase9_2_Jarzynski_Ensemble.m');

    disp('>> Initiating Phase 9.3: Simscape Validation...');
    run('Phase9_3_Simscape_Validation.m');

    disp('>> Exporting Parameter Tables...');
    run('Export_Pi_Parameters.m');

    disp('--- SIMULATION SUITE SUCCESSFULLY COMPLETED ---');
catch ME
    disp('!!! ERROR ENCOUNTERED DURING EXECUTION !!!');
    disp(ME.message);
end

% 5. Step back out to the root folder
cd('..');

% Turn off the console logger
diary off;