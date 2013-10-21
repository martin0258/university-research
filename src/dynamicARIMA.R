dynamicARIMA = function( file ) {
  # Train/predict with an ARIMA model for each period of each series.
  # We use the automated forecasting of ARIMA in the forecast pacakage.
  #
  # Args:
  #   file: The name of the ratings file (e.g., Chinese_Weekday_Drama.csv)
  #
  # Returns:
  #   A list of two objects.
  #     One is the MAPE of forecast for each series.
  #     Another is the forecast for each time period of each series.
  library("forecast")
  
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
        auto.arima(trainingTS)
      }, error = function(err) {
        return(err)
      })
      # Error occurs when training. No prediction.
      if(inherits(arModel,"error"))
      {
        errInfo <- rbind(errInfo, c(drama=colnames(data[drama]), episode=episode, error=paste(arModel)))
        bestOrder[episode,drama] <- NA
        prediction[episode,drama] <- NA
        next
      }
      # Error handling for predict.ARIMA
      pred <- tryCatch({
        predict(arModel, n.ahead=1)$pred[1]
      }, error = function(err) {
        return(err)
      })
      # Error occurs when testing. No prediction.
      if(inherits(pred, "error"))
      {
        errInfo <- rbind(errInfo, c(drama=colnames(data[drama]), 
                                    episode=episode,
                                    error=paste(pred)))
        prediction[episode,drama] <- NA
      }else
      {
        prediction[episode,drama] <- pred
      }
    }
  }
  
  # Calculate total MAPE
  absp <- abs(prediction-data)/data
  mapes <- colMeans(absp, na.rm=TRUE)
  return( list(mape=mapes, forecast=prediction, error=errInfo) )
}