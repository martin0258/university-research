library(rpart)
library(e1071)    # for parameter tuning
library(hydroGOF) # for default error_fun
library(lattice)  # for plotting errors over iterations

adaboostR2 <- function( formula, data,
                        val_data = NULL,
                        num_predictors = 50,
                        learning_rate = 1,
                        weighted_sampling = TRUE,
                        loss = 'linear',
                        verbose = FALSE,
                        error_fun = mse,
                        monitor_errors = FALSE,
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
  #     - predictors_weights: weight of each predictor
  #     - num_predictors: number of predictors
  #     - avg_losses: average loss of each predictor

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
  val_base_predictions_cache <- vector()
  train_base_predictions_cache <- vector()
  
  # leave-one-out parameter tuning
  tune_control <- tune.control(sampling='fix',
                               error.fun=error_fun)
  
  train_data <- data
  train_num_cases <- nrow(train_data)
  
  # set initial data weights
  train_data_weights <- rep(1 / train_num_cases, train_num_cases)
  
  for(i in 1:num_predictors)
  {
    # progress indicator: a dot indicates a training iteration got started
    cat_verbose(verbose, '.')
    
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
      cat_verbose(verbose, '\n')
      msg <- "Training: Stop at itr %d because fit is perfect, loss = 0"
      cat_verbose(verbose, sprintf(msg, i))
    } else {
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
        cat_verbose(verbose, '\n')
        msg <- "Training: Stop at itr %d because fit is too bad, loss (%.2f) >= 0.5"
        cat_verbose(verbose, sprintf(msg, i, avg_loss))
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
    }
    
    # monitor performance of current ensemble
    # WARNING: very time-consuming due to prediction performance!!
    if (monitor_errors) {
      current_ada <- construct.adaboostR2(predictors,
                                          predictors_weights)
      predictions <- predict(current_ada, train_data, verbose=F,
                             train_base_predictions_cache)
      train_prediction <- predictions[['final_predictions']]
      train_base_predictions_cache <- predictions[['base_predictions_cache']]
      train_error <- error_fun(train_prediction, train_data[, response])
      train_errors <- c(train_errors, train_error)
  
      if (!is.null(val_data)) {
        predictions <- predict(current_ada, val_data, verbose=F,
                               val_base_predictions_cache)
        val_prediction <- predictions[['final_predictions']]
        val_base_predictions_cache <- predictions[['base_predictions_cache']]
        val_error <- error_fun(val_prediction, val_data[, response])
        val_errors <- c(val_errors, val_error)
      }
    }

    # early stop if fit of this iteration is perfect
    if (errors_max == 0) break
  }

  # newline after printing one or more dots
  cat_verbose(verbose, '\n')

  # plot errors over iterations
  if (monitor_errors) {
    if (is.null(val_data)) val_errors <- rep(NA, length(train_errors))
    errors_over_itrs <- data.frame(val_errors, train_errors)
    p <- xyplot(ts(errors_over_itrs), superpose=T, type='o', lwd=2,
                main='Errors over iterations', xlab='Iteration', ylab='Error')
    print(p)
  }

  # re-train with full data, and num_predictors is determined by min val error
  if (!is.null(val_data)) {
    full_data <- rbind(data, val_data)
    min_val_error_itr <- which.min(val_errors)
    cat_verbose(verbose, sprintf('Trained %d predictors.\n', length(predictors)))
    cat_verbose(verbose,
                sprintf('Retrain %d predictors with all data based on min val error.\n',
                min_val_error_itr))
    model <- adaboostR2(model_formula, full_data,
                        num_predictors=min_val_error_itr,
                        learning_rate = learning_rate,
                        weighted_sampling = weighted_sampling,
                        loss = loss,
                        verbose = verbose,
                        error_fun = error_fun,
                        base_predictor = base_predictor, ... )
    model$errors <- errors_over_itrs
    return(model)
  }

  final_ada <- construct.adaboostR2(predictors,
                                    predictors_weights,
                                    params=match.call(),
                                    errors=NULL,
                                    avg_losses)
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

predict.adaboostR2 <- function( object, new_data, verbose = FALSE,
                                base_predictions_cache = NULL) {
  # Returns predictions for new data.
  
  # Arguments:
  #   object: The adaboostR2 predictor.
  #
  #   new_data: The matrix or data frame of inputs for training data.
  #
  # Returns: The predictions for new data.

  if(object$num_predictors == 0) {
    msg <- 'Prediction: Unable to predict because of no base predictor.'
    cat_verbose(verbose, msg, '\n')
    return (rep(as.numeric(NA), nrow(new_data)))
  }
  # the newline is for beautifying testthat output
  #cat('\n')

  # initialize return values
  final_predictions <- vector()
  
  # build a base prediction matrix: (row = cases, col = predictors)
  if (is.null(base_predictions_cache)) {
    base_predictions <- vector()
    predictor_start_idx <- 1
  } else {
    base_predictions <- base_predictions_cache
    predictor_start_idx <- ifelse(!is.null(ncol(base_predictions)),
                                  ncol(base_predictions) + 1, 1)
  }
  
  for(idx in predictor_start_idx:object$num_predictors)
  { 
    predictor <- object$predictors[[idx]]
    base_prediction <- predict(predictor, new_data)
    base_predictions <- cbind(base_predictions, base_prediction)
  }

  # for each case, get the weighted median as the final prediction
  weighted_median <- adaboostR2._weighted_median
  for(i in 1:nrow(new_data))
  {
    final_prediction <- weighted_median(base_predictions[i, ], 
                                        object$predictors_weights)
    final_predictions <- c(final_predictions, final_prediction)
  }
  
  if (is.null(base_predictions_cache)) {
    return (final_predictions)
  } else {
    return (list(final_predictions=final_predictions,
                 base_predictions_cache=base_predictions))
  }
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

cat_verbose <- function (verbose, ...) {
  if (verbose) {
    do.call('cat', args=list(..., file=''))
  } else {
    # do (print) nothing
  }
}