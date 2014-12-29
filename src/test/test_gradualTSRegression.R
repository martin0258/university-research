# This script is a test of SET TVR data
# It tests various models and features in terms of prediction accuracy

# ---------- Region: Parameters of script (use defaults if not exists)
{
## Parameters that control position for reading data and including libraries
project_root <- ifelse(exists('project_root'), project_root,
                       'D:/Projects/GitHub/ntu-research/')

## Parameters that control data set (either Idol or Chinese)
test_dataset <- ifelse(exists('test_dataset'), test_dataset, 'Idol')

## Parameters that control features 
feature_files <- c(
#   sprintf('data/%s_Drama_Opinion.csv', test_dataset),
#   sprintf('data/%s_Drama_GoogleTrend.csv', test_dataset),
#   sprintf('data/%s_Drama_FB.csv', test_dataset),
#   sprintf('data/%s_Drama_WeekDay.csv', test_dataset)
) 

## Parameters that control control models
seed <- ifelse(exists('seed'), seed, 0)
window_len <- ifelse(exists('window_len'), window_len, 4)
r_control <- list(minsplit=2, maxdepth=30)
r_control_ensemble <- list(minsplit=2, maxdepth=30)
models <- 
  list(
      list(name='lastPeriod',
           args=list(model_type='ts', predictor='guessLastPeriod')
          ),
      list(name='avgPastPeriods',
           args=list(model_type='ts', predictor='avgPastPeriods')
          ),
      list(name='SExpSmoothing',
           args=list(model_type='ts',
                     predictor='HoltWinters', beta=F, gamma=F)
          ),
      list(name='DExpSmoothing',
           args=list(model_type='ts', predictor='HoltWinters', gamma=F)
          ),
      list(name='ESStateSpace',
           args=list(model_type='ts', predictor='ets')
          ),
      list(name='auto.arima',
           args=list(model_type='ts', predictor='auto.arima')
          ),
      list(name='nnetar',
           args=list(model_type='ts', predictor='nnetar')
          ),
      list(name='rsw.rpart.equal.ns',
           args=list(model_type='ts',
                     predictor='rsw', weight_type='equal',
                     weighted_sampling=FALSE,
                     method='rpart', control=r_control)
          ),
      list(name='rsw.rpart.equal',
           args=list(model_type='ts',
                     predictor='rsw', weight_type='equal',
                     method='rpart', control=r_control)
          ),
      list(name='rsw.rpart.linear',
           args=list(model_type='ts',
                     predictor='rsw', weight_type='linear',
                     method='rpart', control=r_control)
          ),
      list(name='rsw.rpart.exp',
           args=list(model_type='ts',
                     predictor='rsw', weight_type='exp',
                     method='rpart', control=r_control)
          )
      )
ensemble <- list(predictor='rsw',
                 input_models=c('auto.arima'),
                 args=list(weight_type='exp',
                 method='rpart', control=r_control_ensemble))
}

# ---------- Region: Include libraries and source codes
{
if (!require(forecast)) install.packages('forecast')
library(forecast)  # for auto.arima() and ets()
library(rpart)
setwd(project_root)
source("src/getFeature.R")
source("src/gradualTSRegression.R")
source("src/guessLastPeriod.R")
source("src/avgPastPeriods.R")
source("src/rsw.R")
source("src/lib/mape.R")
source("src/lib/mae.R")
}

# Record script start time for calculating time spent
start_time <- proc.time()

# ---------- Region: Read and process input before fitting models
{
# Read ratings
ratings_file <- sprintf('data/%s_Drama_Ratings_AnotherFormat.csv', test_dataset)
ratings <- read.csv(ratings_file, fileEncoding='utf-8')
# Final output (ratings & features)
data <- ratings

# Read features, and then combine them with ratings into a single data set
for (feature_file in feature_files) {
  feature <- read.csv(feature_file, fileEncoding='utf-8')
  # left join automatically by common variables
  data <- merge(data, feature, sort=FALSE, all.x=TRUE)
}

# Sort (for easily viewing data while debugging)
attach(data)
data <- data[order(Drama, Episode),]
detach(data)

# Group data by each drama
dramas <- split(data, factor(data[, 'Drama']))

# For simplicity, skip dramas that have any missing values
# Ref: http://stackoverflow.com/a/12615019
dramas_indices_with_no_na <- vector(mode='numeric', length=0)
for (idx in 1:length(dramas)) {
  ratings <- dramas[[idx]][3]
  if (any(is.na(ratings))) {
    dramas_indices_with_no_na <- c(dramas_indices_with_no_na, idx)
  }
}
if (length(dramas_indices_with_no_na) > 0) {
  dramas <- dramas[-dramas_indices_with_no_na]
}

# Skip drama whose data is not enough (e.g., "Second Life")
# If it is not skipped, gradualTSRegression() will fail.
dramas_indices_to_skip <- vector(mode='numeric', length=0)
for (idx in 1:length(dramas)) {
  if (nrow(dramas[[idx]]) < 6) {
    dramas_indices_to_skip <- c(dramas_indices_to_skip, idx)
  }
}
if (length(dramas_indices_to_skip) > 0) {
  dramas <- dramas[-dramas_indices_to_skip]
}

# Hotfix: remove episodes that have missing values in features
for (idx in 1:length(dramas)) {
  dramas[[idx]] <- dramas[[idx]][complete.cases(dramas[[idx]]), ]
}
}

