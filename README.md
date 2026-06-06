# PINNLab

**PINNLab** is an interactive MATLAB dashboard for teaching data-driven parameter estimation in ordinary differential equations using physics-informed neural networks (PINNs). It was designed for undergraduate differential equations, mathematical modeling, biomathematics, and scientific computing courses.

PINNLab introduces students to inverse modeling: instead of only solving an ODE when the parameters are known, students estimate unknown parameters from noisy data while checking whether the fitted trajectory is consistent with the governing differential equation. The dashboard makes this process visible through real-time plots of state reconstruction, parameter convergence, and loss diagnostics.

The instructional sequence follows the **5E learning model**:

1. **Engage** with qualitative ecological intuition.
2. **Explore** a forced scalar ODE.
3. **Explain** coupled Lotka--Volterra predator--prey dynamics.
4. **Elaborate** with a higher-dimensional Holling Type II predator--prey model.
5. **Evaluate** model adequacy using the historical Hudson Bay hare--lynx dataset.

PINNLab is intended as a teaching tool, not a black-box parameter recovery engine. Some runs will converge cleanly; others may reveal sensitivity to initialization, scaling, loss weighting, or model misspecification. These behaviors are part of the intended learning experience.

---

## Quick Start

1. Clone or download this repository.

   ```matlab
   git clone https://github.com/mohanparthasarathy/PINNLab.git
   ```

2. Open MATLAB in the repository root folder.

3. Run the startup script:

   ```matlab
   startup
   ```

   This adds the repository and subfolders to the MATLAB path.

4. Launch the dashboard:

   ```matlab
   PINNLab_Dashboard
   ```

5. Select a module from the left panel, set the parameters, and click **Start Training**.

For Module 0, the dashboard opens the external PhET Natural Selection simulation. For Module 4, the dashboard prompts the user to select a CSV file containing empirical hare--lynx data.

---

## MATLAB Requirements

PINNLab requires:

- MATLAB
- Deep Learning Toolbox
- Statistics and Machine Learning Toolbox is helpful but not generally required for the included modules
- Internet access for Module 0, since the PhET simulation opens in a web browser

The dashboard was developed for MATLAB App Designer-style workflows using `uifigure`, `uiaxes`, `uitable`, `dlnetwork`, `dlarray`, and custom training loops.

If running in MATLAB Online, confirm that the required toolboxes are available through your institutional license.

---

## Repository Contents

A typical PINNLab repository contains:

```text
PINNLab_Dashboard.m
startup.m
run_PINN_Population.m
run_PINN_ForcedODE.m
run_PINN_LotkaVolterra.m
run_PINN_HollingsTypeII.m
data/
    hare_lynx_data.csv
images/
    phet_natural_selection.png
docs/
    PINNLab_Teaching_Guide.md
    PINNLab_Example_Student_Worksheet.md
    example_runs/
        README.md
README.md
```

### Core files

- `PINNLab_Dashboard.m`  
  Main graphical interface. Handles module selection, user inputs, plotting panels, logs, equations, and routing to the module engines.

- `startup.m`  
  Adds the repository and all subfolders to the MATLAB path.

- `run_PINN_Population.m`  
  Foundational demonstration using exponential growth.

- `run_PINN_ForcedODE.m`  
  Module 1 engine for a forced first-order ODE.

- `run_PINN_LotkaVolterra.m`  
  Module 2 engine for the basic Lotka--Volterra predator--prey system.

- `run_PINN_HollingsTypeII.m`  
  Shared engine for Module 3 and Module 4. In synthetic mode, it generates data from a Holling Type II model. In real-data mode, it fits the historical hare--lynx dataset.

- `data/hare_lynx_data.csv`  
  Historical hare--lynx data used in Module 4.

- `images/phet_natural_selection.png`  
  Optional screenshot used for the Module 0 landing screen.

### Documentation

