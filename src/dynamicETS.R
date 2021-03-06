dynamicETS = function( file ) {
  # Train/predict with a Exponential Smoothing State Space Model for each period of each series.
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
  prediction[1,] <- NA  # Not able to predict the 1st period
  prediction[!is.na(prediction)] <- 0
  
  # Error Info
  errInfo <- c()
  
  # Recrod execution time
  start <- proc.time()
  
  for(drama in 1:ncol(data))
  {
    nepisode <- max(which(!is.na(data[drama])))
    # Predict from the 2nd period
    for(episode in 2:nepisode)
    {
      trainingTS <- ts(data[drama][1:(episode-1),1])
      
      # Training phase
      # Error handling for training a HoltWinters model
      esModel <- tryCatch({
        ets( trainingTS )
      }, error = function(err) {
        return(err)
      })
      # Error occurs when training. No prediction.
      if(inherits(esModel,"error"))
      {
        errInfo <- rbind(errInfo, c(drama=colnames(data[drama]),
                                    phase='train',
                                    episode=episode, 
                                    error=paste(esModel)))
        prediction[episode,drama] <- NA
        next
      }
      # Testing phase
      prediction[episode,drama] <- predict( esModel, h=1 )$mean[1]
      
      # Replace missing values with the forecast
      if( is.na( data[ drama ][ episode, 1 ] ) )
      {
        data[ drama ][ episode, 1 ] <- prediction[ episode, drama ]
      }
    }
  }
  
  end <- proc.time()
  
  # Calculate total MAPE
  absp <- abs(prediction-data)/data
  mapes <- colMeans(absp, na.rm=TRUE)
  cat("[Time Spent]\n")
  print( end - start )
  return( list(mape=mapes, forecast=prediction, error=errInfo) )
}