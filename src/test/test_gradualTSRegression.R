# This script is a test of SET TVR data
# It tests performance in terms of different algorithms
# To be specific, it tests the following learning algorithms:
#   - weak learner (nnet and rpart for default)
#   - AdaBoost.R2 (weak learner)
#   - TrAdaBoost.R2 (weak learner)
#   - various time series models

library(nnet)
library(rpart)
library(forecast)  # for auto.arima() and ets()
library(hydroGOF)  # For function mae()
#library(doParallel)

# Global parameters of this script.
# If not set before sourcing this script, use default values as below.
r_control <- rpart.control(minsplit=2, maxdepth=4)
r_control_ensemble <- rpart.control(minsplit=2, maxdepth=1)
project_root <- ifelse(exists('project_root'),
                       project_root,
                       'D:/Projects/GitHub/ntu-research/')
test_dramas_type <- ifelse(exists('test_dramas_type'),
                           test_dramas_type,
                           'Idol') # Or 'Chinese'
has_features <- ifelse(exists('has_feautures'),
                       has_features,
                       FALSE)
window_len <- ifelse(exists('window_len'),
                     window_len,
                     4)
seed <- ifelse(exists('seed'), seed, 0)
if (!exists('base_predictors_args')) {
  base_predictors_args <-list(
#                               list(
#                                    predictor='nnet',
#                                    size=3, linout=T, trace=F,
#                                    rang=0.1, decay=1e-1, maxit=100
#                                   ),
                              list(
                                   predictor='rpart',
                                   control=r_control
                                  )
                             )
}
base_predictors_args <- list() # disable boost and transfer models
baseline_models <- 
  list(
      list(name='lastPeriod',
           args=list(model_type='ts', predictor='guessLastPeriod')
          ),
      list(name='avgPastPeriods',
           args=list(model_type='ts', predictor='avgPastPeriods')
          ),
      list(name='SExpSmoothing',
           args=list(model_type='ts', predictor='HoltWinters', beta=F, gamma=F)
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
      list(name='rsw.rpart.equal',
           args=list(model_type='ts', predictor='rsw',
                     window_len=NULL, weight_type='equal', weighted_sampling=F,
                     method='rpart', control=r_control)
          ),
      list(name='rsw.rpart.equal.ws',
           args=list(model_type='ts', predictor='rsw',
                     window_len=NULL, weight_type='equal',
                     method='rpart', control=r_control)
          ),
      list(name='rsw.rpart.linear',
           args=list(model_type='ts', predictor='rsw',
                     window_len=NULL, weight_type='linear',
                     method='rpart', control=r_control)
          ),
      list(name='rsw.rpart.exp',
           args=list(model_type='ts', predictor='rsw',
                     window_len=NULL, weight_type='exp',
                     method='rpart', control=r_control)
          )
      )
ensemble <- list(predictor='rsw',
                 input_models=c('SExpSmoothing', 'auto.arima', 'nnetar'),
                 args=list(weight_type='linear',
                 method='rpart', control=r_control_ensemble)
                )
ensemble_models_names <- ensemble$input_models
# End of settings

num_base_models <- length(base_predictors_args)
num_baseline_models <- length(baseline_models)
num_models <- num_base_models * 3 + num_baseline_models
models_names <- c()
for (base_predictor_args in base_predictors_args) {
  base_predictor_name <- base_predictor_args$predictor
  models_names <- c(models_names,
                    sprintf('%s', base_predictor_name),
                    sprintf('adaboostR2.%s', base_predictor_name),
                    sprintf('trAdaboostR2.%s', base_predictor_name))
}
# Reference: http://stackoverflow.com/a/2803542
baseline_models_names <- sapply(baseline_models, '[[', 1)
models_names <- c(models_names, baseline_models_names)

# Change working directory to project root to source following libs
setwd(project_root)
source("src/lib/windowing.R")
source("src/lib/mape.R")
source("src/guessLastPeriod.R")
source("src/avgPastPeriods.R")
source("src/adaboostR2.R")
source("src/trAdaboostR2.R")
source("src/rsw.R")
source("src/gradualTSRegression.R")

# Set up parallel computing
# registerDoParallel(cores=detectCores())

# Record script start time for calculating time spent afterwards
start_time <- proc.time()

# Read ratings
ratings_file <- sprintf('data/%s_Drama_Ratings_AnotherFormat.csv',
                        test_dramas_type)
ratings <- read.csv(ratings_file, fileEncoding='utf-8')
# Final output (ratings & features)
data <- ratings

# Read features and combine with ratings
if (has_features) {
  source("src/getFeature.R")
  featureFiles <- c(sprintf('data/%s_Drama_Opinion.csv', test_dramas_type),
                    sprintf('data/%s_Drama_GoogleTrend.csv', test_dramas_type),
                    sprintf('data/%s_Drama_FB.csv', test_dramas_type))
  for (featureFile in featureFiles) {
    feature <- read.csv(featureFile, fileEncoding='utf-8')
    # left join automatically by common variables
    data <- merge(data, feature, sort=FALSE, all.x=TRUE)
  }
}

# sort (for easy view)
attach(data)
data <- data[order(Drama, Episode),]
detach(data)

dramas <- split(data, factor(data[, "Drama"]))

# Handle missing values (it is not needed because we skip them afterwards)
# dramas_tmp <- list() # used to keep dramas that have more than one case
# for (idx in 1:length(dramas)) {
#   # Sort by episode and replace missing values of ratings by interpolation
#   attach(dramas[[idx]])
#   dramas[[idx]] <- dramas[[idx]][order(Episode),]
#   detach(dramas[[idx]])
#   dramas[[idx]][3] <- na.approx(dramas[[idx]][3])
# 
#   # Only keep complete cases (without any missing value)
#   dramas[[idx]] <- dramas[[idx]][complete.cases(dramas[[idx]]),]
# 
#   # Keep dramas that have more than one case
#   if (nrow(dramas[[idx]]) > 0) {
#     new_idx <- length(dramas_tmp) + 1
#     dramas_tmp[[new_idx]] <- dramas[[idx]]
#     names(dramas_tmp)[new_idx] <- names(dramas)[idx]
#   }
# }
# dramas <- dramas_tmp

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

# It is a list of data frames (each is returned from gradualTSRegression).
#   Each data frame represents the results of a drama.
#   Each row has the following column for each episode: 
#     1. ratings
#     2. test prediction
#     3. train prediction
#     4. test error
#     4. train error
#     5. error message
results <- list()

mape_dramas <- matrix(, nrow=num_models, ncol=0)
mae_dramas <- matrix(, nrow=num_models, ncol=0)
rownames(mape_dramas) <- models_names
rownames(mae_dramas) <- models_names

num_dramas <- length(dramas)
# There are many unresolved issues of using %dopar%
# foreach (idx = 1:length(dramas)) %do% {
for (idx in 1:num_dramas) {
  dramaName <- names(dramas)[idx]
  colnames(dramas[[idx]])[3] <- dramaName
  
  target_feature <- dramas[[idx]][, -c(1, 2, 3)]
  ratings <- dramas[[idx]][3]
  
  for (base_predictor_args in base_predictors_args) {
    # Experiment: base predictor only
    set.seed(seed)

    cat('--------------------', '\n')
    cat('Starting experiment...', '\n')
    cat(sprintf('Drama: %s, Model: %s',
                dramaName, base_predictor_args$predictor), '\n')
    
    # Use do.call to easily add new base predictor
    args <- c(list(x=ratings, feature=target_feature, windowLen=window_len),
              base_predictor_args)
    result <- do.call(gradualTSRegression, args=args)
    results[[length(results) + 1]] <- result
    
    # Experiment break: Adjust args for AdaBoost.R2/TrAdaBoost.R2
    # Add a new arg and remove old arg
    base_predictor_args['base_predictor'] <- base_predictor_args$predictor
    base_predictor_args['predictor'] <- NULL
    
    # Experiment: AdaBoost.R2 with base predictor
    set.seed(seed)

    cat('--------------------', '\n')
    cat('Starting experiment...', '\n')
    cat(sprintf('Drama: %s, Model: AdaBoost.R2(%s)',
                dramaName, base_predictor_args$base_predictor), '\n')
    
    args <- c(list(x=ratings, feature=target_feature, windowLen=window_len,
                   predictor='adaboostR2', verbose=T, error_fun=mape),
              base_predictor_args)
    result <- do.call(gradualTSRegression, args=args)
    results[[length(results) + 1]] <- result
    
    # Experiment: TrAdaBoost.R2 with base predictor
    
    # Prepare data set for TrAdaBoost.R2
    # Combine multiple sources into one data set:
    src_data <- list()
    src_indices <- 1:length(dramas)
    src_indices <- src_indices[-idx]
    for (src_idx in src_indices) {
      src_drama_name <- names(dramas)[src_idx]
      colnames(dramas[[src_idx]])[3] <- src_drama_name
      src_data[[length(src_data) + 1]] <- dramas[[src_idx]][3]
  
      # Extra: Add time period as a feature into windowing data
#       time_periods <- seq(window_len, num_cases + window_len - 1)
#       w_data <- cbind(time_periods, w_data)
  
      # Add other features into windowing data
#       features <- tail(dramas[[src_idx]][, -c(1, 2, 3)], num_cases)
#       w_data <- cbind(features, w_data)
    }

    set.seed(seed)
    cat('--------------------', '\n')
    cat('Starting experiment...', '\n')
    cat(sprintf('Drama: %s, Model: TrAdaBoost.R2(%s)',
                dramaName, base_predictor_args$base_predictor), '\n')
    args <- c(list(x=ratings, feature=target_feature, source_data=src_data,
                   windowLen=window_len,
                   predictor='trAdaboostR2', verbose=T, error_fun=mape),
              base_predictor_args)
    result <- do.call(gradualTSRegression, args=args)
    results[[length(results) + 1]] <- result
  }

  # Experiments of baseline models
  for (baseline_model in baseline_models) {
    cat('--------------------', '\n')
    cat('Starting experiment...', '\n')
    cat(sprintf('Drama: %s, Model: %s', dramaName, baseline_model$name), '\n')
    result <- do.call(gradualTSRegression,
                      args=c(list(x=ratings), baseline_model$args))
    results[[length(results) + 1]] <- result
  }

  # After running all experiments, calculate MAPE & MAE
  mape_drama <- c()
  mae_drama <- c()
  for (result in tail(results, num_models)) {
    mape_drama <- c(mape_drama, mape(result['Prediction'], ratings))
    mae_drama <- c(mae_drama, round(mae(result['Prediction'], ratings), 4))
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

num_dramas_performed <- length(results) / num_models

# For each model, calculate an overall error across all dramas
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

# ensemble
cat('--------------------', '\n')
cat('Starting ensemble...', '\n')
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
    predict_train <- predict(fit, train_data)
    train_error <- mape(predict_train, train_data[['y']])
    
    # test (predict)
    predict_test <- predict(fit, test_data)
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

# calculate an overall error for ensemble
predictions <- c()
actuals <- c()
for (i in 1:num_dramas_performed) {
  predictions <- c(predictions, ensemble_results[[i]]$Prediction)
  actuals <- c(actuals, ensemble_results[[i]][, 1])
}
mape_dramas[ensemble_name, 'all_mape'] <- mape(predictions, actuals)
mae_dramas[ensemble_name, 'all_mae'] <- round(mae(predictions, actuals), 4)

# Print test errors and ranks
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

# Run statistical signifance test
# Note: When sourcing a script, output is printed only if with print() function.
# print(friedman.test(mape_dramas))
# print(quade.test(mape_dramas))
# 
# print(friedman.test(mae_dramas))
# print(quade.test(mae_dramas))

# Print total time spent
end_time <- proc.time()
time_spent <- end_time - start_time
cat(sprintf("Done! Time spent: %.2f (s)", time_spent["elapsed"]), '\n')