- `docs/PINNLab_Teaching_Guide.md`
  Instructor-facing guide with learning goals, classroom formats, module-specific teaching notes,
  training-log interpretation, failure-mode guidance, and assessment ideas.

- `docs/PINNLab_Example_Student_Worksheet.md`
  A fillable student worksheet covering all five modules, with before/after prompts, parameter
  recording tables, and model-comparison questions for Module 4.

- `docs/example_runs/README.md`
  A guide for instructors on how to collect, organize, and caption representative PINNLab
  screenshots for teaching use. The `example_runs/` directory is intentionally empty; instructors
  add their own screenshots to this folder.
  
---

## Module Descriptions

### Demo: Exponential Growth

The demonstration introduces the basic PINN workflow using

\[
\frac{dy}{dt} = ky.
\]

Students choose a true growth rate and an initial guess. The dashboard generates noisy synthetic data, trains a neural network to represent \(y(t)\), and estimates \(k\). Because the exact solution is familiar, this module helps students interpret the loss function, training phases, and parameter trace before moving to more complex systems.

This module is best used to introduce:

- neural networks as differentiable function approximators,
- automatic differentiation,
- data loss versus physics residual,
- parameter convergence,
- sensitivity to initial guesses.

---

### Module 0: Engage — PhET Natural Selection

Module 0 opens the PhET Natural Selection simulation. This activity is qualitative. It is not intended to generate Lotka--Volterra data and should not be interpreted as a calibrated predator--prey model.

Its role is to motivate the ecological question:

> How can interactions between species or environmental pressures affect rates of population change?

Students should use this module to discuss population growth, extinction, environmental pressure, selection, and the idea that the rate of change of one quantity may depend on another quantity.

---

### Module 1: Explore — Forced ODE

Module 1 studies

\[
\frac{dy}{dt} - ky = Q(t),
\]

where \(Q(t)\) is a user-specified forcing function such as `sin(2*t)`.

The module uses the logarithmic transformation

\[
u(t)=\log(y(t))
\]

for numerical stability. The transformed residual is

\[
u'(t)-k-Q(t)e^{-u(t)}=0.
\]

The dashboard displays the recovered state, the forcing function, and the convergence of the estimated parameter \(k\).

This module is useful for discussing:

- empirical or non-symbolic forcing,
- numerical stability,
- log-state training,
- how forcing enters the residual,
- why inverse problems differ from closed-form solution exercises.

---

### Module 2: Explain — Lotka--Volterra Dynamics

Module 2 introduces the classic predator--prey system

\[
\frac{dx}{dt}=\alpha x-\beta xy,
\]

\[
\frac{dy}{dt}=-\gamma y+\delta xy.
\]

Students select true parameters for synthetic data generation and separate initial guesses for the inverse problem. This makes initialization sensitivity visible and encourages students to compare runs.

The neural network outputs both prey and predator trajectories. The physics residual has two components:

\[
r_x(t)=\frac{d\hat{x}}{dt}-(\alpha\hat{x}-\beta\hat{x}\hat{y}),
\]

\[
r_y(t)=\frac{d\hat{y}}{dt}-(-\gamma\hat{y}+\delta\hat{x}\hat{y}).
\]

This module is useful for discussing:

- coupled ODE systems,
- simultaneous state reconstruction and parameter estimation,
- biological interpretation of parameters,
- initialization sensitivity,
- the difference between a good trajectory fit and accurate parameter recovery.

---

### Module 3: Elaborate — Holling Type II Predator--Prey Model

Module 3 extends Lotka--Volterra dynamics by adding logistic prey growth and a saturating predation response:

\[
\frac{dx}{dt}
=
\alpha x\left(1-\frac{x}{K}\right)
-
\frac{\beta xy}{c+x},
\]

\[
\frac{dy}{dt}
=
-\gamma y
+
\frac{\delta\beta xy}{c+x}.
\]

The six parameters are:

- \(\alpha\): prey growth rate
- \(K\): carrying capacity
- \(\beta\): predation scale
- \(c\): half-saturation constant
- \(\gamma\): predator mortality
- \(\delta\): conversion efficiency

