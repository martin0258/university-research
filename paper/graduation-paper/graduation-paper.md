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
### Models (Learning Algorithms)
- Time series models
  - AR (Autoregressive model)
  - ARIMA (Autoregressive integrated moving average model)
  - ES (Exponential smoothing)
- Regression models
  - Process (same for each weak learner)
    1. Weak learner
    2. Weak learner + AdaBoost.R2
    3. Weak learner + TrAdaBoost.R2
  - Weak learners
    - LR (Linear regression)
    - NN (Neural network)

### Data Sets
- Labels (TVR)
  - Chinese Drama (華劇)
    - 4 dramas are included: 真愛找麻煩, 剩女保鏢, 愛上巧克力, 我們發財了
    - 3 dramas are excluded: 美味的想念, 兩個爸爸, 幸福選擇題
    - Reaons: incompleteness (i.e., too many missing values)
  - Idol Drama (偶像劇)
    - 9 dramas are included: 犀利人妻, 國民英雄, 小資女孩向前衝, 向前走向愛走, 螺絲小姐要出嫁, 我租了一個情人, 金大花的華麗冒險, 大紅帽與小野狼, 真愛黑白配
- Features
  - For each drama, we also have the following features:
    - Facebook
    - Google Trend
    - Opinion

### Settings
- **Training set**: all previous periods of a drama + all periods from other earlier dramas
- **Testing set**: next period of a drama
- **Metric**: MAPE
- **Windowing length**: 4 (decided by performance or autocorrelation?)

### Evaluation
#### Performance Metric
MAPE (Mean Absolute Percentage Error) is the only used metric (Why? Is it good enough?).

In [Forecasting television ratings],
> The prediction errors are judged by two measures, MAPE and MAD, which have been used extensively for gauging the prediction accuracy of television ratings (e.g., Napoli, 2001; Nikolopoulos et al., 2007; Patelis et al., 2003).

#### Statistical Significance Testing
By doing statistical significance testing, the purpose is to seek confidence in the belief that there is statistically significant difference in the experiment. 
However, there are multiple choices of statistical tests. 
The concerns of choosing statistical tests are as below:

1. Number of algorithms to compare (2 or more)
2. Number of domains (different data sets) to compare (2 or more)
3. Parametric or non-parametric statistical tests

The final choice is Friedman's test due to the following reasons:

1. There are more than two algorithms to compare.
2. There are more than two domains to compare.
3. Parametric test is preferred since it is difficult to verify assumptions of non-parametric statistical tests.

For more info, please see [Performance Evaluation for Learning Algorithms: Techniques, Application and Issues] (an ICML 2012 tutorial).

[Forecasting television ratings]: http://www.sciencedirect.com/science/article/pii/S0169207011000033
[Performance Evaluation for Learning Algorithms: Techniques, Application and Issues]: http://www.mohakshah.com/tutorials/icml2012/Tutorial-ICML2012/Tutorial_at_ICML_2012.html
