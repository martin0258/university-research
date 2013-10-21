avgN = function(file, n=5,...){
  # Train/predict with an average model for each period of each series.
  # It simple average ratings of preivous N episodes as the forecast.
  #
  # Args:
  #   file: The name of the ratings file (e.g., Chinese_Weekday_Drama.csv)
  #   n: number of previous N episodes. The default is 5 (an empirical setting).
  #
  # Returns:
  #   A list of two objects.
  #     One is the MAPE of forecast for each series.
  #     Another is the forecast for each time period of each series.
  
  # Read input data
  data = read.csv(file, fileEncoding="utf-8")
  
  # Calculate the results
  nrows = nrow(data)
  ncols = ncol(data)
  prediction = data
  # We cannot predict these entries
  prediction[1:n,] = NA
  for(r in (n+1):nrows)
  {
    for(c in 1:ncols)
    {
      prediction[r,c] = mean(data[(r-n):(r-1),c])
    }
  }
  
  # Compute MAPE
  diff = data - prediction
  absdiff = abs(diff)
  absp = absdiff/data
  mapes = colMeans(absp,na.rm=TRUE)
  
  cat( sprintf("AvgN: %d\n", n) )
  return( list(mape=mapes, forecast=prediction) )
  return(mapes)
}