Module 3 is intentionally more challenging than Module 2. Students may observe that some runs recover trajectories well while estimating one or more parameters poorly. This is not necessarily a software bug. It may reflect local minima, weak identifiability, poor initialization, insufficient predator signal, or the inherent difficulty of high-dimensional inverse problems.

This module is useful for discussing:

- model refinement,
- saturation effects,
- identifiability,
- local minima,
- vanishing or weak gradients,
- repeated runs and diagnostic interpretation.

---

### Module 4: Evaluate — Hare--Lynx Data


Students fit competing predator–prey models to the historical Hudson's Bay hare and lynx dataset. Two options are available:

- Mod 4A: Lotka–Volterra
- Mod 4B: Holling Type II

Students compare data fit, physics consistency, parameter stability, and biological plausibility to determine which model provides the most convincing explanation of the observed population cycles.

This module emphasizes model evaluation rather than parameter recovery, since the true ecological parameters are unknown. The values entered in the dashboard are initial guesses, and the final estimates should be interpreted as fitted calibration values rather than biological ground truth.

Large estimates of \(K\) or \(c\) in the Holling Type II model may indicate that the model is using carrying capacity or half-saturation as flexible fitting terms rather than identifying biologically meaningful constants. This is a valuable modeling lesson: real data may be noisy, indirect, incomplete, or inconsistent with the assumptions of the proposed ODE model.

---

## Training Log Guide

The training log is not just a progress monitor. It is a diagnostic record of the modeling process.

A typical log line has the form:

```text
Ep 2500 | Phase: Physics Inverse | L_total=... | L_data=... | L_phys=... | w_data=... | w_phys=...
```

### Key quantities

- `Ep`  
  Current training epoch.

- `Phase`  
  Current stage of training. Most modules use a phased strategy such as data fitting, inverse parameter estimation, and fine tuning.

- `L_total`  
  Weighted objective being optimized.

- `L_data`  
  Data-fitting loss. This measures how well the neural-network trajectory matches observations.

- `L_phys`  
  Physics residual loss. This measures how well the fitted trajectory satisfies the governing ODE.

- `w_data`  
  Weight applied to the data loss.

- `w_phys`  
  Weight applied to the physics residual.

### Interpreting the phases

PINNLab generally uses a three-phase training structure.

1. **Data fitting / mapping phase**  
   The network learns a smooth approximation to the observed data. Physical parameters are fixed.

2. **Physics inverse phase**  
   The physics residual is activated and the parameter estimates are updated. In some modules the network is frozen or updated slowly so that parameter movement is easier to interpret.

3. **Fine tuning phase**  
   Both the neural-network weights and the physical parameters are updated together.

The total loss is not always directly comparable across phases because the active objective may change. Students should inspect `L_data` and `L_phys` separately before deciding whether a run is improving or failing.

---

## Failure Modes and Diagnostic Interpretation

PINNs are powerful, but they are not automatic. PINNLab is designed to make both successful and unsuccessful training runs useful for learning.

Common failure modes include:

### 1. Good visual fit but poor parameter recovery

A neural network may fit the observed trajectory well while the estimated parameters remain far from the true synthetic values. This can happen when multiple parameter combinations produce similar trajectories.

Teaching interpretation:

> State reconstruction and parameter identification are related but distinct goals.

---

### 2. Stagnant parameter traces

If one or more parameters barely move, the optimizer may be stuck, the gradients may be weak, or the data may not contain enough information to identify that parameter.

Possible responses:

- try a different initial guess,
- reduce the learning rate,
- increase training epochs,
- rerun with another seed,
- reduce noise,
- choose a more informative synthetic trajectory.

---

### 3. Large physics residual despite good data fit

A low data loss does not imply that the fitted curve satisfies the ODE. If `L_data` is small but `L_phys` remains large, the model may be inconsistent with the data or the optimizer may not have found a physically consistent solution.

