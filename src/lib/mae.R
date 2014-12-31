mae <- function (prediction, actual,
                 na.rm = TRUE, roundTo = 4) {
  # Return mean absolute error.

  # Covert to matrix. It can avoid error when using mean function.
  prediction <- data.matrix(prediction)
  actual <- data.matrix(actual)
  
  # Calculate absolute error
  ae <- abs(prediction - actual)
  
  # Calculate mean and round it
  mae <- round(mean(ae, na.rm = na.rm), roundTo)
  
  return (mae)
}
