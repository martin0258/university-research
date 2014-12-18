library(rpart)
library(Defaults)
library(e1071)    # for parameter tuning
library(hydroGOF) # for default error_fun

adaboostR2 <- function( formula, data,
                        val_data = NULL,
                        num_predictors = 50,
                        learning_rate = 1,
                        weighted_sampling = TRUE,
                        loss = 'linear',
                        verbose = FALSE,
                        error_fun = mse,
                        base_predictor = rpart, ... ) {
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
  if (!verbose) {
    if (.Platform$OS.type == "windows") {
      setDefaults(cat, file='nul')
    } else {
      # this only works for linux
      # for windows we need to use NUL or nul
      setDefaults(cat, file='/dev/null')
    }
  }else {
    setDefaults(cat, file='')
  }

  # initialize return values
  predictors <- list()
  predictors_weights <- list()
  avg_losses <- list()
  params <- match.call()

  model_formula <- as.formula(formula, env=environment())
  # get dependent variable name from formula
  # TODO: consider the case of multiple responses
  response <- all.vars(model_formula[[2]])
  
  val_errors <- c()
  train_errors <- c()
  
  # leave-one-out parameter tuning
  tune_control <- tune.control(sampling='fix',
                               error.fun=error_fun)
  
  train_data <- data
  train_num_cases <- nrow(train_data)
  
  # set initial data weights
  train_data_weights <- rep(1 / train_num_cases, train_num_cases)
  
  for(i in 1:num_predictors)
  {
    cat(sprintf('AdaBoost.R2 iteration %2d...\n', i))
    # train a weak hypothesis of base predictor
    if(weighted_sampling) {
      # instead of training with data_weights,
      # we can do weighted sampling of the training set with replacement,
      # and fit on the bootstrapped sample and obtain a prediction.
      bootstrap_idx <- sample(train_num_cases,
                              replace=TRUE, 
                              prob=train_data_weights)
#       tune_result <- tune(base_predictor,
#                           model_formula, data=train_data[bootstrap_idx, ],
#                           ranges=list(maxdepth=seq(1, 4)),
#                           tunecontrol=tune_control, ...)
#       predictor <- tune_result$best.model
      predictor <- do.call(base_predictor,
                           args=list(formula=model_formula,
                           data=train_data[bootstrap_idx, ], ...))
    } else {
      # By using do.call can resolve the env scope issue of 'weights'
      # Reference: http://stackoverflow.com/a/6957900
      predictor <- do.call(base_predictor,
                           list(formula=model_formula,
                                data=train_data,
                                weights=train_data_weights, ...))
    }

    prediction <- predict(predictor, train_data)

    errors <- abs(prediction - train_data[response])
    errors_max <- max(errors, na.rm = TRUE)
    if (errors_max == 0) {
      # early termination:
      #   if the fit is perfect, store the predictor info and stop
      predictors[[i]] <- predictor
      predictors_weights[[i]] <- 1
      msg <- "Training: Stop at itr %d because fit is perfect, loss = 0"
      cat(sprintf(msg, i), '\n')
      break
    }
    errors <- errors / errors_max
    
    if (loss == 'square') {
      errors <- errors ^ 2
    } else if(loss == 'exponential') {
      errors <- 1 - exp(- errors)
    }
    
    avg_loss <- sum(train_data_weights * errors, na.rm = TRUE)
    avg_losses[[i]] <- avg_loss

    if (avg_loss >= 0.5) {
      # early termination:
      #   stop if the fit is too "terrible"
      #   TODO: fix the case of similar small errors
      msg <- "Training: Stop at itr %d because fit is too bad, loss (%.2f) >= 0.5"
      cat(sprintf(msg, i, avg_loss), '\n')
      break
    } else {
      # update data weights
      beta_confidence <- avg_loss / (1 - avg_loss)
      train_data_weights <- 
        train_data_weights * beta_confidence ^ ((1 - errors) * learning_rate)

      # normalize
      train_data_weights <- train_data_weights / sum(train_data_weights)

      # store the predictor info
      predictors[[i]] <- predictor
      predictors_weights[[i]] <- learning_rate * log(1 / beta_confidence)
    }
    
    # monitor performance of current ensemble
    # WARNING: very time-consuming due to prediction performance!!
    current_ada <- construct.adaboostR2(predictors,
                                        predictors_weights)
    train_prediction <- predict(current_ada, train_data)
    train_error <- error_fun(train_prediction, train_data[, response])
    train_errors <- c(train_errors, train_error)

    if (!is.null(val_data)) {
      val_prediction <- predict(current_ada, val_data)
      val_error <- error_fun(val_prediction, val_data[, response])
      val_errors <- c(val_errors, val_error)
    }

    # use performance on validation data to determine stop or not
  }

  errors_over_itrs <- data.frame(val_errors, train_errors)
  final_ada <- construct.adaboostR2(predictors,
                                    predictors_weights,
                                    params=match.call(),
                                    errors=errors_over_itrs,
                                    avg_losses)
  setDefaults(cat, file='')
  return (final_ada)
}

construct.adaboostR2 <- function (predictors,
                                  predictors_weights,
                                  params = NULL,
                                  errors = NULL,
                                  avg_losses = NULL
                                  ) {
  # Return an adaboostR2 object
  predictor <- list(predictors = predictors,
                    predictors_weights = predictors_weights, 
                    params = params,
                    num_predictors = length(predictors),
                    errors = errors,
                    avg_losses = avg_losses)
  class(predictor) <- 'adaboostR2'
  return (predictor)
}

predict.adaboostR2 <- function( object, new_data, verbose = FALSE ) {
  # Returns predictions for new data.
  
  # Arguments:
  #   object: The adaboostR2 predictor.
  #
  #   new_data: The matrix or data frame of inputs for training data.
  #
  # Returns: The predictions for new data.
  if(!verbose) {
    if (.Platform$OS.type == "windows") {
      setDefaults(cat, file='nul')
    } else {
      # this only works for linux
      # for windows we need to use NUL or nul
      setDefaults(cat, file='/dev/null')
    }
  }else {
    setDefaults(cat, file='')
  }

  if(object$num_predictors == 0) {
    cat('Prediction: Unable to predict because of no base predictor.', '\n')
    return (rep(as.numeric(NA), nrow(new_data)))
  }
  # the newline is for beautifying testthat output
  #cat('\n')

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
                                        object$predictors_weights)
    final_predictions <- c(final_predictions, final_prediction)
  }
  setDefaults(cat, file='')
  return (final_predictions)
}

summary.adaboostR2 <- function( object ) {
  # Summary method for class "adaboostR2".
  #
  # Arguments:
  #   object: An object of class "adaboostR2".

  return (list(num_predictors = object$num_predictors,
               input_num_predictors = object$input_num_predictors))
}

adaboostR2._weighted_median <- function( x, weights ) {
  # Computes weighted median.
  #  
  # Arguments:
  #   x: A numeric vector containing the values whose median is to be computed.
  #
  #   weights: A numeric vector containing the weights.
  #
  # Returns:
  #   The weighted median.
  
  # use its w.median to check our implementation
  # Note: cannot successfully install the package after it was removed from CRAN
  # library(cwhmisc)

  result <- NA
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
      result <- df_ordered$x[i]
      break
    }
  }

  # WARNING: The following comparison does not handle NA.
#   expected_result <- w.median(x, weights)
#   stopifnot(result == expected_result)
  return (result)
}
