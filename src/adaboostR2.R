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

  # initialize return values
  models <- vector()
  weights <- vector()
  
  # set initial data weights
  numCases <- nrow(data)
  dw <- rep(1/numCases, numCases) 
  
  for(i in 1:itr)
  {
    # train weak hypothesis by calling base learner
    model <- nnet(x, y,
                  weights = dw,
                  size = ncol(x),
                  linout = TRUE)

    # calculate the adjusted error for each case
    prediction <- predict(model, x)
    errors <- abs(y - prediction)
    # TODO: return if all errors are zero (which probably is impossible)
    adjustedErrors <- errors / max(errors)
    totalError <- sum(dw * adjustedErrors)
    if(totalError >= 0.5)
    {
      itr <- itr - 1
      break
    }
  
    # update data weights
    beta <- totalError / (1 - totalError)
    dw <- dw * beta ^ (1 - adjustedErrors)
    dw <- dw / sum(dw)  # normalization
    
    # store return values
    models <- c(models, model)
    weights <- c(weights, log(1/beta))
  }
  
  # the final hypothesis is weighted median (what does it mean?)
  return (list(models, weights))
}
