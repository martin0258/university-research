featureExperiment = function(ratingFile, featureFiles, settingFile) {
  # Return a data frame containing all features joined by column Drama & Episode.
  #
  # Args:
  #   ratingFile: a rating file
  #   featureFiles: a list of feature files
  #   settingFile: a feature setting file
  #
  # Returns:
  #   No return. It will write experiment results into various files.
  
  allFeatures <- getFeatures(featureFiles)
  settings <- read.csv(settingFile, fileEncoding="utf-8")
  settingFeatures <- names(settings)
  # TODO: find common columns dynamically
  commonColumns <- c("Drama", "Episode")
  commonFilter <- rep(TRUE, length(commonColumns))
  selectedColumns <- c(commonColumns, settingFeatures)
  features <- subset(allFeatures, select = selectedColumns)
  
  # Loop through all settings
  for(i in 1:nrow(settings))
  {
    setting <- c(commonFilter, as.logical(settings[i,]))
    subFeatures <- features[, setting]
    if(ncol(subFeatures)==length(commonColumns))
    {
      subFeatures <- NULL
    }
    result <- dynamicARIMA(ratingFile, subFeatures)
    fileName <- sprintf("%s.csv", paste(settings[i,], collapse=''))
    write.table(t(result$mape), fileName, row.names = FALSE)
    write.table(result$forecast, fileName, append = TRUE, row.names = FALSE)
  }
}