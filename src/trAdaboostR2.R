library(nnet)
library(Defaults)

trAdaboostR2 <- function( formula, source_data, target_data,
                          num_predictors = 50,
                          learning_rate = 1,
                          loss = 'linear',
                          weighted_sampling = TRUE,
                          verbose = FALSE,
                          base_predictor = nnet, ...
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
  #     - predictor_weights: weight of each predictor
  #     - num_predictors: number of predictors
  #     - avg_losses: average loss of each predictor
  #
  # References:
  #   - David Pardoe and Peter Stone.
  #     Boosting for Regression Transfer.
  #     ICML 2010.
  #
  #   - Dai,Wenyuan, Yang, Qiang, Xue, Gui-rong, and Yu, Yong.
  #     Boosting for transfer learning.
  #     ICML 2007.

  # Cast formula.
  form <- as.formula(formula, env=environment())

  # Adjust option of printing message.
  if (!verbose) {
    if (.Platform$OS.type == "windows") {
      setDefaults(cat, file='nul')
    } else {
      # this only works for linux
      # for windows we need to use NUL or nul
      setDefaults(cat, file='/dev/null')
    }
  } else {
    setDefaults(cat, file='')
  }

  # initialize return values
  predictors <- list()
  predictor_weights <- list()
  avg_losses <- list()

  # combine source and target data to a single dataset
  data <- rbind(source_data, target_data)
  data <- data.frame(data)
  num_cases <- nrow(data)
  num_src_cases <- nrow(source_data)
  source_idx <- 1:num_src_cases
  target_idx <- (num_src_cases + 1):num_cases

  # set initial data weights
  data_weights <- rep(1 / num_cases, num_cases)

  max_num_itrs <- num_predictors
  for (i in 1:max_num_itrs)
  {
    # train a weak hypothesis of base predictor
    if (weighted_sampling) {
      # instead of training with data_weights,
      # we can do weighted sampling of the training set with replacement,
      # and fit on the bootstrapped sample and obtain a prediction.
      bootstrap_idx <- sample(num_cases, replace=TRUE, prob=data_weights)
      predictor <- base_predictor(form, data[bootstrap_idx, ], ...)
    } else {
      predictor <- base_predictor(form, data, weights=data_weights, ...)
    }

    prediction <- predict(predictor, data)
    # get dependent variable name from formula
    # what if there are multiple responses?
    response <- all.vars(form[[2]])
    errors <- abs(prediction - data[response])
    errors_max <- max(errors, na.rm=TRUE)
    if (errors_max == 0) {
      # early termination:
      #   if the fit is perfect, store the predictor info and stop
      predictors[[i]] <- predictor
      predictor_weights[[i]] <- 1
      msg <- "Early terminaion because fit at iteration %d is perfect."
      cat('\n', sprintf(msg, i))
      break
    }
    errors <- errors / errors_max

    if (loss == 'square') {
      errors <- errors ^ 2
    } else if (loss == 'exponential') {
      errors <- 1 - exp(- errors)
    }

    avg_loss <- sum(data_weights * errors, na.rm=TRUE)
    avg_losses[[i]] <- avg_loss

    if (avg_loss >= 0.5) {
      # early termination:
      #   stop if the fit is too "terrible"
      #   TODO: fix the case of similar small errors
      msg <- "Early termination at iteration %d because avg loss >= 0.5"
      cat('\n', sprintf(msg, i))
      break
    } else {
      beta_confidence <- avg_loss / (1 - avg_loss)
      # TODO: confirm N (in paper) to used during early termination.
      beta <- 1 / (1 + sqrt(2 * log(num_src_cases / max_num_itrs)))

      ## update weights of source instances
      data_weights[source_idx] <-
        data_weights[source_idx] *
        beta ^ (errors[source_idx,] * learning_rate)

      ## update weights of target instances
      data_weights[target_idx] <-
        data_weights[target_idx] *
        beta_confidence ^ (-errors[target_idx,] * learning_rate)

      # normalize
      data_weights <- data_weights / sum(data_weights)

      # store the predictor info
      predictors[[i]] <- predictor
      predictor_weights[[i]] <- learning_rate * log(1 / beta_confidence)
    }
  }

  final_predictor <- list(predictors=predictors,
                          predictor_weights=predictor_weights,
                          num_predictors=length(predictors),
                          input_num_predictors=num_predictors,
                          avg_losses=avg_losses)
  class(final_predictor) <- "trAdaboostR2"

  # restore option to default value
  if (!verbose) {
    setDefaults(cat, file='')
  }

  return (final_predictor)
}

predict.trAdaboostR2 <- function( object, new_data,
                                  verbose = TRUE ) {
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
  if (!verbose) {
    if (.Platform$OS.type == "windows") {
      setDefaults(cat, file='nul')
    } else {
      # this only works for linux
      # for windows we need to use NUL or nul
      setDefaults(cat, file='/dev/null')
    }
  } else {
    setDefaults(cat, file='')
  }

  if (object$num_predictors == 0) {
    cat('\n', 'No prediction because there is no base predictor.', '\n')
    return (rep(as.numeric(NA), nrow(new_data)))
  }
  # the newline is for beautifying testthat output
  cat('\n')

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
                      object$predictor_weights[predictor_range])
    final_predictions <- c(final_predictions, final_prediction)
  }

  # restore option to default value
  if (!verbose) {
    setDefaults(cat, file='')
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
  library(cwhmisc)

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
