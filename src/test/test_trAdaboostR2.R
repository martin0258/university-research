# Usage example on SET ratings data
library(nnet)
library(zoo)
set.seed(0)
# Change working directory to "ntu-research/"
# setwd("~/Projects/GitHub/ntu-research/")
source("src/lib/windowing.R")
source("src/lib/mape.R")
source("src/trAdaboostR2.R")
data <- read.csv("data/Chinese_Drama_Ratings_AnotherFormat.csv",
                 fileEncoding="utf-8")
dramas <- split(data, factor(data[, "Drama"]))

# Data preprocessing: replace missing values by interpolation
for (idx in 1:length(dramas)) {
  dramas[[idx]][3] <- na.approx(dramas[[idx]][3])
}

results <- list()
for (idx in 1:length(dramas)) {
  # Form source data:
  #   - Apply windowing transformation to each drama
  #   - Bind data
  window_len <- 4
  src_indices <- 1:length(dramas)
  src_indices <- src_indices[-idx]
  src_data <- c()  # An empty data frame?
  for (src_idx in src_indices) {
    src_drama_name <- names(dramas)[src_idx]
    colnames(dramas[[src_idx]])[3] <- src_drama_name
    src_drama <- dramas[[src_idx]][src_drama_name]
    wData <- windowing(src_drama, window_len)
    src_data <- rbind(wData, src_data)
  }
  src_data <- data.frame(src_data)
  colnames(src_data)[ncol(src_data)] <- "Y"

  # Form target data
  t_drama_name <- names(dramas)[idx]
  colnames(dramas[[idx]])[3] <- t_drama_name
  t_data <- windowing(dramas[[idx]][t_drama_name], window_len)
  t_data <- data.frame(t_data)
  colnames(t_data)[ncol(t_data)] <- "Y"

  # Train model: nnet + trAdaBoostR2
  model <- trAdaboostR2("Y~.",
                        source_data=src_data,
                        target_data=t_data,
                        base_predictor=nnet,
                        size=3, linout=T, trace=F,
                        rang=0.1, decay=1e-1, maxit=100)
  # Predict
  result <- predict(model, t_data)
  result_mape <- mape(result, t_data["Y"])
  results[[idx]] <- list(prediction=result, mape=result_mape)
}