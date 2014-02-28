library(testthat)
context("Test AdaBoost.R2")
source("../adaboostR2.R")

# Precondition: 
#   - The current working directory must be the root of the project.

# Toy sample
train.x <- rbind(c(-2, -1),
           c(-1, -1),
           c(-1, -2),
           c(1, 1),
           c(1, 2),
           c(2, 1))
train.y <- c(-1, -1, -1, 1, 1, 1)
test.x <- rbind(c(-1, -1),
                c(2, 2),
                c(3, 2))
test.y <- c(-1, 1, 1)
train_data <- data.frame(x=train.x, y=train.y)
test_data <- data.frame(x=test.x)
seed <- 0

test_that("adaboostR2 with lm", {
  set.seed(seed)
  fit <- adaboostR2("y~.", train_data,
                    base_predictor=lm)
  prediction <- predict(fit, test_data)
  expect_that(prediction, equals(test.y))
})

test_that("adaboostR2 with rpart", {
  library(rpart)
  set.seed(seed)
  fit <- adaboostR2("y~.", train_data,
                    base_predictor=rpart, method="anova")
  prediction <- predict(fit, test_data)
  expect_that(prediction, equals(test.y))
})

test_that("adaboostR2 with nnet", {
  library(nnet)
  set.seed(seed)
  num_features <- ncol(train_data) - 1
  fit <- adaboostR2("y~.", train_data,
                    base_predictor=nnet,
                    size=num_features, linout=TRUE, trace=FALSE)
  prediction <- predict(fit, test_data)
  expect_that(prediction, equals(test.y))
})
