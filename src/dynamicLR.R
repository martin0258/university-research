dynamicLR = function( file, windowLen = 4 ) {
  # Train/predict with a linear regression model for each period of each series.
  #
  # Args:
  #   file: The name of the ratings file (e.g., Chinese_Weekday_Drama.csv)
  #
  # Returns:
  #   A list of two objects.
  #     One is the MAPE of forecast for each series.
  #     Another is the forecast for each time period of each series.
  
  # Read input data
  data <- read.csv(file, fileEncoding="utf-8")
  
  # Prepare data structures
  prediction <- data
  prediction[,] <- NA
  
  # Error Info
  errInfo <- c()
  
  # Recrod execution time
  start <- proc.time()
  
  for(drama in 1:ncol(data))
  {
    # form data
    wData <- data.frame(windowing(data[, drama], windowLen))
    colnames(wData)[ncol(wData)] <- "Y"

    numCases <- nrow(wData)
    for(trainEndIndex in 1:(numCases-1))
    {
      testIndex <- trainEndIndex + 1
      testEpisode <- testIndex + windowLen - 1

      # Training phase (with error handling)
      model <- tryCatch({
        lm( Y ~ ., data = wData, subset = 1:trainEndIndex)
      }, error = function(err) {
        return(err)
      })
      # Error occurs when training. No prediction.
      if(inherits(model,"error"))
      {
        errInfo <- rbind(errInfo, c(drama=colnames(data[drama]),
                                    phase='train',
                                    episode=testEpisode, 
                                    error=paste(model)))
        prediction[testEpisode, drama] <- NA
        next
      }
      # Testing phase
      prediction[testEpisode, drama] <- predict(model, wData[testIndex,1:windowLen])
      
      # Replace missing values with the forecast
      if( is.na( data[ drama ][ testEpisode, 1 ] ) )
      {
        data[ drama ][ testEpisode, 1 ] <- prediction[ testEpisode, drama ]
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