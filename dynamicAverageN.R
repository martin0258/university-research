dynamicAvgN = function(file,ratio=0.5){
  # Summary: This script calculates the best N for each episode of each drama
  # file: The ratings file (e.g., Chinese_Weekday_Drama.csv)
  # ratio: Control the the largest N (ratio*episode) to search. 
  
  # Read input data
  data <- read.csv(file, fileEncoding="utf-8")
  
  # Prepare data structures
  prediction <- data
  prediction[1,] <- NA
  prediction[!is.na(prediction)] <- 0
  prediction[2:3,] <- data[1:2,]
  bestN <- prediction
  bestN[2:3,] <- NA
  minMAPE <- prediction
  minMAPE[2:3,] <- NA
  
  # Start running the algorithm
  for(drama in 1:ncol(data))
  {
    nepisode <- max(which(!is.na(data[drama])))
    # Predict from the 3rd episdoe for each drama
    # Because We have no way to predict the 1st, 
    # And can only guess the previous for 2nd & 3rd episode
    for(episode in 4:nepisode)
    {
      tminMAPE <- 1
      tbestN <- 0
      for(n in 1:(episode*ratio))
      {
        # Predict 1~(episode-1) with average N
        ratings <- data[drama][1:(episode-1),1]
        tprediction <- ratings
        tprediction[1:n] <- NA
        for(i in (n+1):length(ratings))
        {
          tprediction[i] <- mean(ratings[(i-n):(i-1)], na.rm=TRUE)
        }
        # Avoid invalid prediction for too large ratios (e.g., 0.8)
        if(length(tprediction)!=length(ratings)){break}
        # Calculate MAPE
        mape <- mean(abs(tprediction-ratings)/ratings, na.rm=TRUE)
        # Compare with the current best
        if(mape < tminMAPE)
        {
          tminMAPE <- mape
          tbestN <- n
        }
      }
      # Use the bestN and minMAPE found to predict this episode
      bestN[episode,drama] <- tbestN
      minMAPE[episode,drama] <- tminMAPE
      prediction[episode,drama] <- mean(data[(episode-tbestN):(episode-1),drama], na.rm=TRUE)
    }
  }
  
  # Calculate total MAPE
  absp <- abs(prediction-data)/data
  mapes <- colMeans(absp, na.rm=TRUE)
  totalMAPE <- mean(mapes)
  print(mapes)
  cat("\ntotalMAPE: ", totalMAPE, "\n")
  return(totalMAPE)
}