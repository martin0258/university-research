adaboostR2 = function( formula, data, num_predictors = 50,
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
  #     - predictor_weights: weights for predictors
  #     - num_predictors: number of predictors

  # initialize return values
  predictors <- list()
  predictor_weights <- list()
  
  # set initial data weights
  num_cases <- nrow(data)
  data_weights <- rep(1 / num_cases, num_cases)
  
  inputItr <- num_predictors
  form <- as.formula(formula, env=environment())
  for(i in 1:num_predictors)
  {
    # train a weak hypothesis of base predictor
    predictor <- base_predictor(form, data, weights=data_weights, ...)

    # calculate the adjusted error for each case
    errors <- abs(residuals(predictor))
    if(max(errors) == 0)
    {
      # return if all errors are zero (which probably is impossible)
      # store return values
      predictors[[length(predictors) + 1]] <- predictor
      predictor_weights[[length(predictor_weights) + 1]] <- 1
      cat(sprintf("Break at iteration %d because all errors are zero.\n", i))
      break
    }
    adjustedErrors <- errors / max(errors)
    totalError <- sum(data_weights * adjustedErrors)
    if(totalError >= 0.5)
    {
      if(i == 1)
      {
        # Issue: similar small errors problem?
        # Workaround: use the trained model
        predictors[[length(predictors) + 1]] <- predictor
        predictor_weights[[length(predictor_weights) + 1]] <- 1
      }
      cat(sprintf("Break at iteration %d because total error >= 0.5\n", i))
      break
    }
  
    # update data weights
    beta <- totalError / (1 - totalError)
    data_weights <- data_weights * beta ^ (1 - adjustedErrors)
    data_weights <- data_weights / sum(data_weights)
    
    # store return values
    predictors[[length(predictors) + 1]] <- predictor
    predictor_weights[[length(predictor_weights) + 1]] <- log(1 / beta)
  }
  
  final_predictor <- list(predictors = predictors,
                     predictor_weights = predictor_weights, 
                     num_predictors = length(predictors),
                     input_num_predictors = num_predictors)
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

  # build a prediction matrix: (row = cases, col = predictors)
  predictions <- vector()
  final_predictions <- vector()
  

#     data <- matrix(x, nrow = 1)
#     data <- data.frame(data)
#   }
  for(i in 1:object$num_predictors)
  { 
    predictions <- cbind(predictions,
                        predict(object$predictors[[i]], new_data))
  }

  # get weighted median for each case
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
