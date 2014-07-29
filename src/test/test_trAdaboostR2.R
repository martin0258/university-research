# Usage example on SET ratings data
library(nnet)
library(zoo)
set.seed(0)
# Change working directory to "ntu-research/"
# setwd("~/Projects/GitHub/ntu-research/")
source("src/lib/windowing.R")
source("src/lib/mape.R")
source("src/trAdaboostR2.R")
# Read ratings
ratings <- read.csv("data/Chinese_Drama_Ratings_AnotherFormat.csv",
                    fileEncoding="utf-8")
# Final output (ratings & features)
data <- ratings
# Read features and combine with ratings
source("src/getFeature.R")
featureFiles <- c("data/Chinese_Drama_Opinion.csv",
                  "data/Chinese_Drama_GoogleTrend.csv",
                  "data/Chinese_Drama_FB.csv")
for (featureFile in featureFiles) {
  feature <- read.csv(featureFile, fileEncoding="utf-8")
  # left join automatically by common variables
  data <- merge(data, feature, sort=F, all.x=TRUE)
}

# sort (for easy view)
attach(data)
data <- data[order(Drama, Episode),]
detach(data)

dramas <- split(data, factor(data[, "Drama"]))

# Handle missing values
dramas_tmp <- list() # used to keep dramas that have more than one case
for (idx in 1:length(dramas)) {
  # Sort by episode and replace missing values of ratings by interpolation
  attach(dramas[[idx]])
  dramas[[idx]] <- dramas[[idx]][order(Episode),]
  detach(dramas[[idx]])
  dramas[[idx]][3] <- na.approx(dramas[[idx]][3])

  # Only keep complete cases (without any missing value)
  dramas[[idx]] <- dramas[[idx]][complete.cases(dramas[[idx]]),]

  # Keep dramas that have more than one case
  if (nrow(dramas[[idx]]) > 0) {
    new_idx <- length(dramas_tmp) + 1
    dramas_tmp[[new_idx]] <- dramas[[idx]]
    names(dramas_tmp)[new_idx] <- names(dramas)[idx]
  }
}
dramas <- dramas_tmp

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

    # bind features
    ncases <- nrow(dramas[[src_idx]])
    # Assumption: col1=Drama, col2=Episode, col3=Rating, col4~colN=Features
    feature <- dramas[[src_idx]][window_len:ncases, -c(1, 2, 3)]
    wData <- cbind(feature, wData)

    src_data <- rbind(wData, src_data)
  }
  src_data <- data.frame(src_data)
  colnames(src_data)[ncol(src_data)] <- "Y"

  # Form target data
  t_drama_name <- names(dramas)[idx]
  colnames(dramas[[idx]])[3] <- t_drama_name
  t_data <- windowing(dramas[[idx]][t_drama_name], window_len)

  # bind features
  ncases <- nrow(dramas[[idx]])
  t_data <- cbind(dramas[[idx]][window_len:ncases, -c(1, 2, 3)], t_data)

  t_data <- data.frame(t_data)
  colnames(t_data)[ncol(t_data)] <- "Y"

  # Train model: nnet + trAdaBoostR2
  model <- trAdaboostR2("Y~.",
                        source_data=src_data,
                        target_data=t_data,
                        verbose=T,
                        base_predictor=nnet,
                        size=3, linout=T, trace=F,
                        rang=0.1, decay=1e-1, maxit=100)
  # Predict
  result <- predict(model, t_data)
  result_mape <- mape(result, t_data["Y"])
  results[[idx]] <- list(prediction=result, mape=result_mape)
}