# ---------- Region: Initialize variables used in fitting and testing models
{
num_dramas <- length(dramas)
num_models <- length(models)
# Reference of the next line: http://stackoverflow.com/a/2803542
models_names <- sapply(models, '[[', 1)
models_names_idx <- paste(seq(1, num_models), models_names, sep='.')

# results is a list of data frames returned from gradualTSRegression().
#   Each data frame represents the results of a drama.
#   Each row has the following column for each episode: 
#     1. ratings
#     2. test prediction
#     3. train prediction
#     4. test error
#     4. train error
#     5. error message
results <- list()

# each column is the metric results of each drama
mape_dramas <- matrix(, nrow=num_models, ncol=0)
mae_dramas <- matrix(, nrow=num_models, ncol=0)
rownames(mape_dramas) <- models_names_idx
rownames(mae_dramas) <- models_names_idx
}

# ---------- Region: Fit models and test them
for (drama_idx in 1:num_dramas) {
  drama <- dramas[[drama_idx]]
  dramaName <- names(dramas)[drama_idx]
  colnames(drama)[3] <- dramaName
  
  features <- drama[-c(1, 2, 3)]
  ratings <- drama[3]

  # Run experiment for each model
  for (model_idx in 1:num_models) {
    model <- models[[model_idx]]
    cat('--------------------', '\n')
    cat('Starting experiment...', '\n')
    cat(sprintf('Drama %d: %s, Model %d: %s',
                drama_idx, dramaName, model_idx, model$name), '\n')
    
    # Add external feature if specified
    xreg <- NULL
    if ('xreg' %in% names(model$args)) {
      model$args$xreg <- features
      xreg <- features
    }
    
    result <- do.call(gradualTSRegression,
                      args=c(list(x=ratings, feature=xreg), model$args))
    results[[length(results) + 1]] <- result
  }

  # After running all experiments, calculate MAPE & MAE
  mape_drama <- c()
  mae_drama <- c()
  for (result in tail(results, num_models)) {
    mape_drama <- c(mape_drama, mape(result['Prediction'], ratings))
    mae_drama <- c(mae_drama, mae(result['Prediction'], ratings))
  }
  mape_dramas <- cbind(mape_dramas, mape_drama)
  mae_dramas <- cbind(mae_dramas, mae_drama)
  # Note: display first 2 characters of drama name to make table more readable
  colnames(mape_dramas)[ncol(mape_dramas)] <- substr(dramaName, 1, 2)
  colnames(mae_dramas)[ncol(mae_dramas)] <- substr(dramaName, 1, 2)

  # Plot result
  color_idx <- 0
  colors <- rainbow(num_models) 
  for (result in tail(results, num_models)) {
    color_idx <- color_idx + 1
    color <- colors[color_idx]
    if (color_idx == 1) {
      # Note: Draw bigger values first to make plot more readable
      # In most cases, testing errors are bigger than training errors
      plot(ts(result['TestError']), col=color, xlab='', ylab='', type='o')
      title(main=dramaName, xlab='Episode', ylab='MAPE')
      lines(ts(result['TrainError']), col=color, lty=2)
    } else {
      lines(ts(result['TestError']), col=color, type='o')
      lines(ts(result['TrainError']), col=color, lty=2)
    }
  }
  legend('topleft', legend=paste(models_names, ': ', mape_drama, sep=''),
         pch=21, lty=1, col=colors, cex=0.7)
  legend('bottomleft', legend=c('training', 'testing'),
         pch=c(NA, 21), lty=c(2, 1))
}

# ---------- Region: Calculate a total error among all dramas for each model
{
num_dramas_performed <- length(results) / num_models
all_mape <- c()
all_mae <- c()
for (i in 1:num_models) {
  predictions <- c()
  actuals <- c()
  for (j in 1:num_dramas_performed) {
    result_idx <- i + num_models * (j - 1)
    predictions <- c(predictions,  results[[result_idx]]$Prediction)
    actuals <- c(actuals, results[[result_idx]][, 1])
  }
  all_mape <- c(all_mape, mape(predictions, actuals))
  all_mae <- c(all_mae, round(mae(predictions, actuals), 4))
}
mape_dramas <- cbind(mape_dramas, all_mape)
mae_dramas <- cbind(mae_dramas, all_mae)
}

