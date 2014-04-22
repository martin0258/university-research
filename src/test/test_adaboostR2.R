library(testthat)
context("Test AdaBoost.R2")
source("../adaboostR2.R")
library(pracma)

# Precondition: 
#   - The current working directory must be the root of the project.

seed <- 0

uci_test <- function(file_prefix, predictor, ...) {
  folder <- '../../data/transfer data/'
  files <- paste(folder, file_prefix, seq(1, 3), '.arff', sep='')
  response <- 'my_res'

  # read and preprocess data
  library(foreign)
  uci_data <- list()
  for(file in files) {
    data <- read.arff(file)

    # ignore cases having missing values
    data <- na.omit(data)

    idx <- length(uci_data) + 1
    names(data)[ncol(data)] <- response
    uci_data[[idx]] <- data
  }

  # run 3 experiments (with different target sets)
  training_rmse <- vector()
  testing_rmse <- vector()
  for(i in 1:length(uci_data)) {
    # prepare training data
    uci_train_data <- vector()
    train_data_idx <- 1:length(uci_data)
    train_data_idx <- train_data_idx[- i]
    for(j in train_data_idx) {
      uci_train_data <- rbind(uci_train_data, uci_data[[j]])
    }

    # add training instances from target data set
    num_training_from_target <- 25
    uci_train_data <- rbind(uci_train_data,
                            uci_data[[i]][1:num_training_from_target, ])

    # prepare testing data
    uci_test_data <- uci_data[[i]][-1:-num_training_from_target, ]
    num_test_cases <- nrow(uci_test_data)
    num_features <- ncol(uci_data[[i]]) - 1
    formula <- as.formula(sprintf('%s ~ .', response))
    fit <- predictor(formula, uci_train_data, ...)
    train_prediction <- predict(fit, uci_train_data)
    test_prediction <- predict(fit, uci_test_data)
    test_errors <- rmserr(test_prediction, uci_test_data[[response]])
    train_errors <- rmserr(train_prediction, uci_train_data[[response]])
    training_rmse <- c(training_rmse, round(train_errors$rmse, 2))
    testing_rmse <- c(testing_rmse, round(test_errors$rmse, 2))
  }
  cat(' Training RMSE: ', paste(training_rmse, collapse=' | '), '\n')
  cat(' Testing  RMSE: ', paste(testing_rmse, collapse=' | '), '\n')
}

test_that('UCI Conrete Length data', {
  file_prefix <- 'new-concrete'
  set.seed(seed)
  cat(sprintf('-- Data: %s -----------------------', file_prefix), '\n')
  cat(sprintf('-- Model: nnet -----------------------'), '\n')
  # TODO: avoid declaring duplicate parameters
  uci_test(file_prefix, nnet, size=7, linout=T, trace=F)
  cat(sprintf('-- Model: AdaBoost.R2 with nnet ------'), '\n')
  uci_test(file_prefix, adaboostR2, size=7, linout=T, trace=F)
})

test_that('UCI Housing data', {
  file_prefix <- 'new-housing'
  set.seed(seed)
  cat(sprintf('-- Data: %s -----------------------', file_prefix), '\n')
  cat(sprintf('-- Model: nnet -----------------------'), '\n')
  # TODO: avoid declaring duplicate parameters
  uci_test(file_prefix, nnet, size=12, linout=T, trace=F)
  cat(sprintf('-- Model: AdaBoost.R2 with nnet ------'), '\n')
  uci_test(file_prefix, adaboostR2, size=12, linout=T, trace=F)
})

test_that('UCI Auto MPG data', {
  file_prefix <- 'new-autompg'
  set.seed(seed)
  cat(sprintf('-- Data: %s -----------------------', file_prefix), '\n')
  cat(sprintf('-- Model: nnet -----------------------'), '\n')
  # TODO: avoid declaring duplicate parameters
  uci_test(file_prefix, nnet, size=6, linout=T, trace=F)
  cat(sprintf('-- Model: AdaBoost.R2 with nnet ------'), '\n')
  uci_test(file_prefix, adaboostR2, size=6, linout=T, trace=F)
})

# TODO: fix error "factor c has new levels chevrolet, honda"
# test_that('UCI Automobile data', {
#   file_prefix <- 'new-imports'
#   set.seed(seed)
#   cat(sprintf('-- Data: %s -----------------------', file_prefix), '\n')
#   cat(sprintf('-- Model: nnet -----------------------'), '\n')
#   # TODO: avoid declaring duplicate parameters
#   uci_test(file_prefix, nnet, size=24, linout=T, trace=F, MaxNWts=2000)
#   cat(sprintf('-- Model: AdaBoost.R2 with nnet ------'), '\n')
#   uci_test(file_prefix, adaboostR2, size=24, linout=T, trace=F, MaxNWts=2000)
# })
