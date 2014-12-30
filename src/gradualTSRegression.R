source('src/lib/windowing.R')
source('src/lib/mape.R')

gradualTSRegression <- function(x,
                                feature = NULL,
                                windowLen = 4, n.ahead = 1, seed = 1,
                                verbose = FALSE,
                                model_type = c('regression', 'ts'),
                                error_fun = mape,
                                predictor, ...) {
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
  model_type <- match.arg(model_type)
  model_formula <- as.formula('Y~.')
  
  # Initialize a data instructure storing input data and result
  result <- data.frame(x)
  rownames(result) <- seq(1, nrow(result))

  # Add new columns for storing result
  result[, "Prediction"] <- NA
  result[, "TestError"] <- NA
  result[, "TrainError"] <- NA
  result[, "ErrorMsg"] <- NA

  # Record start execution time
  start <- proc.time()

  # Form regression data from time series
  wData <- windowing(x, windowLen)
  wData <- data.frame(wData)
  
  # Form time series data
  x_ts <- ts(x)
  
  numCases <- nrow(wData)

  # Bind external regressors from input parameter if any
  if (!is.null(feature)) {
    wData <- cbind(tail(feature, numCases), wData)
  }

  # Align column names
  names(wData) <- paste("X", seq(1, ncol(wData)), sep="")
  names(wData)[ncol(wData)] <- "Y"  # The response variable (1 step)

  # Train a model for each time period
  # Start from 2 because at least 2 training instances are needed
  # for doing leave-one-out cross-validation to tune parameters
  cat('Fitting and predicting')
  for(trainEndIndex in 2:(numCases - 1)) {
    cat('.')
    trainIndex <- 1:trainEndIndex
    testIndex <- trainEndIndex + 1
    train_data <- wData[trainIndex, ]  # train data = subtrain + validation
    val_num_cases <- 1
    val_data <- tail(train_data, val_num_cases)
    subtrain_data <- wData[1:(trainEndIndex - val_num_cases), ]
    test_data <- wData[testIndex, ]
    testPeriod <- testIndex + windowLen - 1
    trainPeriods <- 1:(testPeriod - 1)
    train_data_ts <- x_ts[trainPeriods]
    test_data_ts <- x_ts[testPeriod]
    
    # Training phase
    set.seed(seed)
    model <- tryCatch({
      # Use do.call to easily add new model in test_gradualTSRegression.R
      if (model_type == 'regression') {
        do.call(predictor, list(formula=model_formula, data=train_data, ...))
      } else if (model_type == 'ts') {
        # training time series model
        do.call(predictor, list(train_data_ts, ...))
      } else {
        # should not be here in any case
      }
    }, error = function(err) {
      return(err)
    })

    # Something went wrong during training.
    if(inherits(model, "error"))
    {
      result[testPeriod, "ErrorMsg"] <- paste('Training: ', model)
      # Skip testing phase
      next
    }
    
    # Testing phase
    if (model_type == 'regression') {
      predictTrain <- predict(model, wData[trainIndex, ])
      predictTest <- predict(model, wData[testIndex, ])
    } else if (model_type == 'ts') {
      predictTrain <- NA
      if (predictor %in% c('ets', 'auto.arima', 'nnetar')) {
        # Reference: http://stackoverflow.com/a/22213320
        predictTest <- forecast(model, h = n.ahead)$mean[1]
      } else {
        # add external regressors if any
        if(!is.null(feature)) {
          newxreg <- tail(head(feature, testPeriod), 1)
          predictTest <- predict(model, n.ahead, newxreg)[1]
        } else {
          predictTest <- predict(model, n.ahead)[1]
        }
      }
    } else {
      # should not be here in any case
    }
    
    # Evaluate testing performance
    trainError <- NA # mape(predictTrain, train_data_ts)
    testError <- error_fun(predictTest, test_data_ts)
    result[testPeriod, "Prediction"] <- predictTest
    result[testPeriod, "TestError"] <- testError
    result[testPeriod, "TrainError"] <- trainError
  }
  cat('\n')
  
  end <- proc.time()
  time_spent <- end - start
  cat(sprintf("Done! Time spent: %.2f (s)", time_spent["elapsed"]), '\n')

  return(result)
}
