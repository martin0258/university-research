source('src/lib/windowing.R')  # for transforming time series to regression
source('src/lib/mape.R')       # for calculating val error

# 'R'egression with Time 'S'eries 'W'eighting (RSW)
rsw <- function (x = NULL, xreg = NULL,
                 formula = NULL, data = NULL,
                 window_len = NULL,
                 weighted_sampling = TRUE,
                 repeats = 20,
                 weight_type = c('equal', 'linear', 'exp', 'exp3', 'auto'),
                 prune = TRUE,
                 error_fun = mape,
                 method, ...) {
  # Return a model that trains a regression model
  # with time series weights concepts (newer cases have more weights)
  #
  # Args:
  #   x: A univariate time series or vector.
  #
  # Returns: 
  #   object: An object with class name 'rsw'
  
  weight_type <- match.arg(weight_type)
  
  if (!is.null(formula) && !is.null(data)) {
    r_data <- data
    model_formula <- formula
    num_cases <- nrow(r_data)
  } else if (!is.null(x)) {
    # form regression data from time series data
    # cast x to make sure it is time series
    x <- ts(x)
    
    model_formula <- as.formula('Y~.')
    
    # automatically choose optimal number of lags via AIC for a linear AR model
    # window length = number of lags + 1 (1 is for the y of one-step forecast)
    if (is.null(window_len)) {
      window_len <- ar(x, aic=TRUE)$order + 1
      window_len <- ifelse(window_len <= 2, 2, window_len)
    }
  
    r_data <- windowing(x, window_len)
    r_data <- data.frame(r_data)
    num_cases <- nrow(r_data)
    
    # Align column names with training formula
    names(r_data) <- paste("X", seq(1, ncol(r_data)), sep="")
    names(r_data)[ncol(r_data)] <- "Y"
    
    # bind external regressors if any
    if (!is.null(xreg)) {
      xreg <- data.frame(xreg)
      stopifnot(length(x) != nrow(xreg))
      r_data <- cbind(tail(xreg, num_cases), r_data)
    }
  } else {
    stop('Either x or (formula, data) must not be null.')
  }
  
  # Give more weights for newer cases
  # Options: linear increase, exponential increase
  
  if (weight_type == 'equal') {
    # this is known as bagging
    case_weights <- rep(1 / num_cases, num_cases)
  } else if (weight_type == 'linear') {
    case_weights <- seq(1, num_cases)
  } else if (weight_type == 'exp') {
    case_weights <- exp(1:num_cases)
  } else if (weight_type == 'exp3') {
    alpha <- 3
    case_weights <- (exp(1)^alpha)^(1:num_cases)
  } else {
    # decide weight type automatically based on validation error
    num_val_cases <- 1
    val_data <- tail(r_data, num_val_cases)
    subtrain_data <- head(r_data, num_cases - num_val_cases)
    
    fits_type <- list()
    val_errors <- c()
    weight_types <- c('equal', 'linear', 'exp', 'exp3')
    for (type in weight_types) {
      fit <- rsw(formula=model_formula, data=subtrain_data,
                 weight_type=type,
                 method=method, ...)
      fits_type[[length(fits_type) + 1]] <- fit
      prediction <- predict(fit, new_data=val_data)
      val_error <- error_fun(prediction, val_data[, 'Y'])
      val_errors <- c(val_errors, val_error)
    }
    fit <- rsw(x=x,
               weight_type=weight_types[which.min(val_errors)],
               method=method, ...)
    return (fit)
  }
  
  fits <- list()
  if (weighted_sampling) {
    # resampling data based on case weights
    for (i in 1:repeats) {
      bootstrap_idx <- sample(num_cases, replace=TRUE, prob=case_weights)
      # fit a model
      fit <- do.call(method, list(formula=model_formula,
                                  data=r_data[bootstrap_idx, ], ...))
      fits[[length(fits) + 1]] <- fit
    }
  } else {
    # fit a model
    fit <- do.call(method, list(formula=model_formula,
                                data=r_data, weights=case_weights, ...))
    fits[[1]] <- fit
  }
  
  # prune tree (http://www.statmethods.net/advstats/cart.html)
  if (method == 'rpart' && prune == TRUE) {
    for (i in 1:length(fits)) {
      fit <- fits[[i]]
      min_val_cp <- fit$cptable[which.min(fit$cptable[, 'xerror']), 'CP']
      fit <- prune(fit, min_val_cp)
      fits[[i]] <- fit
    }
  }
  
  # construct return object
  obj <- list(x = x, window_len = window_len, r_data = r_data,
              call = match.call(), fits = fits)
  class(obj) <- 'rsw'
  obj[['fitted']] <- fitted(obj)
  
  return (obj)
}

predict.rsw <- function (object, n.ahead = 1, newxreg = NULL,
                         new_data = NULL)  {
  if (is.null(object$window_len)) {
    stopifnot(!is.null(new_data))
    test_data <- new_data
    
    predictions <- vector()
    for (fit in object$fits) {
      prediction <- as.numeric(predict(fit, test_data))
      predictions <- rbind(predictions, prediction)
    }
    final_predictions <- colMeans(predictions)
  } else {
    num_features <- object$window_len - 1
    last_case_x <- tail(object$x, num_features)
    last_case_x <- data.frame(matrix(last_case_x, nrow=1))
    names(last_case_x) <- paste('X', seq(1, num_features), sep='')
    if (!is.null(newxreg)) {
      last_case_x <- cbind(newxreg, last_case_x)
    }
    test_data <- last_case_x
    
    predictions <- c()
    for (fit in object$fits) {
      prediction <- predict(fit, test_data)
      predictions <- c(predictions, prediction)
    }
    avg_predictions <- mean(predictions)
    # flat multi-steps forecast
    final_predictions <- rep(avg_predictions, n.ahead)
    names(final_predictions) <- seq(length(object$x) + 1, length.out = n.ahead)
  }
  
  return (final_predictions)
}

# Note: When using weight type of linear or exp, the training model
# focuses on newer training cases to have accurate ahead prediction,
# so it should have much bigger training errors on older training cases.
fitted.rsw <- function (object) {
  predictions <- c()
  for (fit in object$fits) {
    prediction <- predict(fit, object$r_data)
    predictions <- rbind(predictions, prediction)
  }
  if (!is.null(object$window_len)) {
    result <- c(rep(NA, object$window_len - 1), colMeans(predictions))
    names(result) <- seq(1, length(result))
  } else {
    result <- colMeans(predictions)
  }
  return (result)
}

example_rsw <- function () {
  # Regression Tree
  library(rpart)
  
  # Example: time series data
  fit <- rsw(lh, method='rpart')
  plot(lh, type='o', main=paste('Example:', deparse(fit$call)))
  lines(fitted(fit), type='o', col='blue')
  
  # Example: regression data
  fit2 <- rsw(formula=Price ~ ., data=cu.summary, method='rpart')
  plot(cu.summary$Price, main=paste('Example:', deparse(fit2$call)))
  points(predict(fit2, new_data=cu.summary), col='blue')
}
