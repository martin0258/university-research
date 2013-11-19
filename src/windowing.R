windowing = function( data, windowLen ) {
  # Summary: transform a time-series data into a set of cases for regression analysis
  # Reference: Autoregressive Tree Models for Time-Series Analysis (C. Meek, 2002)
  
  # Parameter
  #   data      : the time series data
  #   windowLen : an integer >= 2
  # Return
  #   A list of cases
  
  tsData <- ts(data)
  cases <- vector()
  
  numCases <- length(tsData) - windowLen + 1
  for(i in 1:numCases)
  {
    cases <- rbind(cases, window(tsData, i, i + windowLen - 1)[1:windowLen])
  }

  return(cases)
}