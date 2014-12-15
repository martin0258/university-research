# Test AdaBoost.R2 with 1D sinusoidal dataset with Gaussian noise.
# Ref: http://scikit-learn.org/stable/auto_examples/ensemble/plot_adaboost_regression.html

library(nnet)
library(caret)
# Set working dir to current file location
# Ref: http://stackoverflow.com/a/25995989
this.dir <- dirname(parent.frame(2)$ofile)
setwd(this.dir)
source("../adaboostR2.R")

set.seed(1)

# create the dataset
num_cases <- 100
x <- seq(from=0, to=6, length.out=num_cases)
y <- sin(x) + sin(6 * x) + rnorm(num_cases, mean=0, sd=0.1)
data <- data.frame(y, x)

# train nnet
# nn <- nnet(y~., data, size=1, linout=TRUE, rang=0.1, decay=5e-4, maxit=200, trace=FALSE)
# prediction_nn <- predict(nn, data['x'])

# tune nnet
nn_t <- train(y~., data, method='nnet', linout=TRUE, trace=FALSE)
prediction_nn_t <- predict(nn_t, data['x'])

# train AdaBoost.R2 with nnet
# tune "size" and "decay"
ada_nn <- adaboostR2(y~., data, num_predictors=300, verbose=TRUE, base_predictor=nnet,
                     linout=TRUE, trace=FALSE,
                     size=nn_t$bestTune$size, decay=nn_t$bestTune$size)
prediction_ada_nn <- predict(ada_nn, data['x'])

# train regression tree
# rp <- rpart(y~., data)
# prediction_rp <- predict(rp, data['x'])

# tune regression tree
# tune "max depth"
rp_t <- train(y~., data, method='rpart2', tuneLength=6)
prediction_rp_t <- predict(rp_t, data['x'])

# train AdaBoost.R2 with regression tree
ada_rp <- adaboostR2(y~., data, num_predictors=300, verbose=TRUE, base_predictor=rpart,
                     maxdepth=rp_t$bestTune$maxdepth)
prediction_ada_rp <- predict(ada_rp, data['x'])

# plot dataset
plot(x, y, type='b', main='AdaBoost.R2 with 1D sinusoidal dataset with Gaussian noise',
     xlab='data - x', ylab='data - y')
# plot prediction
points(x, prediction_nn_t, type='b', col='blue')
points(x, prediction_ada_nn, type='b', col='red')
points(x, prediction_rp_t, type='b', col='green')
points(x, prediction_ada_rp, type='b', col='orange')
legends <- c('training data',
             'nnet', 'AdaBoost.R2+nnet',
             'rpart', 'AdaBoost.R2+rpart')
legend('topright', legend=legends,
       col=c('black', 'blue', 'red', 'green', 'orange'),
       cex=0.7, pch=21, lty=1)

# goodness of fit
library(hydroGOF)
performance <- data.frame(gof(prediction_nn_t, data[, 'y']),
                          gof(prediction_ada_nn, data[, 'y']),
                          gof(prediction_rp_t, data[, 'y']),
                          gof(prediction_ada_rp, data[, 'y']))
colnames(performance) <- c('nn', 'ada_nn', 'rp', 'ada_rp')
print(performance)