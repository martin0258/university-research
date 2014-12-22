gradualTSRegression <- function(x,
                                feature = NULL,
                                source_data = NULL,
                                windowLen = 4, n.ahead = 1,
                                verbose = FALSE,
                                model_type = c('regression', 'ts'),
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
  #source("lib/windowing.R")
  wData <- windowing(x, windowLen)
  wData <- data.frame(wData)
  
  # Form time series data
  x_ts <- ts(x)
  
  numCases <- nrow(wData)

#   # Add time period as a feature
#   timePeriods <- seq(windowLen, numCases + windowLen - 1)
#   wData <- cbind(timePeriods, wData)

  # Bind features from input parameter if any
  if (!is.null(feature)) {
    wData <- cbind(tail(feature, numCases), wData)
  }

  # Align column names
  names(wData) <- paste("X", seq(1, ncol(wData)), sep="")
  names(wData)[ncol(wData)] <- "Y"  # The response variable (1 step)
  if (!is.null(source_data)) {
    names(source_data) <- paste("X", seq(1, ncol(source_data)), sep="")
    names(source_data)[ncol(source_data)] <- "Y"
  }

  # Train a model for each time period
  # Start from 2 because at least 2 training instances are needed
  # for doing leave-one-out cross-validation to tune parameters
  for(trainEndIndex in 2:(numCases - 1)) {
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
    cat(sprintf('--- Testing Episode: %2d --- \n', testPeriod))
    
    # settings of parameter tuning
    tune_control <- tune.control(sampling='fix',
                                 error.fun=mape_actual_first)
    
    # Training phase
    model <- tryCatch({
      # Use do.call to easily add new model in test_gradualTSRegression.R
      if (predictor == "trAdaboostR2") {
        do.call(predictor, args=list(formula=model_formula,
                                     source_data=source_data,
                                     target_data=train_data,
                                     val_data=NULL,
                                     verbose=verbose, ...))
      } else if (predictor == "adaboostR2") {
        do.call(predictor, args=list(formula=model_formula,
                                     data=train_data,
                                     val_data=NULL,
                                     verbose=verbose, ...))
      } else if (model_type == 'regression') {
        do.call(predictor, args=list(formula=model_formula,
                                     data=train_data, ...))
#         tune_result <- tune(predictor, model_formula, data=train_data,
#                             ranges=list(maxdepth=seq(1, 4)),
#                             tunecontrol=tune_control, ...)
#         tune_result$best.model
      } else if (model_type == 'ts') {
        # training time series model
        do.call(predictor, args=list(x=train_data_ts, ...))
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
      trainError <- mape(predictTrain, wData[trainIndex, "Y"])
      testError <- mape(predictTest, wData[testIndex, "Y"])
    } else if (model_type == 'ts') {
      predictTrain <- NA
      predictTest <- predict(model, n.ahead = n.ahead)[1]
      trainError <- NA # mape(predictTrain, train_data_ts)
      testError <- mape(predictTest, test_data_ts)
    } else {
      # should not be here in any case
    }
    
    # Evaluate
    #source("lib/mape.R")
    result[testPeriod, "Prediction"] <- predictTest
    result[testPeriod, "TestError"] <- testError
    result[testPeriod, "TrainError"] <- trainError
  }
  
  # Record end execution time
  end <- proc.time()

  time_spent <- end - start
  
  cat(sprintf("Done! Time spent: %.2f (s)", time_spent["elapsed"]), '\n')
  return(result)
}
