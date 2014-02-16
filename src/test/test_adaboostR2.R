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

test_that("adaboostR2 with lm", {
  fit <- adaboostR2("y~.", train_data,
                    base_predictor=lm)
  print(summary(fit))
  prediction <- predict(fit, test_data)
  expect_that(prediction, equals(test.y))
})

test_that("adaboostR2 with rpart", {
  library(rpart)
  fit <- adaboostR2("y~.", train_data,
                    base_predictor=rpart, method="anova")
  print(summary(fit))
  prediction <- predict(fit, test_data)
  expect_that(prediction, equals(test.y))
})