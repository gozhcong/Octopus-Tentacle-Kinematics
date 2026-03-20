# Raw Data Visualization
`rawdata_visualization.png`
<img width="1659" height="851" alt="rawdata_visualization" src="https://github.com/user-attachments/assets/587986b6-9c4a-44ec-9e7e-992563918b43" />

This figure presents the raw kinematic data extracted from the octopus tentacle video, showing the centerline positions across 100 time frames (t = 0.00 s to t = 2.00 s) with a temporal resolution of 0.02 s (50 Hz sampling). The data comprises 20 equally spaced arc-length points along the tentacle, parameterized from base (s = 0) to tip (s = L).

## Left Panel: Tentacle motion vs time
- Displays 3D motion of the tentacle in reach-grasp-retract sequence at different timing
- The tentacle extends outward in the positive X-direction, reaches maximum extension around t = 0.8 s (grasping onset), then retracts toward the base

## Centre Panel: Phase snapshot
- Extension (t = 0.00 s): Tentacle fully retracted, initial posture
- Grasping (t = 0.80 s): Maximum extension, tip engages target object
- Retraction (t = 1.30 s): Tentacle retracting, tip returning toward base
This snapshot shows the bending and curling deformation during grasping, distinct from the linear extension/retraction motion

## Right Panel: Tip trajectory
- This graph traces the path of the tentacle tip (s = L) over the entire motion sequence
  - Green marker: Starting position at t = 0.00 s
  - Red marker: Grasping position at t = 0.80 s (maximum extension)
  - Black marker: Final position at t = 2.00 s
- The tip trajectory shows curvature, indicating non-linear bending during the retraction phase

# Proper Orthogonal Decomposition (POD) Output
`POD_Mode_Shapes.png`
<img width="2005" height="782" alt="POD_Mode_Shapes" src="https://github.com/user-attachments/assets/c78d318f-2712-4170-a232-d06d2d07ac3f" />

## Left Panel: 1st three POD modes
- Mode 1 (Reaching line in blue)
  - Displays 3D motion of the tentacle in reach-grasp-retract sequence at different timing
  - This pattern represents global extension/retraction motion – the entire tentacle moves in the same direction
  - The tentacle extends outward in the positive X-direction, reaches maximum extension around t = 0.8 s (grasping onset), then retracts toward the base

- Mode 2 (Grasping line in red)
  - The line peaks at distal region (s/L ≈ 0.7–0.9), with minimal contribution near the base
  - This represents localized bending and curling concentrated in the distal half of the tentacle, corresponding to the curling motion used to wrap around and grasp objects
  - Wehn the mode amplitude changes sign, it means there is bending in opposite directions depending on the temporal coefficient sign

- Mode 3 (Fine manipulation in green)
  - The line is more complicated and peaks near the tip (s/L ≈ 0.95), denoting localized fine adjustments, likely associated with the final stages of grasping and tip repositioning
  - The sharp peak suggests that this mode captures the finger-like dexterity of the octopus's distal arm
  
## Centre Panel: Cumulative energy capture
- Individual mode energy (blue bar)
  - Mode 1 dominates overwhelmingly at 73.86%, confirming that reaching/retraction is the primary motion
  - Mode 2 contributes 16.20% – A significant secondary motion pattern (likely curling/grasping)
  - Mode 3 contributes 3.26% – Secondary bending or twisting for fine manipulation or out-of-plane motion
  - Mode 4 contributes 4.79% – Higher-order curvature for localized deformations, possibly from object contact
  - Higher modes (5 and above) contribute negligible energy (<0.15% collectively)
 
- Cumulative energy (red line)
  - Mode 1 misses 26% of the motion, the octopus hand can reach/retract, but cannot grasp properly
  - With Mode 2, we still misses ~10% where grasping info is captured but fine manipulation missing
  - Mode 3 captures fine tip manipulation
  - Mode 4 sees cumulative energy at 98.11%, showing we capture all the previous actions and perhaps some out-of-plane motion
  - Higher modes (5 and above) contribute negligibly

## Right Panel: Mode 1 effect on shape
- Mean Shape (Black Line) indicates the time-averaged tentacle configuration across all frames, and show a slightly curved resting posture
- Max + (Blue Line) corresponds to the reaching/extending phase and tentacle extends further outward (positive X-direction)
- Max - (Red Line) corresponds to the retracting phase and tentacle retracts toward the base (negative X-direction)

# Phase-windowed power spectral density (PSD) of a(t)
`Frequency_Spectra.png`
<img width="2005" height="1050" alt="Frequency_Spectra" src="https://github.com/user-attachments/assets/3ec01ca7-6b6f-4be1-b537-95a33b6ec735" />

