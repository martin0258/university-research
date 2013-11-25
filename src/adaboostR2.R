adaboostR2 = function( x, y, itr=100, learner="nnet" ) {
  # Summary: adaboostR2 fits an adaboost model for regression (Drucker, 1997)
  
  # Parameter
  #   x       : the inputs of training data in the form of (x1, x2, ..., xN)
  #   y       : the targets of training data in the form of (y1, y2, ..., yM)
  #   itr     : the number of iterations (i.e., the number of weak learners)
  #   learner : any base learner that fits a model for regression
  # Return
  #   A list of base learners along with their weights to combine

  # hard-coding 
  # use nnet as the base learner
  baseLearner <- "nnet"
  library(nnet)

  # initialize return values
  models <- list()
  weights <- list()
  
  # set initial data weights
  numCases <- nrow(data.frame(y))
  dw <- rep(1/numCases, numCases) 
  
  inputItr <- itr
  for(i in 1:itr)
  {
    # train weak hypothesis by calling base learner
    model <- nnet(x, y,
                  weights = dw,
                  size = ncol(x),
                  linout = TRUE,
                  trace = FALSE)

    # calculate the adjusted error for each case
    prediction <- predict(model, x)
    errors <- abs(y - prediction)
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
  
  # the final hypothesis is weighted median (what does it mean?)
  return (list(models = models, 
               weights = weights, 
               len = itr, baseLearner = baseLearner))
}
