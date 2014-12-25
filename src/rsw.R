source('src/lib/windowing.R')  # for transform time series to regression

# 'R'egression with Time 'S'eries 'W'eighting (RSW)
rsw <- function (x,
                 window_len = NULL,
                 weighted_sampling = TRUE,
                 seed = 1,
                 repeats = 20,
                 weight_type = c('equal', 'linear', 'exp'),
                 method, ...) {
  # Return a model that trains a regression model
  # with time series weights concepts (newer cases have more weights)
  #
  # Args:
  #   x: A univariate time series or vector.
  #
  # Returns: 
  #   object: An object with class name 'rsw'
  
  # cast x to make sure it is time series
  x <- ts(x)
  
  # automatically choose optimal number of lags via AIC for a linear AR model
  # window length = number of lags + 1 (1 is for the y of one-step forecast)
  if (is.null(window_len)) {
    window_len <- ar(x, aic=TRUE)$order + 1
    window_len <- ifelse(window_len <= 2, 2, window_len)
  }
  
  weight_type <- match.arg(weight_type)
  
  # form regression data from time series data
  r_data <- windowing(x, window_len)
  r_data <- data.frame(r_data)
  num_cases <- nrow(r_data)
  model_formula <- as.formula('Y~.')
  # Align column names with training formula
  names(r_data) <- paste("X", seq(1, ncol(r_data)), sep="")
  names(r_data)[ncol(r_data)] <- "Y"
  
  # Give more weights for newer cases
  # Options: linear increase, exponential increase
  
  if (weight_type == 'equal') {
    # this is known as bagging
    case_weights <- rep(1 / num_cases, num_cases)
  } else if (weight_type == 'linear') {
    case_weights <- seq(1, num_cases)
  } else if (weight_type == 'exp') {
    case_weights <- exp(1:num_cases)
  } else {
    # should not be here
  }
  
  fits <- list()
  if (weighted_sampling) {
    # resampling data based on case weights
    set.seed(seed)
    for (i in 1:repeats) {
      bootstrap_idx <- sample(num_cases, replace=TRUE, prob=case_weights)
      fit <- do.call(method, args=list(formula=model_formula,
                                       data=r_data[bootstrap_idx, ], ...))
      fits[[length(fits) + 1]] <- fit
    }
  } else {
    fit <- do.call(method, args=list(formula=model_formula,
                                     data=r_data, weights=case_weights, ...))
    fits[[1]] <- fit
  }
  
  # construct return object
  obj <- list(x = x, window_len = window_len, r_data = r_data,
              call = match.call(), fits = fits)
  class(obj) <- 'rsw'
  obj[['fitted']] <- fitted(obj)
  
  return (obj)
}

predict.rsw <- function (object, n.ahead = 1)  {
  # form test data
  num_features <- object$window_len - 1
  last_case_x <- tail(object$x, num_features)
  last_case_x <- data.frame(matrix(last_case_x, nrow=1))
  names(last_case_x) <- paste('X', seq(1, num_features), sep='')
  
  predictions <- c()
  for (fit in object$fits) {
    prediction <- predict(fit, newdata=last_case_x)[1]
    predictions <- c(predictions, prediction)
  }
  final_prediction <- mean(predictions)
  predictions <- rep(final_prediction, n.ahead) # flat multiple steps forecast
  names(predictions) <- seq(length(object$x) + 1, length.out = n.ahead)
  return (predictions)
}

fitted.rsw <- function (object) {
  predictions <- c()
  for (fit in object$fits) {
    prediction <- predict(fit, object$r_data)
    predictions <- rbind(predictions, prediction)
  }
  result <- c(rep(NA, object$window_len - 1), colMeans(predictions))
  names(result) <- seq(1, length(result))
  return (result)
}

ensemble_ts <- function (y, ...) {
  input_predictions <- data.frame(list(...))
  y_x <- cbind(y, input_predictions)
  colnames(y_x) <- c('y', paste('p', seq(1, ncol(y_x) - 1), sep=''))
  
  # only keep cases with no missing value at all
  # assumption: all the cases with missing value are centralized first
  y_x_complete <- y_x[complete.cases(y_x), ]
  
  # gradual time series regression
  train_errors <- c()
  predictions <- c()
  num_min_train <- 1
  for (train_idx in 1:(nrow(y_x_complete) - 1)) {
    # prepare training and testing data
    train_data <- y_x_complete[train_idx, ]
    test_data <- y_x_complete[train_idx + 1, ]
    
    # train an ensemble model
#     fit <- rpart(y~., train_data, minsplit=2, maxdepth=2)
#     fit <- lm(y~., train_data)
    
    # test (predict)
#     prediction <- predict(fit, newdata=test_data)
    train_error <- abs(train_data[, 1] - train_data[, -c(1)])
    train_errors <- rbind(train_errors, train_error)
    best_model_idx <- which.min(colSums(train_errors))
    prediction <- test_data[, 1 + best_model_idx]
    predictions <- c(predictions, prediction)
#     cat(sprintf('%d,', best_model_idx))
  }
#   cat('\n')
  predictions <- c(y_x_complete[1, 4], predictions)
  
  # padded starting cases that have missing values with NA
  num_incomplete_cases <- nrow(y_x) - nrow(y_x_complete)
  predictions <- c(rep(NA, num_incomplete_cases), predictions)
  names(predictions) <- seq(1, length(predictions))
  return (predictions)
}
