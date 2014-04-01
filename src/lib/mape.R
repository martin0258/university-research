mape <- function (prediction, actual, na.rm = TRUE, roundTo = 4) {
  # Return mean absolute percentage error.

  absp <- abs(prediction - actual) / actual
  mape <- round(mean(absp, na.rm = na.rm), roundTo)
  return (mape)
}