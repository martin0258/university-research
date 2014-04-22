windowing <- function(x, windowLen) {
  # Summary: Transform a time series data into a set of cases.
  # Reference: Autoregressive Tree Models for Time-Series Analysis (C. Meek, 2002)
  #
  # Arguments:
  #   x: A numeric vector or time series.
  #   windowLen: The length of windowing transformation (must be an integer >= 2).
  #
  # Returns:
  #   A list of cases in matrix format
  
  # Check precondition
  if (!(windowLen >= 2)) {
    stop("The value of windowLen must be an integer >= 2.")
  }
  
  tsData <- ts(x)
  cases <- c()
  
  numCases <- length(tsData) - windowLen + 1
  for(i in 1:numCases)
  {
    cases <- rbind(cases, window(tsData, i, i + windowLen - 1)[1:windowLen])
  }

  return(cases)
}