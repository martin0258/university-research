AdaBoostR2 Class Design
=======================

### Class Name
adaboostR2

### Attribute
* num_predictors
* predictors
* weights
* baseLearner

### Operation
#### Public
* adaboostR2
* predict.adaboostR2
* summary.adaboostR2
* plot.adaboostR2

#### Private
* weighted.median
* adaboostR2.fit
* adaboostR2.boost
