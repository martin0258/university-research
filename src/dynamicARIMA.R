dynamicARIMA = function( file, features=NULL ) {
  # Train/predict with an ARIMA model for each period of each series.
  # We use the automated forecasting of ARIMA in the forecast pacakage.
  #
  # Args:
  #   file: The name of the ratings file (e.g., Chinese_Weekday_Drama.csv)
  #   feature: a feature list or matrix that will become the value of "xreg" when fitting arima
  #
  # Returns:
  #   A list of three objects.
  #     1. MAPE of forecast for each series.
  #     2. Forecast for each time period of each series.
  #     3. Order information
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
  
  models <- list()
  orders <- prediction
  
  dramaNames <- names(data)
  for(drama in 1:ncol(data))
  {
    dramaName <- dramaNames[drama]
    nepisode <- max(which(!is.na(data[drama])))
    # Predict from the 3rd episdoe for each drama
    # Because We have no way to predict the 1st, and can only guess the 1st for the 2nd
    for(episode in 3:nepisode)
    {
      tbestOrder <- 0
      trainEpisodes <- 1:(episode-1)
      trainTS <- ts(data[drama][trainEpisodes,1])
      
      if(is.null(features))
      {
        trainFeatures <- NULL
        testFeatures <- NULL
      }else{
        thisFeatures <- subset(features, Drama == dramaName & Episode <= episode)[,c(-1, -2)]
        trainFeatures <- thisFeatures[-nrow(thisFeatures),]
        testFeatures <- thisFeatures[nrow(thisFeatures),]
      }
      
      # Error handling for methods other than yw
      arModel <- tryCatch({
        auto.arima(trainTS, xreg = trainFeatures)
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
        predict(arModel, n.ahead=1, newxreg=testFeatures)$pred[1]
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
        orders[episode,drama] <- NA
      }else
      {
        prediction[episode,drama] <- pred
        orders[episode,drama] <- paste(arModel$arma, collapse='')
      }
    }
  }
  
  # Calculate total MAPE
  absp <- abs(prediction-data)/data
  mapes <- colMeans(absp, na.rm=TRUE)
  return( list(mape=mapes, forecast=prediction, error=errInfo, orders=orders) )
}