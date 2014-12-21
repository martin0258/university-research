library(rpart)
library(hydroGOF) # for default error_fun
library(lattice)  # for plotting errors over iterations

trAdaboostR2 <- function( formula, source_data, target_data,
                          val_data = NULL,
                          num_predictors = 50,
                          learning_rate = 1,
                          loss = 'linear',
                          weighted_sampling = TRUE,
                          verbose = FALSE,
                          error_fun = mse,
                          base_predictor = rpart, ...
                        ) {
  # Fits and returns a TrAdaBoost.R2 model.
  #
  # Arguments:
  #   formula:
  #     An object of class "formula".
  #
  #   source_data:
  #     A data frame containing the variables in the model.
  #     If you have multiple sources, combine them into one.
  #
  #   target_data:
  #     A data frame containing the variables in the model.
  #
  #   val_data:
  #     Validation data.
  #     It is a data frame containing the variables in the model.
  #     Boosting will stop early if validation error increases.
  #
  #   num_predictors:
  #     The maximum number of estimators (iterations) at which boosting is terminated.
  #     In case of perfect fit, the learning procedure is stopped early.
  #     Default 50.
  #
  #   learning_rate:
  #     It shrinks the contribution of each predictor by learning_rate.
  #     There is a trade-off between learning_rate and num_predictors.
  #     Defaul 1.
  #
  #   loss:
  #     The loss function to use when updating the weights
  #     after each boosting iteration. Must be one of the strings in the
  #     default argument.
  #     Default 'linear'.
  #
  #   weighted_sampling:
  #     Whether to use weighted sampling during training.
  #     For base learner that does not support training with instance weights,
  #     this option must be used.
  #     Defaul TRUE.
  #
  #   verbose:
  #     Whether to print detailed messages during execution process.
  #     Defaul FALSE.
  #
  #   base_predictor:
  #     The function of base estimator from which the boosted ensemble is built.
  #     Support for sample weighting is required. That is, the function must be
  #     in the form function( formula, data, weights, ... ).
  #     Default nnet.
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
  #
  # References:
  #   - [1] David Pardoe and Peter Stone.
  #     Boosting for Regression Transfer.
  #     ICML 2010.
  #
  #   - [2] Dai,Wenyuan, Yang, Qiang, Xue, Gui-rong, and Yu, Yong.
  #     Boosting for transfer learning.
  #     ICML 2007.

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

  # combine source and target data to a single dataset
  data <- rbind(source_data, target_data)
  data <- data.frame(data)
  num_cases <- nrow(data)
  num_src_cases <- nrow(source_data)
  source_idx <- 1:num_src_cases
  target_idx <- (num_src_cases + 1):num_cases

  # set initial data weights
  # Note: based on [1], equally initial weights may not be the best sometimes
  data_weights <- rep(1 / num_cases, num_cases)

  for (t in 1:num_predictors)
  {
    # progress indicator: a dot indicates a training iteration got started
    cat_verbose(verbose, '.')

    # train a weak hypothesis of base predictor
    if (weighted_sampling) {
      # instead of training with data_weights,
      # we can do weighted sampling of the training set with replacement,
      # and fit on the bootstrapped sample and obtain a prediction.
      bootstrap_idx <- sample(num_cases, replace=TRUE, prob=data_weights)
      predictor <- do.call(base_predictor,
                           args=list(formula=model_formula,
                           data=data[bootstrap_idx, ], ...))
    } else {
      # By using do.call can resolve the env scope issue of 'weights'
      # Reference: http://stackoverflow.com/a/6957900
      predictor <- do.call(base_predictor,
                           list(formula=form,
                                data=data,
                                weights=data_weights, ...))
    }

    prediction <- predict(predictor, data)

    errors <- abs(prediction - data[response])
    errors_max_source <- max(errors[source_idx, ], na.rm=TRUE)
    errors_max_target <- max(errors[target_idx, ], na.rm=TRUE)
    if (errors_max_target == 0) {
      # early termination:
      #   if the fit is perfect, store the predictor info and stop
      predictors[[t]] <- predictor
      predictors_weights[[t]] <- 1
      cat_verbose(verbose, '\n')
      msg <- "Training: Stop at itr %d because fit is perfect, loss = 0"
      cat_verbose(verbose, sprintf(msg, t))
    } else {
      # normalize errors
      errors[target_idx, ] <- errors[target_idx, ] / errors_max_target
      if (errors_max_source != 0) {
        errors[source_idx, ] <- errors[source_idx, ] / errors_max_source
      }
  
      if (loss == 'square') {
        errors <- errors ^ 2
      } else if (loss == 'exponential') {
        errors <- 1 - exp(- errors)
      }
  
      avg_loss <- sum(data_weights[target_idx] * errors[target_idx, ],
                      na.rm=TRUE)
      avg_losses[[t]] <- avg_loss
  
      if (avg_loss >= 0.5) {
        # early termination:
        #   stop if the fit is too "terrible"
        #   TODO: fix the case of similar small errors
        cat_verbose(verbose, '\n')
        msg <- "Training: Stop at itr %d because fit is too bad, loss (%.2f) >= 0.5"
        cat_verbose(verbose, sprintf(msg, t, avg_loss))
        break
      } else {
        beta_t <- avg_loss / (1 - avg_loss)
        # TODO: confirm N (in paper) to used during early termination.
        beta <- 1 / (1 + sqrt(2 * log(num_src_cases / num_predictors)))
  
        ## update weights of source instances
        data_weights[source_idx] <-
          data_weights[source_idx] *
          beta ^ (errors[source_idx, ] * learning_rate)
  
        ## update weights of target instances
        data_weights[target_idx] <-
          data_weights[target_idx] *
          beta_t ^ (-errors[target_idx, ] * learning_rate)
  
        # normalize
        data_weights <- data_weights / sum(data_weights)
  
        # store the predictor info
        predictors[[t]] <- predictor
        predictors_weights[[t]] <- learning_rate * log(1 / beta_t)
      }
    }

    # monitor performance of current ensemble
    # WARNING: very time-consuming due to prediction performance!!
    fit <- construct.trAdaboostR2(predictors, predictors_weights)
    predictions <- predict(fit, target_data, verbose=F,
                           train_base_predictions_cache)
    train_prediction <- predictions[['final_predictions']]
    train_base_predictions_cache <- predictions[['base_predictions_cache']]
    train_error <- error_fun(train_prediction, target_data[, response])
    train_errors <- c(train_errors, train_error)

    if (!is.null(val_data)) {
      predictions <- predict(fit, val_data, verbose=F,
                             val_base_predictions_cache)
      val_prediction <- predictions[['final_predictions']]
      val_base_predictions_cache <- predictions[['base_predictions_cache']]
      val_error <- error_fun(val_prediction, val_data[, response])
      val_errors <- c(val_errors, val_error)
    }

    # early stop if fit of this iteration is perfect
    if (errors_max_target == 0) break
  }
  
  # newline after printing one or more dots
  cat_verbose(verbose, '\n')
  
  # plot errors over iterations
  if (is.null(val_data)) val_errors <- rep(NA, length(train_errors))
  errors_over_itrs <- data.frame(val_errors, train_errors)
  p <- xyplot(ts(errors_over_itrs), superpose=T, type='o', lwd=2,
              main='Errors over iterations', xlab='Iteration', ylab='Error')
  print(p)
  
  # re-train with full data, and num_predictors is determined by min val error
  if (!is.null(val_data)) {
    full_target_data <- rbind(target_data, val_data)
    min_val_error_itr <- which.min(val_errors)
    cat_verbose(verbose, sprintf('Trained %d predictors.\n', length(predictors)))
    cat_verbose(verbose,
                sprintf('Retrain %d predictors with all data based on min val error.\n',
                min_val_error_itr))
    model <- trAdaboostR2(model_formula,
                          source_data = source_data,
                          target_data = full_target_data,
                          num_predictors = min_val_error_itr,
                          learning_rate = learning_rate,
                          weighted_sampling = weighted_sampling,
                          loss = loss,
                          verbose = verbose,
                          error_fun = error_fun,
                          base_predictor = base_predictor, ... )
    model$errors <- errors_over_itrs
    return(model)
  }

  final_predictor <- list(predictors=predictors,
                          predictors_weights=predictors_weights,
                          num_predictors=length(predictors),
                          input_num_predictors=num_predictors,
                          avg_losses=avg_losses)
  class(final_predictor) <- "trAdaboostR2"

  return (final_predictor)
}

