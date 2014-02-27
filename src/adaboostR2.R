adaboostR2 = function( formula, data, num_predictors = 50,
                       learning_rate = 1,
                       loss_function = c('linear', 'square', 'exponential'),
                       base_predictor, ... ) {
  # Fits and returns an adaboost model for regression.
  # The algorithm is known as AdaBoost.R2 (Drucker, 1997).
  #  
  # Arguments:
  #   formula: An object of class "formula".
  #
  #   data: An data frame containing the variables in the model.
  #
  #   num_predictors: 
  #     The maximum number of estimators at which boosting is terminated. 
  #     In case of perfect fit, the learning procedure is stopped early.
  #     Default 50.
  #
  #   learning_rate:
  #     It shrinks the contribution of each predictor by learning_rate.
  #     There is a trade-off between learning_rate and num_predictors.
  #     Defaul 1.
  #
  #   loss_function:
  #     The loss function to use when updating the weights 
  #     after each boosting iteration. Must be one of the strings in the
  #     default argument.
  #     Default 'linear'.
  #
  #   base_predictor: 
  #     The function of base estimator from which the boosted ensemble is built.
  #     Support for sample weighting is required. That is, the function must be
  #     in the form function( formula, data, weights, ... ).
  #
  #   ...: The other arguments passed to base_predictor.
  #
  # Returns:
  #   An object of class "adaboostR2".
  #   The object contains the following components:
  #     - predictors: predictors trained at each iteration
  #     - predictor_weights: weight of each predictor
  #     - num_predictors: number of predictors
  #     - avg_losses: average loss of each predictor

  # initialize return values
  predictors <- list()
  predictor_weights <- list()
  avg_losses <- list()
  
  # set initial data weights
  num_cases <- nrow(data)
  data_weights <- rep(1 / num_cases, num_cases)
  
  form <- as.formula(formula, env=environment())
  for(i in 1:num_predictors)
  {
    # Alternative:
    #   instead of training with data_weights,
    #   we can do weighted sampling of the training set with replacement,
    #   and fit on the bootstrapped sample and obtain a prediction.

    # train a weak hypothesis of base predictor
    predictor <- base_predictor(form, data, weights=data_weights, ...)

    # calculate the average loss
    errors <- abs(residuals(predictor))
    errors <- errors / max(errors)
    avg_loss <- sum(data_weights * errors)
    avg_losses[[i]] <- avg_loss

    if(avg_loss == 0) {
      # early termination:
      #   if the fit is perfect, store the predictor info and stop
      predictors[[i]] <- predictor
      predictor_weights[[i]] <- 1
      msg <- "Early terminaion because fit at iteration %d is perfect."
      cat('\n', sprintf(msg, i))
      break
    }
    else if(avg_loss >= 0.5) {
      # early termination:
      #   stop if the fit is too "terrible"
      #   TODO: fix the case of similar small errors
      msg <- "Early termination at iteration %d because avg loss >= 0.5"
      cat('\n', sprintf(msg, i))
      break
    }
    else {
      # update data weights
      beta_confidence <- avg_loss / (1 - avg_loss)
      data_weights <- data_weights * beta_confidence ^ ((1 - errors) * learning_rate)
      # normalize
      data_weights <- data_weights / sum(data_weights)

      # store the predictor info
      predictors[[i]] <- predictor
      predictor_weights[[i]] <- learning_rate * log(1 / beta_confidence)
    }
  }
  
  final_predictor <- list(predictors = predictors,
                     predictor_weights = predictor_weights, 
                     num_predictors = length(predictors),
                     input_num_predictors = num_predictors,
                     avg_losses = avg_losses)
  class(final_predictor) <- "adaboostR2"
  return (final_predictor)
}

predict.adaboostR2 = function( object, new_data ) {
  # Returns predictions for new data.
  
  # Arguments:
  #   object: The adaboostR2 predictor.
  #
  #   new_data: The matrix or data frame of inputs for training data.
  #
  # Returns: The predictions for new data.

  if(object$num_predictors == 0) {
    cat('\n', 'No prediction because there is no base predictor.', '\n')
    return (rep(as.numeric(NA), nrow(new_data)))
  }
  # the newline is for beautifying testthat output
  cat('\n')

  # build a prediction matrix: (row = cases, col = predictors)
  predictions <- vector()
  final_predictions <- vector()
  
  for(predictor in object$predictors)
  { 
    prediction <- predict(predictor, new_data)
    predictions <- cbind(predictions, prediction)
  }

  # for each case, get the weighted median as the final prediction
  weighted_median <- adaboostR2._weighted_median
  for(i in 1:nrow(new_data))
  {
    final_prediction <- weighted_median(predictions[i, ], 
                                        object$predictor_weights)
    final_predictions <- c(final_predictions, final_prediction)
  }
  return (final_predictions)
}

summary.adaboostR2 = function( object ) {
  # Summary method for class "adaboostR2".
  #
  # Arguments:
  #   object: An object of class "adaboostR2".

  return (list(num_predictors = object$num_predictors,
               input_num_predictors = object$input_num_predictors))
}

adaboostR2._weighted_median = function( x, weights ) {
  # Computes weighted median.
  #  
  # Arguments:
  #   x: A numeric vector containing the values whose median is to be computed.
  #
  #   weights: A numeric vector containing the weights.
  #
  # Returns:
  #   The weighted median.

  weights <- unlist(weights)
  cases <- vector()
  for(i in 1:length(x))
  {
    cases <- rbind(cases, c(x[i], weights[i]))
  }
  df <- data.frame(cases)
  names(df) <- c("x", "weights")
  threshold <- sum(df$weights) / 2
  df_ordered <- df[order(x),]
  weight_sum <- 0
  for(i in 1:length(x))
  {
    weight_sum <- weight_sum + df_ordered$weights[i]
    if(weight_sum >= threshold)
    {
      return (df_ordered$x[i])
    }
  }
}
