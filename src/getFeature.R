getFeatures = function(featureFiles) {
  # Return a data frame containing all features joined by column Drama & Episode.
  #
  # Args:
  #   featureFiles: a list of feature files
  #
  # Returns:
  #   A data frame of column Drama, Episode, and feature columns.
  
  # We use join_all to merge different feature files
  library(plyr)
  
  dataFrames <- list()
  for(featureFile in featureFiles)
  {
    # Read input data
    dataFrame <- read.csv(featureFile, fileEncoding="utf-8")
    dataFrames[[length(dataFrames)+1]] <- dataFrame
  }

  # Join by common variables (expectation: Drama, Episode)
  features <- join_all(dataFrames)
  return(features)  
}