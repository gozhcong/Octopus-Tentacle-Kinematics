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

The trajectory exhibits a slight curvature, indicating non-linear bending during the retraction phase
