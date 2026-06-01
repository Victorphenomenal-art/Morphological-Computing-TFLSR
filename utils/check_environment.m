%% check_environment.m
% Executes a pre-flight check of the file structure and dependencies.

function status = check_environment()
    status = true;
    fprintf('Executing system pre-flight diagnostics...\n');
    
    directories = {'models', 'scripts', 'utils', 'tests', 'data/validation', 'results/logs'};
    
    for i = 1:length(directories)
        if ~exist(directories{i}, 'dir')
            fprintf('Warning: Standard directory /%s is missing.\n', directories{i});
            status = false;
        end
    end
    
    if status
        fprintf('All system directories verified.\n');
    else
        fprintf('Check failed. Run phase 0 initialization scripts.\n');
    end
end