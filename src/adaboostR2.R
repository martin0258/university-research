adaboostR2 = function( x, y, itr = 50, baseLearner = "lm" ) {
  # Summary: adaboostR2 fits an adaboost model for regression (Drucker, 1997)
  # Note: The base learner used is hard-coded as lm which supports case weights.
  
  # Parameter
  #   x       : the inputs of training data in the form of (x1, x2, ..., xN)
  #   y       : the targets of training data in the form of (y1, y2, ..., yM)
  #   itr     : the number of iterations (i.e., the number of weak learners)
  #   learner : any base learner that fits a model for regression
  # Return
  #   An object of class "adaboostR2".
  #   The object contains the following components:
  #     - models, predictors trained at each iteration
  #     - weights, weights for predictors
  #     - len, number of predictors
  #     - baseLearner, the base learning algorithm

  # initialize return values
  models <- list()
  weights <- list()
  
  # set initial data weights
  numCases <- nrow(data.frame(y))
  dw <- rep(1/numCases, numCases) 
  
  # form a data frame from x, y for linear regresion
  dataBind <- cbind(x, y)
  if(numCases == 1)
  { 
    dataBind <- c(x, y) 
    dataBind <- matrix(dataBind, nrow = 1)
  }
  data <- data.frame(dataBind)
  colnames(data)[ncol(data)] <- "Y"
  
  inputItr <- itr
  for(i in 1:itr)
  {
    # train weak hypothesis by calling base learner
    model <- lm(Y ~ ., data = data, weights = dw)

    # calculate the adjusted error for each case
    errors <- abs(residuals(model))
    if(max(errors) == 0)
    {
      # return if all errors are zero (which probably is impossible)
      # store return values
      models[[length(models)+1]] <- model
      weights[[length(weights)+1]] <- 1
      itr <- i
      cat(sprintf("Break at iteration %d because all errors are zero.\n", i))
      break
    }
    adjustedErrors <- errors / max(errors)
    totalError <- sum(dw * adjustedErrors)
    if(totalError >= 0.5)
    {
      if(i == 1)
      {
        # Issue: similar small errors problem?
        # Workaround: use the trained model
        models[[length(models)+1]] <- model
        weights[[length(weights)+1]] <- 1
      }
      cat(sprintf("Break at iteration %d because total error >= 0.5\n", i))
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
  cat(sprintf("input itr: %d\nactual itr: %d\n", inputItr, itr))
  
  finalModel <- list(models = models, 
               weights = weights, 
               len = length(models), baseLearner = baseLearner)
  class(finalModel) <- "adaboostR2"
  return (finalModel)
}

predict.adaboostR2 = function( object, newData, ... ) {
  # Summary: given new data, return prediction (weighted median) of an adaboost R2 model
  
  # Parameter
  #   model   : the trained adaboostR2 model
  #   newData : the inputs of testing data in the form of (x1, x2, ..., xN)
  # Return
  #   the numeric prediction

  # build a prediction matrix: (row = cases, col = predictors)
  predictions <- vector()
  wmPredictions <- vector()
  
  # form a data frame from newData for linear regression model to predict
  data <- data.frame(newData)
  numPredictors <- length(object$models[[1]]$coefficients) - 1
  if(ncol(data) != numPredictors)
  {
    data <- matrix(newData, nrow = 1)
    data <- data.frame(data)
  }

  for(i in 1:object$len)
  { 
    ## Make column names align with model (assume the 1st element is intercept)
    colnames(data) <- names(coefficients(object$models[[i]]))[-1]
    predictions <- cbind(predictions,
                        predict(object$models[[i]], data))
  }
  # get weighted median for each case
  for(i in 1:nrow(data.frame(data)))
  {
    wmPrediction <- weighted.median(predictions[i,], object$weights)
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