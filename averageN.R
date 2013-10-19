avgN = function(file, n=5,...){
  # n: can be any positive integer (e.g, 1, 2, 3, etc). The default value 5 is an empirical good number
  
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
  return(mapes)
}