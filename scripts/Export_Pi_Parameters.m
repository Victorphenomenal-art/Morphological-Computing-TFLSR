% Generates a CSV table of the PRX Dimensionless Parameters
clear; clc;

Pi_Names = {'Pi_1 (Duffing)'; 'Pi_2_slip (Slide Damping)'; 'Pi_2_stick (Static Clamping)'; 'Pi_stride (Propulsion)'; 'Pi_4 (Deborah Fluid)'};
Values = [4.00; 0.08; 65.0; 2.72; 0.95];
Descriptions = {'Hyperelastic restoring force multiplier'; 'Viscous kinetic resistance during expansion'; 'Coulomb static friction during contraction'; 'Rectified volume-expansion gain'; 'Fluid-dynamic capacitance lag'};

PiTable = table(Pi_Names, Values, Descriptions);

% Save to the tables directory
writetable(PiTable, '../results/tables/Dimensionless_Parameters.csv');
disp('Successfully exported parameters to results/tables/Dimensionless_Parameters.csv');