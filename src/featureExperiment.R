featureExperiment = function (ratingFile, featureFiles, featureSettingFile,
                              featureSuffixes=c('0','1','2','3')) {
  # Perform feature selection experiments.
  #
  # Args:
  #   ratingFile: a rating file
  #   featureFiles: a list of feature files
  #   featureSettingFile: a feature setting file
  #   featureSuffixes: column names with one of the suffix will be included
  #
  # Returns:
  #   No return. It will write experiment results into various files.
  
  # Get a list of data frames from feature files (one each)
  featureList <- getFeatures(featureFiles, featureSuffixes)
  features <- featureList$data
  numCases <- nrow(features[[1]])

  # Read settings. Each row is an experiment.
  featureSettings <- read.csv(featureSettingFile, fileEncoding="utf-8")
  for (i in 2:nrow(featureSettings)) {
    # Compose the features used at this experiment
    setting <- featureSettings[i, ]
    if (length(setting) != length(features)) {
      stop("Number of column mismatched between feature and its setting.")
    }
    featureUsed <- data.frame(row.names=1:numCases)

    for (j in 1:length(setting)) {
      if (setting[j]=='1') {
        featureUsed <- cbind(featureUsed, features[[j]])
      }
    }
    if (ncol(featureUsed) == 0) {
      featureUsed <- NULL
    } else {
      featureUsed <- cbind(featureList$selector, featureUsed)
    }

    # Run experiment
    result <- dynamicARIMA(ratingFile, featureUsed)

    # Write result into files
    fileName <- sprintf("%s.csv", paste(setting, collapse=''))
    write.table(t(result$mape), fileName, row.names = FALSE)
    write.table(result$forecast, fileName, append = TRUE, row.names = FALSE)
  }
}

genRatingFeature <- function (previousN = 3) {
  # Generate ratings features:
  #   - Ratings of previous N episodes
  #   - Ratings of 1st episode
  
  # Read ratings (working directory must be"ntu-research/data")
  file <- "Chinese_Drama_Ratings_AnotherFormat.csv"
  ratings <- read.csv(file, fileEncoding="utf-8")
  
  # Group ratings by Drama name
  group <- factor(ratings[, "Drama"])
  ratingsByDrama <- split(ratings, group)
  
  # Prepare outputs
  preRatings <- ratingsByDrama
  firstRatings <- ratingsByDrama
  
  # For each drama
  for (dramaIdx in 1:length(preRatings)) {
    thisRatings <- preRatings[[dramaIdx]]
    
    # Generate previous ratings for each episode
    for (episode in (previousN + 1):nrow(thisRatings)) {
      # For each previous episode
      for (preEpisode in 1:previousN) {
        colName <- sprintf("PreRating_%d", preEpisode)
        thisRatings[episode, colName] <- 
          thisRatings[(episode - preEpisode), "Ratings"]
      }
    }
    preRatings[[dramaIdx]] <- thisRatings
    
    # Generate 1st ratings for each episode
    for (episode in 1:nrow(thisRatings)) {
      firstRatings[[dramaIdx]][episode, "Ratings_1"] <-
        thisRatings[1, "Ratings"]
    }
  }
  
  # Unsplit to do some post-processing
  preRatings <- unsplit(preRatings, group)
  firstRatings <- unsplit(firstRatings, group)

  # Post-processing: Remove Ratings column
  preRatings <- preRatings[, -3]
  firstRatings <- firstRatings[, -3]

  # Write output to file
  write.table(preRatings, 
              "Chinese_Drama_PreRatings.csv",
              row.names=FALSE,
              sep=",",
              fileEncoding="utf-8")
  write.table(firstRatings, 
              "Chinese_Drama_1stRatings.csv",
              row.names=FALSE,
              sep=",",
              fileEncoding="utf-8")
}

# Example:
# Assume the working directory is "data"
genRatingFeature()
source("../src/getFeature.R")
ratingFile <- "Chinese_Drama_Ratings.csv"
featureFiles <- c("Chinese_Drama_Opinion.csv",
                  "Chinese_Drama_GoogleTrend.csv",
                  "Chinese_Drama_FB.csv")
featureSettingFile <- "../featureSetting.csv"
featureSuffixes <- c('0', '1', '2', '3')
featureExperiment(ratingFile, featureFiles,
                  featureSettingFile, featureSuffixes)
