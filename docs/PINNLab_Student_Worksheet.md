# PINNLab Student Worksheet

Name:

Date:

Course:

---

## Part 1. Demo: Exponential Growth

The model is

\[
\frac{dy}{dt}=ky.
\]

### Before Running

1. What does the parameter \(k\) represent?

2. If \(k\) increases, what should happen to the population trajectory?

3. What initial guess did you choose for \(k\)?

   \[
   k_{\text{init}} =
   \]

4. What true value did you choose for \(k\)?

   \[
   k_{\text{true}} =
   \]

---

### After Running

1. What final estimate did the PINN report?

   \[
   \hat{k} =
   \]

2. Did the fitted curve match the noisy data well?

3. Did the parameter trace stabilize?

4. What is the difference between fitting the state \(y(t)\) and estimating the parameter \(k\)?

---

## Part 2. Module 0: Engage

Module 0 uses the PhET Natural Selection simulation as qualitative motivation.

1. What population outcomes did you observe?

2. Did the population recover, stabilize, oscillate, or collapse?

3. What environmental or biological factors affected the outcome?

4. Why is this simulation not the same thing as a calibrated predator--prey model?

5. What quantities would you need to measure in order to build a quantitative ODE model?

---

## Part 3. Module 1: Forced ODE

The model is

\[
\frac{dy}{dt}-ky=Q(t).
\]

The module uses the transformation

\[
u(t)=\log(y(t)).
\]

### Before Running

1. What forcing function \(Q(t)\) did you use?

2. What does the forcing term represent in the model?

3. What true value and initial guess did you use for \(k\)?

   \[
   k_{\text{true}} =
   \]

   \[
   k_{\text{init}} =
   \]

---

### After Running

1. What final estimate did the PINN report?

   \[
   \hat{k} =
   \]

2. Did the recovered state match the noisy data?

3. Did the \(k\)-trace stabilize?

4. What does the log message `log_state=on` mean?

5. Why might the log transformation improve numerical stability?

6. Which dashboard feature shows evidence of data fit?

7. Which dashboard feature shows evidence of physical consistency?

---

## Part 4. Module 2: Lotka--Volterra

The model is

\[
\frac{dx}{dt}=\alpha x-\beta xy,
\]

\[
\frac{dy}{dt}=-\gamma y+\delta xy.
\]

### Parameter Interpretation

Briefly describe each parameter.

1. \(\alpha\):

2. \(\beta\):

3. \(\gamma\):

4. \(\delta\):

---

### Before Running

Record your true parameters.

\[
\alpha_{\text{true}} =
\]

\[
\beta_{\text{true}} =
\]

\[
\gamma_{\text{true}} =
\]

\[
\delta_{\text{true}} =
\]

Record your initial guesses.

\[
\alpha_{\text{init}} =
\]

\[
\beta_{\text{init}} =
\]

\[
\gamma_{\text{init}} =
\]

\[
\delta_{\text{init}} =
\]

---

### After Running

Record the final estimates.

\[
\hat{\alpha} =
\]

\[
\hat{\beta} =
\]

\[
\hat{\gamma} =
\]

\[
\hat{\delta} =
\]

1. Did the prey trajectory fit the data well?

2. Did the predator trajectory fit the data well?

3. Which parameter was recovered most accurately?

4. Which parameter was recovered least accurately?

5. Did the parameter traces stabilize?

6. Does a visually good trajectory fit guarantee accurate parameter recovery? Explain.

---

### Initial Guess Experiment

Rerun Module 2 with different initial guesses.

1. What changed in the final parameter estimates?

2. What changed in the fitted trajectories?

3. What does this suggest about initialization sensitivity?

---

## Part 5. Module 3: Holling Type II Model

The model is

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

### Parameter Interpretation

Briefly describe each parameter.

1. \(\alpha\):

2. \(K\):

3. \(\beta\):

4. \(c\):

5. \(\gamma\):

6. \(\delta\):

---

### After Running

1. Did the fitted trajectories match the data?

2. Did all parameters converge?

3. Which parameters were hardest to recover?

4. Did any parameter trace appear stagnant?

5. Did you observe a good visual fit but poor parameter recovery?

6. What might explain this behavior?

---

### Failure Mode Reflection

Choose one possible failure mode you observed or could imagine observing:

- stagnant parameter trace,
- high physics residual,
- good data fit but poor parameter recovery,
- unrealistic parameter value,
- unstable or noisy training.

Describe what happened and what you would try next.

---

## Part 6. Module 4: Hare--Lynx Data

Module 4 fits real historical hare--lynx trapping data.

There are no true parameter values.

The dashboard reports fitted estimates, not recovery errors.

### Before Running

Record your initial guesses.

\[
\alpha_{\text{init}} =
\]

\[
K_{\text{init}} =
\]

\[
\beta_{\text{init}} =
\]

\[
c_{\text{init}} =
\]

\[
\gamma_{\text{init}} =
\]

\[
\delta_{\text{init}} =
\]

---

### After Running

Record the fitted estimates.

\[
\hat{\alpha} =
\]

\[
\hat{K} =
\]

\[
\hat{\beta} =
\]

\[
\hat{c} =
\]

\[
\hat{\gamma} =
\]

\[
\hat{\delta} =
\]

1. Did the fitted curves capture the major hare--lynx cycles?

2. Did the model appear physically consistent based on the physics residual?

3. Were the fitted parameters biologically plausible?

4. Did \(K\) or \(c\) become very large?

5. If so, what might that indicate?

---

## Final Reflection

Answer in one or two paragraphs.

1. What is the difference between data fit and physical consistency?

2. What is the difference between state reconstruction and parameter recovery?

3. Why might a PINN fail even when the code is working correctly?

4. What did the real hare--lynx data teach you that synthetic data did not?

5. When might a classical parameter-estimation method be preferable to a PINN?
