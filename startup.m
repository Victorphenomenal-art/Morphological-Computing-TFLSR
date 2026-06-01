%% startup.m
% Project: Morphological Computing & Chibueze-Victor Transduction Equation
% Author: Anih Chibueze Victor
% Description: Initializes environment paths and validates toolboxes.
% Note: Updated to use 'ver' string matching to support DEMO/Trial licenses.

function startup()
fprintf('\nInitializing Morphological Computing Framework...\n');

rootDir = fileparts(mfilename('fullpath'));
cd(rootDir);

addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'utils'));
addpath(genpath(fullfile(rootDir, 'tests')));
addpath(fullfile(rootDir, 'models'));

if verLessThan('matlab', '9.15')
    warning('MATLAB R2023b or newer is recommended for optimal Simscape Gas functionality.');
end

% Query installed toolboxes directly to bypass DEMO license('test') errors
v = ver;
installedBoxes = {v.Name};

requiredBoxes = {'Simulink', 'Simscape', 'Simscape Fluids', 'Simscape Multibody'};

missingDeps = false;
for i = 1:length(requiredBoxes)
    if ~any(strcmp(installedBoxes, requiredBoxes{i}))
        fprintf('Error: Toolbox "%s" is not installed.\n', requiredBoxes{i});
        missingDeps = true;
    end
end

if missingDeps
    error('Framework initialization halted due to missing dependencies.');
else
    fprintf('All required physical modeling toolboxes detected successfully.\n');
end

% Optional checking for Parallel/Stats toolboxes
if any(strcmp(installedBoxes, 'Parallel Computing Toolbox'))
    fprintf('Parallel Computing Toolbox detected. Enabled for parameter sweeps.\n');
end

fprintf('Environment setup complete. System ready.\n\n');
end