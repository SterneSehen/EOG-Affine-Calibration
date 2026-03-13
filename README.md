[![DOI](https://zenodo.org/badge/1174072621.svg)](https://doi.org/10.5281/zenodo.18994963)
# EOG-Affine-Calibration
EOG-based gaze direction classification using trajectory and displacement-based affine calibration. 

## Overview

Electrooculography (EOG) provides a simple and low-cost way to detect eye movements by measuring the corneo-retinal potential difference. Because EOG signals are highly susceptible to low-frequency noise and drift, accurately estimating gaze direction remains challenging.

This project evaluates the use of affine calibration techniques to estimate gaze displacement from EOG signals. Two calibration strategies were implemented and compared:

- Trajectory-based affine calibration
- Displacement-based affine calibration

The calibrated signals were used to classify gaze direction using multiple directional schemes, including 4-class, skewed 4-class, and 8-class configurations.

Results suggest that displacement-based affine calibration provides more reliable gaze displacement estimation and improves classification performance in multi-directional tasks.

## Key Contributions

This repository provides:

- Implementation of trajectory-based and displacement-based affine calibration methods for EOG signals
- Direction classification frameworks for:
  - 4-quadrant classification
  - skewed 4-quadrant classification
  - 8-direction classification
- Diagnostic analysis of classification errors across direction classes
- Reproducible pipeline for evaluating EOG gaze direction estimation

## Methods

The analysis pipeline consists of the following stages:

1. Affine calibration
   - trajectory-based calibration
   - displacement-based calibration
2. Gaze displacement estimation
3. Direction classification
4. Performance evaluation

## Results Summary

The classification framework was evaluated across multiple directional schemes.

Key observations include:

- Displacement-based affine calibration produced more consistent gaze displacement estimates.
- Classification performance improved when using displacement-based calibration.
- Two main error sources: low-amplitude saccades and near-boundary enpoints.

The highest performance was achieved in the 8-direction classification scheme using displacement-based calibration with amplitude(<1°), with an accuracy of approximately **71.85%**.

## Dataset

This project uses a publicly available electrooculography dataset - dataset 2 from Univeristy of Malta.

Dataset source:
[https://www.um.edu.mt/cbc/ourprojects/eyecon/eogdataset/]

The dataset is not included in this repository. Please download it from the original source.

## Running the Code

### 1. Download the Dataset

### 2. Update Dataset Path

Open the main MATLAB scripts and update the dataset directory path to match the location where you saved the dataset.
### 3. Run the Analysis Pipeline

The project code is located in the `src/` directory.

Typical workflow:

1. Preprocess the EOG signals  
2. Apply affine calibration (trajectory-based or displacement-based)  
3. Perform direction classification  
4. Generate visualizations and statistical analysis

Run the relevant MATLAB scripts in the `src/` folder to reproduce the analyses.

### 4. Example Outputs

The scripts generate outputs including:

- confusion matrices for direction classification
- spatial endpoint plots with sectional accuracy 
- statistical comparisons between calibration methods
- statistical comparison between classifers 
- additional analysis such as filtering low-amplitude saccades

These results correspond to the analyses presented in the project report.

### Notes

- The dataset itself is not included in this repository due to licensing restrictions.
- Ensure MATLAB and required toolboxes are installed before running the scripts.
  
## Author

Letian Xie  
University of Melbourne  
Biomedical Engineering

## Citation

If you use this code, please cite:

Xie, L. (2026).
EOG-Based Gaze Direction Classification Using Affine Calibration.
Zenodo. DOI: 10.5281/zenodo.18994964

Available at:
[https://github.com/Letian-Xie/EOG-Affine-Calibration]

## License

This project is released under the MIT License. See the LICENSE file for details.

## Acknowledgements

This project was completed as part of a research project under the supervision of Associate Progfessor Sam John at the University of Melbourne.
