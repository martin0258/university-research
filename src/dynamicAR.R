dynamicAR = function( file, fitMethod = "yule-walker", maxOrder = NULL ) {
  # Train/predict with an AR model for each period of each series.
  #
  # Args:
  #   file: The name of the ratings file (e.g., Chinese_Weekday_Drama.csv)
  #   fitMethod: the fit method used in function ar {stats}
  #
  # Returns:
  #   A list of two objects.
  #     One is the MAPE of forecast for each series.
  #     Another is the forecast for each time period of each series.
  
  # Read input data
  data <- read.csv(file, fileEncoding="utf-8")
  
  # Prepare data structures
  prediction <- data
  prediction[1:2,] <- NA
  prediction[!is.na(prediction)] <- 0
  bestOrder <- prediction
  
  # Error Info
  errInfo <- c()
  
  for(drama in 1:ncol(data))
  {
    nepisode <- max(which(!is.na(data[drama])))
    # Predict from the 3rd episdoe for each drama
    # Because We have no way to predict the 1st, and can only guess the 1st for the 2nd
    for(episode in 3:nepisode)
    {
      tbestOrder <- 0
      trainingTS <- ts(data[drama][1:(episode-1),1])
      
      # Error handling for methods other than yw
      arModel <- tryCatch({
        if(is.null(maxOrder))
        {
          ar(trainingTS, method=fitMethod, na.action=na.exclude)
        }else{
          ar(trainingTS, aic=FALSE, order.max = maxOrder, method=fitMethod, na.action=na.exclude)
        }
      }, error = function(err) {
        return(err)
      })
      # Error occurs. No prediction.
      if(inherits(arModel,"error"))
      {
        errInfo <- rbind(errInfo, c(drama=colnames(data[drama]), episode=episode, error=paste(arModel)))
        bestOrder[episode,drama] <- NA
        prediction[episode,drama] <- NA
        next
      }
      # Use the bestN and minMAPE found to predict this episode
      bestOrder[episode,drama] <- arModel$order
      prediction[episode,drama] <- predict(arModel,trainingTS)$pred[1]
    }
  }
  
  # Calculate total MAPE
  absp <- abs(prediction-data)/data
  mapes <- colMeans(absp, na.rm=TRUE)
  cat( sprintf("Fit method = %s\n", fitMethod) )
  cat( sprintf("Max order = %d\n", maxOrder) )
  return( list(mape=mapes, forecast=prediction, error=errInfo) )
}