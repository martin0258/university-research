mape <- function (prediction, actual, na.rm = TRUE, roundTo = 4) {
  # Return mean absolute percentage error.

  # Covert from data frame to matrix
  # (The convertion can avoid error when using mean function)
  prediction <- data.matrix(prediction)
  actual <- data.matrix(actual)
  absp <- abs(prediction - actual) / actual
  mape <- round(mean(absp, na.rm = na.rm), roundTo)
  return (mape)
}