construct.trAdaboostR2 <- function (predictors,
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
  class(predictor) <- 'trAdaboostR2'
  return (predictor)
}

predict.trAdaboostR2 <- function( object, new_data, verbose = FALSE,
                                  base_predictions_cache = NULL) {
  # Returns predictions for new data.
  #
  # Arguments:
  #   object: The trAdaboostR2 predictor.
  #
  #   new_data: The matrix or data frame of inputs for training data.
  #
  #   verbose:
  #     Whether to print detailed messages during execution process.
  #     Defaul FALSE.
  #
  # Returns: The predictions for new data.

  if (object$num_predictors == 0) {
    msg <- 'Prediction: Unable to predict because of no base predictor.'
    cat_verbose(verbose, msg, '\n')
    return (rep(as.numeric(NA), nrow(new_data)))
  }
  # the newline is for beautifying testthat output
  #cat('\n')

  # initialize return values
  final_predictions <- vector()
  
  # Based on [1], only consider the final ceiling(N/2) predictors
  num_predictors_consider <- ceiling(object$num_predictors / 2)
  predictors_idx <- tail(1:object$num_predictors, num_predictors_consider)
  predictors <- tail(object$predictors, num_predictors_consider)
  predictors_weights <- tail(object$predictors_weights, num_predictors_consider)
  
  # build a base prediction matrix: (row = cases, col = predictors)
  base_predictions <- vector()

  for(i in predictors_idx)
  {
    colname <- sprintf('%s', i)
    if (colname %in% colnames(base_predictions_cache)) {
      # cache hits
      base_predictions <- cbind(base_predictions,
                                base_predictions_cache[, colname])
    } else {
      predictor <- object$predictors[[i]]
      base_prediction <- predict(predictor, new_data)
      base_predictions <- cbind(base_predictions, base_prediction)
      colnames(base_predictions)[ncol(base_predictions)] <- colname
    }
  }

  # for each case, get the weighted median as the final prediction
  weighted_median <- trAdaboostR2._weighted_median
  for(i in 1:nrow(new_data))
  {
    final_prediction <-
      weighted_median(base_predictions[i, ], predictors_weights)
    final_predictions <- c(final_predictions, final_prediction)
  }

  if (is.null(base_predictions_cache)) {
    return (final_predictions)
  } else {
    return (list(final_predictions=final_predictions,
                 base_predictions_cache=base_predictions))
  }
}

summary.trAdaboostR2 <- function( object ) {
  # Summary method for class "trAdaboostR2".
  #
  # Arguments:
  #   object: An object of class "trAdaboostR2".

  return (list(num_predictors = object$num_predictors,
               input_num_predictors = object$input_num_predictors))
}

trAdaboostR2._weighted_median <- function( x, weights ) {
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
  for (i in 1:length(x))
  {
    cases <- rbind(cases, c(x[i], weights[i]))
  }
  df <- data.frame(cases)
  names(df) <- c("x", "weights")
  threshold <- sum(df$weights) / 2
  df_ordered <- df[order(x),]
  weight_sum <- 0
  for (i in 1:length(x))
  {
    weight_sum <- weight_sum + df_ordered$weights[i]
    if (weight_sum >= threshold)
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