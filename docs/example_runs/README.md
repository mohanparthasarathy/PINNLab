# Example Runs

This folder is intended to store screenshots from representative PINNLab runs.

Screenshots are useful for instructors preparing lectures, worksheets, presentations, or documentation. They also help students recognize the difference between successful convergence, partial convergence, and failed or ambiguous runs.

Suggested structure:

```text
example_runs/
    README.md
    screenshots/
        demo_exponential_success.png
        module1_forced_ode_success.png
        module2_lotka_volterra_success.png
        module3_holling_success.png
        module3_holling_failure_mode.png
        module4_hare_lynx_fit.png
```

The screenshot filenames above are suggestions only.

---

## Recommended Screenshots

### Demo: Exponential Growth

Suggested screenshot:

- noisy data,
- fitted exponential trajectory,
- \(k\)-parameter convergence,
- final parameter table.

Teaching use:

> Introduces the basic PINN workflow in a familiar ODE.

---

### Module 1: Forced ODE

Suggested screenshot:

- noisy population data,
- recovered state,
- forcing function \(Q(t)\),
- \(k\)-convergence trace,
- log message showing log-state training.

Teaching use:

> Shows how empirical or user-defined forcing enters a physics-informed residual.

---

### Module 2: Lotka--Volterra

Suggested screenshot:

- prey data and fitted prey trajectory,
- predator data and fitted predator trajectory,
- four parameter traces,
- final table with true values, initial guesses, estimates, and errors.

Teaching use:

> Shows coupled residuals and highlights the difference between trajectory fit and parameter recovery.

---

### Module 3: Holling Type II Successful Run

Suggested screenshot:

- synthetic prey and predator data,
- fitted trajectories,
- six parameter traces,
- final parameter table.

Teaching use:

> Shows that a higher-dimensional PINN can recover parameters when the trajectory is informative and optimization succeeds.

---

### Module 3: Holling Type II Failure or Partial-Recovery Run

Suggested screenshot:

- visually good trajectory fit,
- one or more poor parameter estimates,
- stagnant or unstable parameter traces,
- training log showing residual behavior.

Teaching use:

> Demonstrates that PINNs can fail or partially succeed. This is useful for discussing identifiability, local minima, initialization sensitivity, and diagnostic interpretation.

---

### Module 4: Hare--Lynx Data

Suggested screenshot:

- historical hare data,
- historical lynx data,
- fitted trajectories,
- fitted parameter table,
- any diagnostic warning about large \(K\) or \(c\).

Teaching use:

> Shows the difference between synthetic parameter recovery and real-data model calibration.

---

## Suggested Caption Template

When adding screenshots to teaching materials, consider using captions like:

```text
PINNLab output for Module 2. The top panel shows reconstructed prey and predator trajectories, while the bottom panel shows convergence of the estimated Lotka--Volterra parameters. The table reports true synthetic values, initial guesses, final estimates, and percent errors.
```

For failure-mode screenshots:

```text
Example of partial parameter recovery in Module 3. The reconstructed trajectories fit the synthetic observations reasonably well, but one or more parameter estimates remain far from their true values. This illustrates that state reconstruction and parameter identification are distinct tasks.
```

For Module 4:

```text
PINNLab output for the historical hare--lynx dataset. Because the true ecological parameters are unknown, estimates should be interpreted as fitted calibration values rather than recovered ground truth.
```

---

## Notes for Contributors

When adding screenshots:

1. Use high-resolution images.
2. Avoid cropping out the training log if the log is relevant.
3. Prefer screenshots with readable axes, legends, and parameter tables.
4. Include both successful and imperfect runs when useful for teaching.
5. Do not present a failed run as a software error unless the code actually crashed.
