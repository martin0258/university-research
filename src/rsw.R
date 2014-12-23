source('src/lib/windowing.R')  # for transform time series to regression

# 'R'egression with Time 'S'eries 'W'eighting (RSW)
rsw <- function (x,
                 window_len,
                 weighted_sampling = TRUE,
                 seed = 1,
                 repeats = 20,
                 weight_type = c('flat', 'linear', 'exp'),
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
  
  if (weight_type == 'flat') {
    case_weights <- rep(1 / num_cases, num_cases)
  } else if (weight_type == 'linear') {
    alpha <- 1
    case_weights <- alpha * seq(1, num_cases)
  } else if (weight_type == 'exp') {
    alpha <- 1
    case_weights <- alpha * exp(1:num_cases)
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
    fitted <- sapply(fits, 'fitted')
  } else {
    fit <- do.call(method, args=list(formula=model_formula,
                                     data=r_data, weights=case_weights, ...))
    fits[[length(models) + 1]] <- fit
    fitted <- fitted(fit)
  }
  
  # construct return object
  obj <- list(x = x, window_len = window_len, 
              call = match.call(), fits = fits, fitted = fitted)
  class(obj) <- 'rsw'
  
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