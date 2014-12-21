library(rpart)

trAdaboostR2 <- function( formula, source_data, target_data,
                          val_data = NULL,
                          num_predictors = 50,
                          learning_rate = 1,
                          loss = 'linear',
                          weighted_sampling = TRUE,
                          verbose = FALSE,
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
    errors_max <- max(errors, na.rm=TRUE)
    if (errors_max == 0) {
      # early termination:
      #   if the fit is perfect, store the predictor info and stop
      predictors[[t]] <- predictor
      predictors_weights[[t]] <- 1
      cat_verbose(verbose, '\n')
      msg <- "Training: Stop at itr %d because fit is perfect, loss = 0"
      cat_verbose(verbose, sprintf(msg, t))
    } else {
      errors <- errors / errors_max
  
      if (loss == 'square') {
        errors <- errors ^ 2
      } else if (loss == 'exponential') {
        errors <- 1 - exp(- errors)
      }
  
      avg_loss <- sum(data_weights * errors, na.rm=TRUE)
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

    # early stop if fit of this iteration is perfect
    if (errors_max == 0) break
  }

  
  # newline after printing one or more dots
  cat_verbose(verbose, '\n')

  final_predictor <- list(predictors=predictors,
                          predictors_weights=predictors_weights,
                          num_predictors=length(predictors),
                          input_num_predictors=num_predictors,
                          avg_losses=avg_losses)
  class(final_predictor) <- "trAdaboostR2"

  return (final_predictor)
}

predict.trAdaboostR2 <- function( object, new_data, verbose = FALSE) {
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

  # build a prediction matrix: (row = cases, col = predictors)
  predictions <- vector()
  final_predictions <- vector()

  # TODO: confirm N (in paper) to used
  predictor_start_idx <-
    object$num_predictors - ceiling(object$num_predictors / 2) + 1
  predictor_range <- predictor_start_idx:object$num_predictors
  for(idx in predictor_range)
  {
    predictor <- object$predictors[[idx]]
    prediction <- predict(predictor, new_data)
    predictions <- cbind(predictions, prediction)
  }

  # for each case, get the weighted median as the final prediction
  weighted_median <- trAdaboostR2._weighted_median
  for(i in 1:nrow(new_data))
  {
    final_prediction <-
      weighted_median(predictions[i, ],
                      object$predictors_weights[predictor_range])
    final_predictions <- c(final_predictions, final_prediction)
  }

  return (final_predictions)
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