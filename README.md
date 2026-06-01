# Thermodynamic Pareto Frontiers in Hierarchical Morphological Computing

[![MATLAB CI](https://github.com/Victorphenomenal-art/MorphologicalComputing_Simscape/actions/workflows/matlab-ci.yml/badge.svg)](https://github.com/Victorphenomenal-art/MorphologicalComputing_Simscape/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Author:** Anih Chibueze Victor  
**Institution:** Department of Mechatronics Engineering, University of Nigeria, Nsukka  

## Overview
This repository contains a rigorous, dimensionally consistent theoretical framework and Simscape simulation environment for investigating hierarchical morphological computation. The model couples a 6-DOF rigid Stewart platform with a 6-segment soft continuum arm (Ecoflex 00-30). 

A core component of this framework is the exact calculation of non-equilibrium thermodynamic work via the Simscape Gas Library and the Jarzynski equality ($e^{-\beta\Delta F}=\frac{1}{M}\sum_{m=1}^{M}e^{-\beta W_{m}}$).

## Execution# Nonequilibrium Thermodynamics and Morphological Computing in Soft Robotic Locomotion

This repository contains the computational framework, first-principles MATLAB models, and numerical validation scripts for the associated manuscript submitted to *Physical Review X*. 

The code proves the thermodynamic boundaries and topological chaos transitions of a hyperelastic, stick-slip soft pneumatic actuator, evaluating its capacity as a morphological computing reservoir.

## Repository Architecture

* `models/` - Contains the ground-truth synthetic data (`TFLSR_Synthetic_Data.mat`) and underlying Simscape physical network architecture.
* `scripts/` - Contains the core, toolbox-free MATLAB scripts required to reproduce the paper's theoretical benchmarks and visualizations.
* `data/` - Contains the generated parameter universes and Lyapunov exponent matrices outputted by the numerical sweeps.
* `TFLSR_SINDy_Analysis/` - Contains the Sparse Identification of Nonlinear Dynamics (SINDy) python pipeline used for empirical pre-strain verification.
* `utils/` & `tests/` - Helper functions and unit tests for continuous integration.
* `docs/` & `results/` - Extended documentation and high-resolution exported `.eps` / `.pdf` figures for the manuscript.

## Core Simulation Scripts (Located in `/scripts`)

All scripts are written in native MATLAB and have been explicitly engineered to run **without proprietary toolboxes** to ensure maximum open-source reproducibility.

1. **`Phase8_PiSpace_MonteCarlo.m`**
   * Executes a Latin Hypercube sampling across the 5-dimensional dimensionless Pi-parameter space, generating a 500-run virtual universe of soft robot state trajectories.
2. **`Phase9_Thermodynamics_Reservoir.m`**
   * Ingests the Phase 8 universe to map the thermodynamic work against Memory Capacity, identifying the high-efficiency information-energy landscape.
3. **`Phase9_1_True_LLE_Heatmap.m`**
   * Computes the Largest Lyapunov Exponent using a twin-trajectory renormalization method to map the precise "Edge of Chaos" phase transition.
4. **`Phase9_2_Jarzynski_Ensemble.m`**
   * Validates the non-equilibrium fluctuation theorems for the system, proving the existence of a macroscopic dissipation barrier relative to the Jarzynski Equality.
5. **`Phase9_3_Simscape_Validation.m`**
   * Benchmarks the non-smooth, stick-slip analytical governing law against the high-fidelity Simscape ground truth, achieving a Validation NMSE of 0.0028.

## How to Reproduce Results

1. Clone or download this repository.
2. Open MATLAB and navigate to the root directory.
3. Open the `scripts/` folder and execute the Phase 8 and Phase 9 scripts in sequential order. 
4. The scripts will automatically route outputs to the `data/` folder and generate the publication-ready figures.

## Author & Citation
**Anih Chibueze Victor** Department of Mechatronics Engineering, University of Nigeria, Nsukka

*(Citation format will be updated upon manuscript publication).*

1. Clone the repository:
   ```bash
   git clone [https://github.com/Victorphenomenal-art/MorphologicalComputing_Simscape.git](https://github.com/Victorphenomenal-art/MorphologicalComputing_Simscape.git)
   cd MorphologicalComputing_Simscape