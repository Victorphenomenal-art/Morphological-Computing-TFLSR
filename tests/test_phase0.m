%% test_phase0.m
% Automated unit tests for environment verification.

function tests = test_phase0
    tests = functiontests(localfunctions);
end

function testInitializationScripts(testCase)
    verifyTrue(testCase, exist('startup.m', 'file') == 2, 'startup.m is missing.');
    verifyTrue(testCase, exist('simulation_defaults.m', 'file') == 2, 'Defaults missing.');
end

function testDataStructures(testCase)
    opts = simulation_defaults();
    verifyTrue(testCase, isfield(opts, 'gas_model'), 'Gas model parameter missing.');
    verifyEqual(testCase, opts.solver, 'ode15s', 'Incorrect stiff solver specified.');
end