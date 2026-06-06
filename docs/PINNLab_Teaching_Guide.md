# PINNLab Teaching Guide

This guide is intended for instructors using PINNLab in an undergraduate differential equations, mathematical modeling, biomathematics, or scientific computing course.

PINNLab is designed to help students understand inverse modeling with ordinary differential equations using physics-informed neural networks (PINNs). The goal is not simply to produce correct parameter estimates. The goal is to help students interpret the relationship between data fit, physics residuals, parameter convergence, model assumptions, and failure modes.

---

## Learning Goals

After completing the PINNLab sequence, students should be able to:

1. Explain the difference between a forward ODE problem and an inverse parameter-estimation problem.
2. Interpret a neural network as a differentiable approximation to an unknown state trajectory.
3. Distinguish data loss from physics residual loss.
4. Explain how automatic differentiation is used to compute derivatives of the neural-network output.
5. Interpret parameter convergence plots.
6. Recognize that state reconstruction and parameter recovery are related but distinct tasks.
7. Identify possible causes of failed or unstable PINN training.
8. Use residual behavior and biological plausibility to evaluate model adequacy.
9. Explain why real-data calibration differs from synthetic parameter recovery.

---

## Recommended Setup

Before class, instructors should:

1. Confirm that MATLAB and required toolboxes are available.
2. Clone or download the PINNLab repository.
3. Run:

   ```matlab
   startup
   PINNLab_Dashboard
   ```

4. Confirm that each module opens correctly.
5. Confirm that `data/hare_lynx_data.csv` is available for Module 4.
6. Confirm that `images/phet_natural_selection.png` is available for the Module 0 landing screen.
7. Run at least one short test of each computational module.

Recommended test settings:

| Module | Epochs | Warmup | Noise |
|---|---:|---:|---:|
| Demo | 3000--8000 | 500--1000 | 5 |
| Module 1 | 3000--8000 | 500--1000 | 5 |
| Module 2 | 5000--8000 | 500--1000 | 2--5 |
| Module 3 | 8000 | 500--1000 | 2--5 |
| Module 4 | 8000 | 500--1000 | Real data |

Because PINN training can be sensitive to initialization and scaling, instructors should run the examples before class and decide whether to present a successful run, a failed run, or both.

---

## Classroom Formats

### Short Demonstration

Approximate time: one 50--75 minute class or lab period.

Recommended modules:

- Demo: Exponential Growth
- Module 2: Lotka--Volterra

Suggested structure:

1. Introduce the difference between forward and inverse problems.
2. Run the exponential growth demo.
3. Ask students to identify `L_data`, `L_phys`, and the parameter trace.
4. Run Module 2 with default settings.
5. Discuss why the fitted trajectory and recovered parameters may not tell the same story.

Suggested deliverable:

> A short reflection explaining the difference between fitting a curve and recovering a physical parameter.

---

### One-Week Mini-Project

Approximate time: three class periods or one week of lab/discussion.

Recommended modules:

- Demo
- Module 0
- Module 1
- Module 2
- Module 4

Suggested structure:

1. Use Module 0 to motivate ecological modeling qualitatively.
2. Use Module 1 to discuss forcing terms and log-state training.
3. Use Module 2 to introduce coupled predator--prey dynamics.
4. Use Module 4 to discuss real data and model adequacy.

Suggested deliverable:

> A short model-comparison paragraph using data loss, physics residual, parameter stability, and biological plausibility.

---

### Extended Project

Approximate time: two to three weeks.

Recommended modules:

- Full sequence: Demo and Modules 0--4

Suggested structure:

1. Students complete all modules.
2. Students rerun Modules 2 and 3 with different initial guesses.
3. Students compare successful and unsuccessful runs.
4. Students fit the hare--lynx data in Module 4.
5. Students submit a written report.

Suggested deliverable:

> A modeling report discussing parameter estimates, residual behavior, biological interpretation, failure modes, and model limitations.

---

## Module-Specific Teaching Notes

### Demo: Exponential Growth

The exponential growth demo is the safest place to introduce the PINN workflow because students can compare the output with a familiar analytic solution.

Important points to emphasize:

- The neural network approximates \(y(t)\).
- Automatic differentiation computes the derivative of the network output.
- The physics residual penalizes violations of \(dy/dt = ky\).
- The parameter trace shows how \(k\) changes during training.
- The initial guess affects the path of optimization.

Suggested prompt:

> What evidence in the dashboard tells you that the curve fits the data? What evidence tells you that the curve satisfies the differential equation?

---

### Module 0: Engage

Module 0 uses the PhET Natural Selection simulation as qualitative motivation.

Important points to emphasize:

- PhET is external to PINNLab.
- The simulation is not a calibrated predator--prey model.
- The goal is ecological intuition, not quantitative inference.
- Students should observe how environmental pressures and species interactions can affect population outcomes.

Suggested prompt:

> What quantities would we need to measure in order to predict whether a population recovers, collapses, or oscillates?

---

### Module 1: Explore

