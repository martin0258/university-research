gradualTSRegression <- function(x,
                                source_data = NULL,
                                windowLen = 4, n.ahead = 1,
                                predictor = lm, ...) {
  # Forecast time series via windowing transformation and regression.
  #
  # Arguments:
  #   x: A numeric vector or time series.
  #   windowLen: The length of windowing transformation (must be an integer >= 2).
  #   n.ahead: The number of steps ahead to predict (only 1 step is implemented).
  #   predictor: The function from which the model is built.
  #   ...: The arguments passed to the predictor function.
  #
  # Returns:
  #   A data frame with the following information (each row represents a perid):
  #     - Input data (x)
  #     - Prediction
  #     - Training error (MAPE)
  #     - Testing error (MAPE)
  #     - Error message if any
  #
  # Internal Dependency (please source them):
  #   - windowing.R
  #   - mape.R
  #
  # Example:
  #  If (windowLen = 4, n.ahead = 1), each training instance has 3 predictors
  #  and 1 response variable.
  
  # Initialize a data instructure storing input data and result
  result <- data.frame(x)

  # Add new columns for storing result
  result[, "Prediction"] <- NA
  result[, "TestError"] <- NA
  result[, "TrainError"] <- NA
  result[, "ErrorMsg"] <- NA

  # Recrod start execution time
  start <- proc.time()

  # Form regression data from time series
  #source("lib/windowing.R")
  wData <- windowing(x, windowLen)
  wData <- data.frame(wData)
  
  # Add time period as a feature
  numCases <- nrow(wData)
  timePeriods <- seq(windowLen, numCases + windowLen - 1)
  wData <- cbind(timePeriods, wData)

  # Align column names
  names(wData) <- paste("X", seq(1, ncol(wData)), sep="")
  names(wData)[ncol(wData)] <- "Y"  # The response variable (1 step)
  if (!is.null(source_data)) {
    names(source_data) <- paste("X", seq(1, ncol(source_data)), sep="")
    names(source_data)[ncol(source_data)] <- "Y"
  }

  # Train a model for each time period
  for(trainEndIndex in 1:(numCases-2)) {
    trainIndex <- 1:trainEndIndex
    valIndex <- trainEndIndex + 1
    testIndex <- trainEndIndex + 2
    testPeriod <- testIndex + windowLen - 1
    
    # Training phase
    model <- tryCatch({
      form <- as.formula("Y~.")
      predictor_name <- as.character(substitute(predictor))
      if (predictor_name == "trAdaboostR2") {
        predictor(form,
                  source_data=source_data,
                  target_data=wData[trainIndex, ],
                  val_data=wData[valIndex, ], ...)
      } else {
        predictor(form, wData[trainIndex, ], ...)
      }
    }, error = function(err) {
      return(err)
    })

    # Something went wrong during training.
    if(inherits(model, "error"))
    {
      result[testPeriod, "ErrorMsg"] <- c(phase='train',
                                        period=testPeriod,
                                        errMsg=paste(model))
      # Skip testing phase
      next
    }
    
    # Testing phase
    predictTrain <- predict(model, wData[trainIndex, ])
    predictTest <- predict(model, wData[testIndex, ])
    
    # Evaluate
    #source("lib/mape.R")
    trainError <- mape(predictTrain, wData[trainIndex, "Y"])
    testError <- mape(predictTest, wData[testIndex, "Y"])
    result[testPeriod, "Prediction"] <- predictTest
    result[testPeriod, "TestError"] <- testError
    result[testPeriod, "TrainError"] <- trainError
  }
  
  # Recrod end execution time
  end <- proc.time()
  
  cat("[Time Spent]\n")
  print(end - start)
  return(result)
}
