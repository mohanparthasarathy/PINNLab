# PINNLab: Educational Dashboard for Data-Driven Modeling
# Mohan Parthasarathy and Padmanabhan Seshaiyer

PINNLab is a MATLAB-based interactive dashboard designed to teach Physics-Informed Neural Networks (PINNs) and data-driven parameter estimation to undergraduate STEM students. It bridges the gap between traditional differential equation pedagogy and modern computational science.

This repository contains the source code accompanying our paper, structured around a 5E instructional framework focusing on ecological predator-prey dynamics.

## Repository Contents
- `PINNLab_Dashboard.m`: The main graphical user interface.
- `run_PINN_*.m`: The underlying mathematical engines and custom training loops for each module.
- `/data`: Contains empirical datasets, including the historical Hudson's Bay Company hare and lynx trapping records.

## 5E Curriculum Modules
1. **Foundational Demo**: Exponential Population Growth ($dy/dt = ky$)
2. **Module 1 (Explore)**: Environmental Forcing ($dy/dt - ky = Q(t)$) utilizing logarithmic transformations for stability.
3. **Module 2 (Explain)**: Basic Lotka-Volterra Predator-Prey dynamics (4 parameters).
4. **Module 3 & 4 (Elaborate/Evaluate)**: Logistic Growth with Holling's Type II functional response (6 parameters) applied to synthetic and real-world historical data.

## Getting Started
1. Clone this repository.
2. Open MATLAB (requires Deep Learning Toolbox).
3. Run `PINNLab_Dashboard.m`.
