guessLastPeriod <- function (x) {
  # Return a time series model that simply guesses last episode.
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
  fitted_values <- c(NA, head(x, length(x) - 1))
  
  # construct return object
  obj <- list(x = x, args = args, fitted_values = fitted_values)
  class(obj) <- 'guessLastPeriod'
  
  return (obj)
}

predict.guessLastPeriod <- function (object, n.ahead = 1) {
  last_period_value <- tail(object$x, 1)
  predictions <- rep(last_period_value, n.ahead)
  return (predictions)
}