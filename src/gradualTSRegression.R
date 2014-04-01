gradualTSRegression <- function(x,
                                windowLen = 4, n.ahead = 1,
                                predictor = lm, ...) {
  # Forecast time series via windowing transformation and regression.
  # Note: Missing values will be replaced by interpolation.
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
  
  # Data preprocessing: replace missing values by interpolation
  library(zoo)
  x <- na.approx(x)
  
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
  #source("windowing.R")
  wData <- windowing(x, windowLen)
  wData <- data.frame(wData)
  names(wData)[ncol(wData)] <- "Y"  # The response variable (1 step)
  numCases <- nrow(wData)
  
  # Train a model for each time period
  for(trainEndIndex in 1:(numCases-1)) {
    trainIndex <- 1:trainEndIndex
    testIndex <- trainEndIndex + 1
    testPeriod <- testIndex + windowLen - 1
    
    # Training phase
    model <- tryCatch({
      form <- as.formula("Y~.")
      predictor(form, wData[trainIndex, ], ...)
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
    #source("mape.R")
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

# Usage example on SET ratings data
library(nnet)
setwd("~/Projects/GitHub/ntu-research/data/")
data <- read.csv("Chinese_Drama_Ratings_AnotherFormat.csv")
dramas <- split(data, factor(data[, "Drama"]))
for (idx in 1:length(dramas)) {
  result <- gradualTSRegression(dramas[[idx]][, "Ratings"],
                                predictor = nnet, size= 3, linout=T, trace=F,
                                rang=0.1, decay=1e-1, maxit=100)
}