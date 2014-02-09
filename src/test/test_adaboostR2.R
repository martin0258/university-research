library(testthat)

# Precondition: 
#   - The current working directory must be the root of the project.

test_that("adaboostR2 works with lm", {
  source("src/adaboostR2.R")
  
  fit <- adaboostR2(x=cars$speed, y=cars$dist,
                    base_predictor=lm)
  print(summary(fit))
  prediction <- predict(fit, x=cars$speed)
  print(prediction)
})

test_that("adaboostR2 works with rpart", {
  source("src/adaboostR2.R")
  
  library(rpart)
  fit <- adaboostR2(x=cars$speed, y=cars$dist,
                    base_predictor=rpart, method="anova")
  print(summary(fit))
  prediction <- predict(fit, x=cars$speed)
  print(prediction)
})