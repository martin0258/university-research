featureScale = function(featureFile, newRange = c(0, 1), columnsToIgnore = c(1, 2)) {
  # Write a scaled feature file to the same folder of the original file.
  #
  # Args:
  #   featureFile: a feature file
  #   newRange: output range (numeric vector of length two)
  #   columnsToIgnore: columns to ignore when doing scaling
  #
  # Returns:
  #   No return.
  
  library(scales)
  library(tools)

  feature <- read.csv(featureFile, fileEncoding="utf-8")
  allColumns <- seq(1, ncol(feature))
  columnsToScale <- setdiff(allColumns, columnsToIgnore)
  for(cIndex in columnsToScale)
  {
    feature[, cIndex] <- rescale(feature[, cIndex])
  }
  fileExt <- file_ext(featureFile)
  filePathNoExt <- file_path_sans_ext(featureFile)
  newRangeSuffix <- paste(newRange, collapse='')
  newFilePath <- sprintf("%s_scale%s.%s", filePathNoExt, newRangeSuffix, fileExt)
  write.csv(feature, newFilePath, row.names = FALSE)
}