# ---------- Region: Fit a ensemble model and test it
{
cat('--------------------', '\n')
cat('Starting ensemble...', '\n')
ensemble_models_names <- ensemble$input_models
ensemble_results <- list()
mape_drama <- mae_drama <- c()
ensemble_models_idx <- match(ensemble_models_names, models_names)
for (drama_idx in 1:num_dramas_performed) {
  # form data
  x_predictions <- vector()
  for (model_idx in ensemble_models_idx) {
    result_idx <- model_idx + (drama_idx - 1) * num_models
    x_predictions <- cbind(x_predictions,
                           results[[result_idx]]$Prediction)
  }
  y_ratings <- results[[result_idx]][, 1]
  y_x <- data.frame(cbind(y_ratings, x_predictions))
  colnames(y_x) <- c('y', ensemble_models_names)
  
  # initialize result
  result <- results[[result_idx]]
  result[, -1] <- NA
  
  # only keep cases with no missing value at all
  # assumption: all the cases with missing value are centralized first
  y_x_complete <- y_x[complete.cases(y_x), ]
  
  # gradual time series regression
  train_errors <- c()
  test_errors <- c()
  predictions <- c()
  num_min_train <- 2
  for (train_end_idx in num_min_train:(nrow(y_x_complete) - 1)) {
    # prepare training and testing data
    train_idx <- 1:train_end_idx
    test_idx <- train_end_idx + 1
    train_data <- y_x_complete[train_idx, ]
    test_data <- y_x_complete[test_idx, ]
    test_episode <- as.integer(rownames(test_data))
    
    # train an ensemble model
    fit <- do.call(ensemble$predictor,
                   args=c(list(formula=y~., data=train_data), ensemble$args))

    # training error
    predict_train <- predict(fit, new_data=train_data)
    train_error <- mape(predict_train, train_data[['y']])
    
    # test (predict)
    predict_test <- predict(fit, new_data=test_data)
    test_error <- mape(predict_test, test_data[['y']])

    # store result
    result[test_episode, 'Prediction'] <- predict_test
    result[test_episode, 'TestError'] <- test_error
    result[test_episode, 'TrainError'] <- train_error
  }
  ensemble_results[[length(ensemble_results) + 1]] <- result
  mape_drama <- c(mape_drama, mape(result[['Prediction']], result[[1]]))
  mae_drama <- c(mae_drama, round(mae(result[['Prediction']], result[[1]]), 4))
}
mape_dramas <- rbind(mape_dramas, c(mape_drama, NA))
mae_dramas <- rbind(mae_dramas, c(mae_drama, NA))
ensemble_name <- sprintf('%s.%s.%s.%s',
                         ensemble$predictor,
                         ensemble$args$method,
                         ensemble$args$weight_type,
                         paste(ensemble_models_idx, collapse='.'))
rownames(mape_dramas)[nrow(mape_dramas)] <- ensemble_name
rownames(mae_dramas)[nrow(mae_dramas)] <- ensemble_name
}

# ---------- Region: Calculate a total error among all dramas for ensemble
{
predictions <- c()
actuals <- c()
for (i in 1:num_dramas_performed) {
  predictions <- c(predictions, ensemble_results[[i]]$Prediction)
  actuals <- c(actuals, ensemble_results[[i]][, 1])
}
mape_dramas[nrow(mape_dramas), 'all_mape'] <- mape(predictions, actuals)
mae_dramas[nrow(mae_dramas), 'all_mae'] <- round(mae(predictions, actuals), 4)
}

# ---------- Region: Calculate ranks, and print them along with errors
{
mape_rank_dramas <- mape_dramas
mae_rank_dramas <- mae_dramas
for (i in 1:ncol(mape_dramas)) {
  mape_rank_dramas[, i] <- paste(sprintf('%.4f', mape_dramas[, i]), ' #',
                                 rank(mape_dramas[, i]), sep='')
  mae_rank_dramas[, i] <- paste(sprintf('%.4f', mae_dramas[, i]), ' #',
                                rank(mae_dramas[, i]), sep='')
}
print(mape_rank_dramas)
print(mae_rank_dramas)
}

# ---------- Region: Run statistical signifance test
{
# print(friedman.test(mape_dramas))
# print(quade.test(mape_dramas))
# 
# print(friedman.test(mae_dramas))
# print(quade.test(mae_dramas))
}

# Print total time spent
end_time <- proc.time()
time_spent <- end_time - start_time
cat(sprintf("Done! Time spent: %.2f (s)", time_spent["elapsed"]), '\n')