Teaching interpretation:

> A curve can fit the points while violating the governing equation.

---

### 4. Parameter explosion

In Module 3 or Module 4, parameters such as \(K\) or \(c\) may become very large. This may indicate weak identifiability or that the model is using a parameter as a flexible fitting device.

Teaching interpretation:

> Biological plausibility matters. A visually good fit is not enough.

---

### 5. Failed or unstable optimization

Some runs may produce oscillatory loss, unstable trajectories, or warnings. This is especially possible in the six-parameter Holling Type II model.

Possible responses:

- rerun with a different initial guess,
- lower the learning rate,
- increase warm-up epochs,
- lower data noise,
- inspect separate data and physics losses,
- compare repeated runs rather than relying on a single output.

---

## Adapting PINNLab

PINNLab was designed around ecological examples, but the framework can be adapted to other parameterized ODE models.

To adapt a module to a new ODE, instructors or advanced students usually need to modify:

1. the synthetic data-generation ODE,
2. the neural-network output dimension,
3. the physics residual in the loss function,
4. parameter names and defaults in the dashboard,
5. plotting labels and table outputs,
6. any empirical data-ingestion routines.

The most important code section to modify is the module-specific loss function. For example, in the Lotka--Volterra module, the loss function computes the network derivatives and subtracts the right-hand side of the ODE. A new model requires replacing that residual with the new governing equation.

PINNLab currently exposes common instructional controls in the GUI, including parameters, initial guesses, noise level, epochs, warm-up length, forcing functions, and data upload. More advanced changes, such as network depth, activation functions, collocation strategies, or entirely new ODE models, are made at the code level.

Although PINNLab is implemented in MATLAB, the instructional structure can be transferred to Python-based scientific machine-learning libraries such as DeepXDE, SciANN, or NVIDIA Modulus. The essential ingredients are:

- a differentiable neural-network state approximation,
- automatic differentiation,
- a data loss,
- a physics residual,
- trainable physical parameters,
- diagnostic visualization.

---

## Recommended Classroom Use

PINNLab can be used at several levels of depth.

### Short demonstration

Time: one class period or lab session.

Recommended modules:

- Demo: Exponential Growth
- Module 2: Lotka--Volterra

Suggested student task:

> Explain the difference between fitting a trajectory and estimating a physical parameter.

---

### One-week mini-project

Time: approximately one instructional week.

Recommended modules:

- Demo
- Module 0
- Module 1
- Module 2
- Module 4

Suggested student task:

> Compare data loss and physics residual. Decide whether a model is fitting the data, satisfying the ODE, both, or neither.

---

### Extended modeling project

Time: two to three weeks.

Recommended modules:

- Full sequence: Demo and Modules 0--4

Suggested student task:

> Write a short modeling report discussing parameter estimates, residual behavior, biological plausibility, failure modes, and model adequacy.

---

## Suggested Student Prompts

Instructors may use prompts such as:

- What does the data loss measure?
- What does the physics residual measure?
- Can a model fit the data but violate the ODE?
- How does changing the initial guess affect parameter recovery?
- Which parameters are easiest or hardest to recover?
- Does a large value of \(K\) or \(c\) make biological sense?
- When should we interpret a poor run as optimizer failure?
- When should we interpret a persistent residual as model inadequacy?
- How would you revise the model or collect better data?

---

## Support and Citation

PINNLab was developed as an open educational resource to support undergraduate instruction in data-driven modeling with differential equations and physics-informed neural networks.

If you use PINNLab in teaching, research, or curriculum development, please cite the associated CODEE Journal article entitled _PINNLab: An Interactive Dashboard for Teaching Data-Driven Parameter Estimation in Differential Equations using Physics-Informed Neural Networks_

Please also cite this GitHub repository when using or adapting the software.

For questions, suggestions, or classroom implementation feedback, please open an issue on the GitHub repository or contact the authors through the repository page.
