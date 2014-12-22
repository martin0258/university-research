avgPastPeriods <- function (x, na.rm = TRUE) {
  # Return a time series model that guesses avg(values of past episodes).
  #
  # Args:
  #   x: A univariate time series or vector.
  #
  # Returns: 
  #   object: An object with class name 'lastPeriod'
  
  # cast x to make sure it is time series
  x <- ts(x)
  
  # capture args
  args <- match.call()
  
  # fitted values
  x_len <- length(x)
  fitted_values <- rep(NA, x_len)
  if (x_len >= 2) {
    for (t in 2:x_len) {
      past_periods <- seq(1, t - 1)
      fitted_values[t] <- mean(x[past_periods], na.rm = na.rm)
    }
  }
  
  # construct return object
  obj <- list(x = x, args = args, fitted_values = fitted_values)
  class(obj) <- 'avgPastPeriods'
  
  return (obj)
}

predict.avgPastPeriods <- function (object, n.ahead = 1, na.rm = TRUE) {
  avg_past_periods <- mean(object$x, na.rm = na.rm)
  predictions <- rep(avg_past_periods, n.ahead)
  return (predictions)
}