Note: f* means max frequency

##  Column 1 — Extension (green, f = 0–39), F* = 1.2 Hz
- All three modes peak at f = 1.2 Hz* with a sharp spike and zero energy above 5 Hz.
- This is the signature of a slow, globally-coordinated proximo-distal elongation wave. 
- Indicates the entire arm is moving coherently during extension — the bending wave recruits spatial patterns from multiple modes simultaneously at the same pace.

##  Column 2 — Grasping (purple, f = 40–64), 
- Mode 1: f* = 14 Hz at 8–16 Hz. Mode 1 still holds the most spatial energy (74%), so even during grasping it responds to the high-frequency sucker-adjustment oscillations at the distal end
- Mode 2: f* = 10 Hz. It captures the mid-frequency tip-curl dynamics with the f* denoting the cyclic sucker contact oscillation during prey capture.
- Mode 3: f* = 10 Hz with a secondary peak near 14 Hz. This indicates finer spatial variation along the curl zone and responds to both the 10 Hz and 14 Hz oscillation frequencies that were embedded in the grasping data.

## Column 3 — Retraction (orange, f = 65–99)
- All three modes has f* = 4.3 Hz, signifying the decaying structural rebound after prey release — the tentacle oscillates freely as it retracts, which causes the spectral broadening around the natural frequency.
- The PSD magnitudes are lower than during extension because retraction is a lower-energy phase with no active high-amplitude forcing.

# Temporal Coefficients
`Temporal_Coefficients.png`
<img width="1875" height="625" alt="Temporal_Coefficients" src="https://github.com/user-attachments/assets/5c857dac-a6e8-49eb-a196-79680a115f53" />

## Mode 1 — blue (reaching)
- Extension Phase (0–0.8 s): Characterized by a monotonic decay (0.085 to -0.05) representing the global elongation wave. This low-frequency transition (1.2 Hz) tracks the spatial commitment of the manipulator to its extended state.
- Grasping Phase (0.8–1.3 s): Exhibits maximum volatility with high-amplitude excursions reaching -0.13. Despite its "reaching" label, Mode 1 captures this deformation due to its 74% spatial variance dominance. The 14 Hz oscillations align with the high-frequency dynamics of the distal tip curl.
- Retraction Phase (1.3–2.0 s): Displays a damped 4 Hz oscillatory recovery toward the baseline. This signifies the structural rebound and transient stabilization as the arm returns to its rest-pose configuration.

## Mode 2 — red (grasping)
- Extension Phase (0–0.8 s): Maintains a negligible amplitude (±0.02) with minor oscillations around the zero-baseline, meaning that Mode 2 has minimal contribution to pure axial elongation.
- Grasping Phase (0.8–1.3 s): Undergoes sharp activation with amplitudes scaling to ±0.06. The rapid sign inversions capture the 10 Hz sucker-contact oscillations, representing the distal bending required for the grasping wrap.
- Retraction Phase (1.3–2.0 s): Exhibits an approximate decaying 4 Hz residual oscillation, indicating a multi-modal structural coupling during the arm's return to its rest-pose.

## Mode 3 — green (fine)
- Maintains low amplitude, which is consistent with it holding only 4.8% of the total energy.
- During extension, it shows a gentle hump peaking around t = 0.5 s, the fine spatial adjustment of the bending wave as the proximo-distal elongation travels along the arm.
- During grasping, it becomes slightly more active with irregular oscillations, capturing the higher-spatial-frequency deformation in the curl zone t
- During retraction, it settles quickly toward zero

# Validation results
`Validation_Results.png`
  <img width="1875" height="782" alt="Validation_Results" src="https://github.com/user-attachments/assets/0f417e36-fad3-4b61-b052-714bb9bb2261" />

# Left panel: Reconstruction error vs. No. of modes 
- This plot shows how the reconstruction error decreases as more modes are included in the reconstruction
- The error curve shows a steep drop from N=1 to N=3; But after N=3, the curve flattens, denoting diminishing returns in the error for reconstruction
- The 5.6% error at N=3: with just three modes, the reconstructed tentacle shape deviates from the actual shape by only 5.6% on average. 

# Right panel: Shape comparison at grasping phase
- Do a visual comparison between the original tentacle shape and the 3-mode reconstruction at the critical grasping moment (t = 0.80 s).
- The reconstructed shape overlays almost perfectly with the original, with overall bending profile is preserved and tip curvature during grasping is accurately reproduced

This validates that 3 spatial modes—corresponding to reaching, grasping, and fine manipulation—are sufficient to capture the essential kinematics of the octopus tentacle for soft robotic design purposes.
