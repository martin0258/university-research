dynamicARIMA = function( data, features=NULL ) {
  # Train/predict with an ARIMA model for each period of each series.
  # We use the automated forecasting of ARIMA in the forecast pacakage.
  #
  # Args:
  #   data: a data frame (each column is a time series to be predicted)
  #   feature: a feature list or matrix that will become the value of "xreg" when fitting arima
  #
  # Returns:
  #   A list of three objects.
  #     1. MAPE of forecast for each series.
  #     2. Forecast for each time period of each series.
  #     3. Order information
  library("forecast")
  
  # Hard-coded parameters
  # Predict from the 5th episdoe for each drama
  # The decision depends on number of previous ratings used.
  firstEpisodeToPredict <- 5
  
  # Prepare data structures
  prediction <- data
  prediction[1:(firstEpisodeToPredict - 1),] <- NA
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
    for(episode in firstEpisodeToPredict:nepisode)
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
        # "xreg" parameter in arima() requires a matrix
        thisFeatures <- as.matrix(thisFeatures)

        # Normalize each feature to 0~1
        for (colIdx in 1:ncol(thisFeatures)) {
          featureMin <- min(thisFeatures[, colIdx], na.rm=TRUE)
          featureMax <- max(thisFeatures[, colIdx], na.rm=TRUE)
          if (featureMin != featureMax) {
            thisFeatures[, colIdx] <-
              (thisFeatures[, colIdx] - featureMin) / (featureMax - featureMin)
          } else {
            thisFeatures[, colIdx] <- 1
          }
        }

        trainFeatures <- thisFeatures[-nrow(thisFeatures),]
        testFeatures <- matrix(thisFeatures[nrow(thisFeatures),], nrow=1)
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
        # Add drifting newxreg if needed
        if ("drift"==colnames(arModel$xreg)[1]) {
          testFeatures <- cbind(episode, testFeatures)
        }

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