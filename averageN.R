avgN = function(n=5,file,...){
  # n: can be 1,2,3,... (note that 5 is the best for data)
  
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
  mape = mean(mapes)
  
  # Print MAPE
  print(mapes)
  cat("\nAvgN: ",n)
  cat("\nMAPE:", mape, "\n")
  return(mape)
}