adaboostR2.train = function( x, y, itr = 100, baseLearner = "nnet" ) {
  # Summary: adaboostR2 fits an adaboost model for regression (Drucker, 1997)
  
  # Parameter
  #   x       : the inputs of training data in the form of (x1, x2, ..., xN)
  #   y       : the targets of training data in the form of (y1, y2, ..., yM)
  #   itr     : the number of iterations (i.e., the number of weak learners)
  #   learner : any base learner that fits a model for regression
  # Return
  #   A list of base learners along with their weights to combine

  # hard-coding 
  # library(nnet)  # use nnet as the base learner
  # use linear regression as the base learner (case weights done by sample()
  baseLearner <- "linear regression"

  # initialize return values
  models <- list()
  weights <- list()
  
  # set initial data weights
  numCases <- nrow(data.frame(y))
  dw <- rep(1/numCases, numCases) 
  
  # form a data frame from x, y for linear regresion
  data <- data.frame(cbind(x, y))
  colnames(data)[ncol(data)] <- "Y"
  
  inputItr <- itr
  for(i in 1:itr)
  {
    # train weak hypothesis by calling base learner
#     model <- nnet(x, y,
#                   weights = dw,
#                   size = ncol(x),
#                   linout = TRUE,
#                   trace = FALSE)

    # resampling with current case weights
    newIndex <- sample(1:numCases, numCases, replace = TRUE, dw)
    model <- lm(Y ~ ., data=data[newIndex, ])

    # calculate the adjusted error for each case
#     prediction <- predict(model, x)
#     errors <- abs(y - prediction)
    errors <- abs(residuals(model))
    # TODO: return if all errors are zero (which probably is impossible)
    adjustedErrors <- errors / max(errors)
    totalError <- sum(dw * adjustedErrors)
    if(totalError >= 0.5)
    {
      itr <- i - 1
      break
    }
  
    # update data weights
    beta <- totalError / (1 - totalError)
    dw <- dw * beta ^ (1 - adjustedErrors)
    dw <- dw / sum(dw)  # normalization
    
    # store return values
    models[[length(models)+1]] <- model
    weights[[length(weights)+1]] <- log(1/beta)
  }
  cat(sprintf("input itr: %d\nactual itr: %d", inputItr, itr))
  
  return (list(models = models, 
               weights = weights, 
               len = itr, baseLearner = baseLearner))
}

adaboostR2.predict = function( model, newData ) {
  # Summary: given new data, return prediction (weighted median) of an adaboost R2 model
  
  # Parameter
  #   model   : the trained adaboostR2 model
  #   newData : the inputs of testing data in the form of (x1, x2, ..., xN)
  # Return
  #   the numeric prediction

  # build a prediction matrix: (row = cases, col = predictors)
  predictions <- vector()
  wmPredictions <- vector()
  
  # form a data frame from newData for linear regresion model to predict
  newData <- data.frame(newData)

  for(i in 1:model$len)
  { 
    ## Make column names align with model (assume the 1st element is intercept)
    colnames(newData) <- names(coefficients(model$models[[i]]))[-1]
    predictions <- cbind(predictions,
                        predict(model$models[[i]], newData))
  }
  # get weighted median for each case
  for(i in 1:nrow(data.frame(newData)))
  {
    wmPrediction <- weighted.median(predictions[i,], model$weights)
    wmPredictions <- c(wmPredictions, wmPrediction)
  }
  return (wmPredictions)
}

weighted.median = function( x, weights ) {
  # Summary: computed weighted median
  #  
  # Parameter
  #   x       : a numeric vector containing the values whose median is to be computed
  #   y       : a numeric vector containing the weights
  #
  # Return
  #   the weighted median
  weights <- unlist(weights)
  cases <- vector()
  for(i in 1:length(x))
  {
    cases <- rbind(cases, c(x[i], weights[i]))
  }
  df <- data.frame(cases)
  names(df) <- c("x", "weights")
  threshold <- sum(df$weights) / 2
  dfOrdered <- df[order(x),]
  weightSum <- 0
  for(i in 1:length(x))
  {
    weightSum <- weightSum + dfOrdered$weights[i]
    if(weightSum >= threshold)
    {
      return (dfOrdered$x[i])
    }
  }
}

# Example:
# cwd <- read.csv("data/Chinese_Weekday_Drama.csv", fileEncoding="utf-8")
# d <- windowing(cwd[,4], 4)
# trainEndIndex <- floor(nrow(d)/2)
# testStartIndex <- trainEndIndex + 1
# model <- adaboostR2.train(d[1:trainEndIndex,1:3], d[1:trainEndIndex,4])
# predictions <- adaboostR2.predict(model, d[testStartIndex:nrow(d),1:3])