AdaBoostR2 Class Design
=======================
### Requirement
This class is designed for [AdaBoost.R2](../../algorithm/AdaBoostR2.Rmd).

### Class Name
adaboostR2

### Attribute
```
+ num_predictors
+ base_predictor
+ base_predictor_params
+ loss_function
+ learning_rate
+ predictors
+ predictor_weights
```

### Operation
```
+ adaboostR2(x, y, num_predictors, base_predictor, base_predictor_params, loss_function, learning_rate)
+ predict.adaboostR2(object, x)
+ summary.adaboostR2(object)
- adaboostR2._weighted_median(x, weights)
- adaboostR2._fit(x, y)
- adaboostR2._boost(x, y, sample_weights)
```