Module 1 uses the forced ODE

\[
\frac{dy}{dt}-ky=Q(t).
\]

The code uses the log transformation

\[
u(t)=\log(y(t)).
\]

The residual becomes

\[
u'(t)-k-Q(t)e^{-u(t)}=0.
\]

Important points to emphasize:

- The forcing function enters directly into the residual.
- The dashboard displays both the recovered state and the forcing term.
- The bottom panel shows convergence of \(k\).
- Log-state training is used for numerical stability.

Suggested prompt:

> Why does the PINN still work when \(Q(t)\) is given as a function or data-like forcing rather than as something we solve analytically by hand?

---

### Module 2: Explain

Module 2 uses the Lotka--Volterra system

\[
\frac{dx}{dt}=\alpha x-\beta xy,
\]

\[
\frac{dy}{dt}=-\gamma y+\delta xy.
\]

Important points to emphasize:

- The network outputs two state variables.
- The residual has one component for prey and one component for predators.
- The prey residual depends on the predator estimate.
- The predator residual depends on the prey estimate.
- Students can set both true synthetic parameters and initial guesses.
- A visually good trajectory does not guarantee accurate parameter recovery.

Suggested prompt:

> Rerun the model with a different initial guess. Does the trajectory change? Do the final parameters change? What does this suggest about identifiability?

---

### Module 3: Elaborate

Module 3 uses the Holling Type II predator--prey model with six parameters.

Important points to emphasize:

- This inverse problem is intentionally harder.
- Parameters may be sensitive to initial guesses.
- Some runs may recover the trajectory but not all parameters.
- Stagnant traces, large residuals, or biologically implausible estimates are useful diagnostic signals.
- Failure modes are part of the learning experience.

Suggested prompt:

> Which parameters appear easiest to recover? Which are hardest? How can you tell from the traces and final estimates?

---

### Module 4: Evaluate

Module 4 fits the historical Hudson Bay hare--lynx trapping data.

Important points to emphasize:

- The true parameters are unknown.
- The table reports initial guesses and fitted estimates, not recovery errors.
- The data are proxy observations, not direct census counts.
- A fitted model should be evaluated using data fit, physics residual, parameter stability, and biological plausibility.
- Large fitted values of \(K\) or \(c\) may indicate weak identifiability or model inadequacy.

Suggested prompt:

> Does the model fit the data visually? Does it satisfy the differential equation? Are the fitted parameters biologically plausible?

---

## Interpreting the Training Log

The training log reports quantities such as:

```text
Ep 2500 | Phase: Physics Inverse | L_total=... | L_data=... | L_phys=... | w_data=... | w_phys=...
```

Students should be taught to read the log as a diagnostic tool.

### `L_data`

Measures how well the neural-network trajectory matches the observed data.

A low `L_data` means the curve fits the points well.

### `L_phys`

Measures how well the fitted trajectory satisfies the governing ODE.

A low `L_phys` means the curve is more consistent with the model equation.

### `L_total`

The weighted training objective.

Because the active loss components may change across phases, `L_total` is not always directly comparable from one phase to another.

### `w_data` and `w_phys`

Weights applied to data loss and physics loss.

These weights are used to balance terms that may have different numerical scales.

---

## Common Failure Modes

### Good visual fit but poor parameter recovery

This can happen when several parameter combinations produce similar trajectories.

Recommended interpretation:

> The state was reconstructed, but the parameters were not uniquely identified.

---

### Stagnant parameter traces

This may indicate weak gradients, poor initialization, or insufficient information in the data.

Recommended response:

- Try a different initial guess.
- Reduce noise.
- Increase epochs.
- Compare repeated runs.

---

### Large physics residual

This may indicate optimization failure or model inadequacy.

Recommended response:

- Inspect parameter traces.
- Check whether data loss is low.
- Rerun with different initial guesses.
- Ask whether the proposed ODE model is appropriate.

---

### Large fitted values of \(K\) or \(c\)

This may occur in the Holling Type II model, especially with real data.

Recommended interpretation:

> The model may be using carrying capacity or half-saturation as flexible fitting terms rather than estimating biologically meaningful constants.

---

## Assessment Ideas

Possible graded or ungraded assessments include:

1. Exit ticket comparing `L_data` and `L_phys`.
2. Short paragraph interpreting a parameter trace.
3. Worksheet comparing two runs with different initial guesses.
4. Model-comparison report for Module 4.
5. Group presentation on a successful run and a failed run.
6. Reflection on when PINNs are useful and when classical methods may be preferable.

---

## Instructor Notes on Framing

PINNLab should not be presented as replacing classical numerical methods. Classical solvers, nonlinear least squares, maximum likelihood, and Bayesian inference remain important tools for parameter estimation.

The value of PINNLab is pedagogical: it gives students a visible way to connect differential equations, noisy data, neural-network function approximation, automatic differentiation, optimization, and model diagnostics.

The central message for students is:

> Differential equations are not only equations to be solved. They are models to be tested, interpreted, and revised in light of data.
