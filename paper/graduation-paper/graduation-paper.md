# Predicting TVR using Regression Transfer

> Keywords: time series prediction/forecasting, transfer learning, regression, TV ratings prediction/forecasting

## Abstract
1. **Importance of problem**: Why TVR prediction is an important problem? (Tim: TV industry is dying. 塊陶阿～！)
2. **Status of problem/solutions**: This problem has become increasingly complex (why?), but little attention has been paid to improving accuracy using new methods.
3. **Highlight of this research (contribution)**: The primary contribution of this paper is to first solve TVR prediction using a state-of-the-art approach, regression transfer learning.
4. **Solution of this research**:
  - First, use windowing transformation to convert time series data into a set of cases suitable for regression task.
  - Then, several boosting-based transfer learning algorithms are applied to regression task.
5. **Result of this research**: Experiment results show promise comparing with other tranditional time series models and non-transfer learning algorithms.

## Experiment
### Models
- Time series models
  - AR (Autoregressive model)
  - ARIMA (Autoregressive integrated moving average model)
  - ES (Exponential smoothing)
- Regression models
  - LR (Linear regression)
  - NN (Neural network)
- Transfer learning models
  - LR (weak learner) + TrAdaBoost.R2
  - NN (weak learner) + TrAdaBoost.R2
