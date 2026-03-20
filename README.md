# Octopus Tentacle POD Analysis

Proper Orthogonal Decomposition (POD) of octopus tentacle kinematics for soft robotics applications.

## Overview
This repository contains MATLAB code for analyzing octopus tentacle motion data using snapshot POD and spectral analysis. The decomposition identifies dominant motion patterns (reaching, grasping, fine manipulation) that inform soft robotic actuator design.

## Data
- `data/octopus_tentacle_data.csv`: Centerline coordinates (x,y,z) of octopus tentacle over 100 frames
- 3 phases: extension (frames 0-39), grasping (40-64), retraction (65-99)

## Code
- `src/octopus_pod_analysis.m`: Main MATLAB script performing:
  - Data loading and preprocessing
  - Snapshot POD implementation
  - FFT frequency analysis
  - Reconstruction and validation
  - Visualization generation

## Usage
```matlab
cd src/
generate_data 
octopus_pod_analysis 
