# PINNLab: Educational Dashboard for Data-Driven Modeling

PINNLab is an open-source, interactive MATLAB dashboard designed to bridge the gap between classical differential equation pedagogy and modern computational data science. It provides a "glass-box" environment for undergraduate STEM students to learn data-driven parameter estimation and solve inverse problems utilizing **Physics-Informed Neural Networks (PINNs)**.

This repository contains the full source code and datasets accompanying our manuscript, currently under review for the CODEE Journal.

---

## 📖 Pedagogical Framework
The PINNLab curriculum is uniquely organized utilizing a revised **T-shaped framework**—balancing broad 21st-century professional competencies (Data-Driven Modeling, Scientific Communication, Critical System Evaluation) with a vertical escalation of mathematical complexity. 

This vertical escalation is strictly governed by the constructivist **5E Instructional Model**. Grounded in a cohesive narrative of ecological predator-prey dynamics, the dashboard guides students from qualitative inquiry to authentic historical research.

## 🧬 Curriculum Modules & Core Files

### Foundational Demonstration: Exponential Growth
* **File:** `run_PINN_Population.m`
* **Mathematics:** $dy/dt = ky$
* **Description:** A technical primer designed to demystify artificial intelligence. Students generate synthetic population data and observe a 3-Phase training algorithm (Data Mapping -> Physics Inverse -> Fine Tuning) to establish trust in the PINN methodology.

### Module 0 (Engage): Qualitative Ecological Inquiry
* **Description:** Bypasses rigorous mathematics to focus on collaborative problem-solving and visual intuition. Students utilize the open-source PhET Natural Selection sandbox to observe the cyclical boom-and-bust nature of predator-prey populations. *(Note: This phase does not require MATLAB computation).*
* **Simulation Link:** [PhET Natural Selection](https://phet.colorado.edu/sims/html/natural-selection/latest/natural-selection_en.html)

### Module 1 (Explore): Environmental Forcing
* **File:** `run_PINN_ForcedODE.m`
* **Mathematics:** $dy/dt - ky = Q(t)$
* **Description:** Students investigate the limitations of classical integrating factors when subjected to empirical or complex seasonal forcing functions ($Q(t)$). This module introduces algorithmic stability via logarithmic variable transformations.

### Module 2 (Explain): Basic Lotka-Volterra Dynamics
* **File:** `run_PINN_LotkaVolterra.m`
* **Mathematics:** Coupled 4-parameter nonlinear system.
* **Description:** Transitions students to multi-dimensional state solutions. Students explore how the composite loss function of the neural network balances competing physical constraints to enforce the conservation laws of consumption and reproduction.

### Modules 3 & 4 (Elaborate & Evaluate): Holling's Type II & Authentic Research
* **File:** `run_PINN_HollingsTypeII.m`
* **Mathematics:** 6-parameter system featuring Logistic Growth and Holling's Type II functional responses.
* **Description:** The climax of the curriculum. Students first navigate high-dimensional, non-convex loss landscapes using synthetic data to test structural identifiability. Finally, the synthetic scaffolding is removed, and students ingest raw historical data (or their own custom CSVs) to critically evaluate competing mathematical hypotheses.

---

## 🗂️ Repository Structure

```text
PINNLab/
│
├── data/
│   └── hare_lynx_data.csv          # Historical Hudson's Bay Company trapping records (1845-1903)
│
├── PINNLab_Dashboard.m             # Main MATLAB App Designer GUI Class
├── run_PINN_Population.m           # Engine for the Foundational Demo
├── run_PINN_ForcedODE.m            # Engine for Module 1
├── run_PINN_LotkaVolterra.m        # Engine for Module 2
├── run_PINN_HollingsTypeII.m       # Engine for Modules 3 & 4 (Handles both Synthetic and Real data)
└── README.md
