getFeatures <- function (featureFiles, featureSuffixes,
                        suffixSeparator='_') {
  # Return a data frame containing all features joined by common variables.
  #
  # Args:
  #   featureFiles: a list of feature files
  #   featureSuffixes: column names with one of the suffix will be included
  #   suffixSeparator: a character appears before the feature suffixes
  #
  # Returns:
  #   A data frame joined by common variables and filtered by suffixes
  
  dataFrames <- list()
  for(featureFile in featureFiles)
  {
    # Read input data
    features <- read.csv(featureFile, fileEncoding="utf-8")

    # Assumption: we assume same row in different files represent same case

    # Filter column by suffixes
    columnsSelected <- vector()
    columnNames <- names(features)
    for (i in 1:length(columnNames)) {
      # Add into columns selected if it matches one of suffixes
      nameSplits <- unlist(strsplit(columnNames[i], suffixSeparator))
      splitLen <- length(nameSplits)
      if (splitLen > 1) {
        # Length is greater than 1 means it has suffix
        suffix <- nameSplits[splitLen
                             ]
        if (suffix %in% featureSuffixes) {
          columnsSelected <- c(columnsSelected, columnNames[i])
        }
      }
    }

    dataFrames[[length(dataFrames)+1]] <- subset(features,
                                                 select=columnsSelected)
  }

  # FIXME: remove hard-coded selector
  features <- read.csv(featureFiles[1], fileEncoding="utf-8")
  return (list(selector=features[, c(1, 2)], data=dataFrames))
}
