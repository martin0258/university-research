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
+ adaboostR2(x, y, num_predictors, base_predictor, base_predictor_params, loss_function) : object
+ predict.adaboostR2(object, x) : predictions
+ summary.adaboostR2(object) : object_summary
- adaboostR2._weighted_median(x, weights) : weighted_median
```

### Decision
#### Q: Types of base predictor to support?
For now, we only support the following packages that support training with data weights by default:
- [rpart](http://cran.r-project.org/web/packages/rpart/index.html)
- [lm](http://stat.ethz.ch/R-manual/R-patched/library/stats/html/lm.html)

Idealy, any algorithm can be used by resampling (futher improvement).
