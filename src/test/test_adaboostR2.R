# Test AdaBoost.R2 with 1D sinusoidal dataset with Gaussian noise.
# Ref: http://scikit-learn.org/stable/auto_examples/ensemble/plot_adaboost_regression.html

library(nnet)
source("../adaboostR2.R")

set.seed(1)

# create the dataset
num_cases <- 100
x <- seq(from=0, to=6, length.out=num_cases)
y <- sin(x) + sin(6 * x) + rnorm(num_cases, mean=0, sd=0.1)
data <- data.frame(y, x)

# train nnet
nn <- nnet(y~., data, size=1, linout=TRUE, rang=0.1, decay=5e-4, maxit=200, trace=FALSE)
prediction_nn <- predict(nn, data['x'])

# train AdaBoost.R2 with nnet
ada_nn <- adaboostR2(y~., data, num_predictors=300, verbose=TRUE, base_predictor=nnet,
                     size=1, linout=TRUE, rang=0.1, decay=5e-4, maxit=200, trace=FALSE)
prediction_ada_nn <- predict(ada_nn, data['x'])

# train regression tree
rp <- rpart(y~., data)
prediction_rp <- predict(rp, data['x'])

# train AdaBoost.R2 with regression tree
ada_rp <- adaboostR2(y~., data, num_predictors=300, verbose=TRUE, base_predictor=rpart)
prediction_ada_rp <- predict(ada_rp, data['x'])

# plot dataset
plot(x, y, type='b', main='AdaBoost.R2 with 1D sinusoidal dataset with Gaussian noise',
     xlab='data - x', ylab='data - y')
# plot prediction
points(x, prediction_nn, type='b', col='blue')
points(x, prediction_ada_nn, type='b', col='red')
points(x, prediction_rp, type='b', col='green')
points(x, prediction_ada_rp, type='b', col='orange')
legends <- c('training data',
             'nnet', 'AdaBoost.R2+nnet',
             'rpart', 'AdaBoost.R2+rpart')
legend('topright', legend=legends,
       col=c('black', 'blue', 'red', 'green', 'orange'),
       cex=0.7, pch=21, lty=1)

# goodness of fit
library(hydroGOF)
performance <- data.frame(gof(prediction_nn, data['y']),
                          gof(prediction_ada_nn, data[, 'y']),
                          gof(prediction_rp, data[, 'y']),
                          gof(prediction_ada_rp, data[, 'y']))
colnames(performance) <- c('nn', 'ada_nn', 'rp', 'ada_rp')
print(performance)