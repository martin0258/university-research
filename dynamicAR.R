# Summary: This script trains a AR model for every time period.

# Parameters
file <- "Chinese_Weekday_Drama.csv"

# Read input data
data <- read.csv(file, fileEncoding="utf-8")

# Prepare data structures
prediction <- data
prediction[1,] <- NA
prediction[!is.na(prediction)] <- 0
prediction[2,] <- data[1,]
bestOrder <- prediction
bestOrder[2,] <- NA

for(drama in 1:ncol(data))
{
  nepisode <- max(which(!is.na(data[drama])))
  # Predict from the 3rd episdoe for each drama
  # Because We have no way to predict the 1st, and can only guess the 1st for the 2nd
  for(episode in 3:nepisode)
  {
    tbestOrder <- 0
    trainingTS <- ts(data[drama][1:(episode-1),1])
    arModel <- ar(trainingTS, method="yw", na.action=na.exclude)
    # Use the bestN and minMAPE found to predict this episode
    bestOrder[episode,drama] <- arModel$order
    prediction[episode,drama] <- predict(arModel,trainingTS)$pred[1]
  }
}

# Calculate total MAPE
absp <- abs(prediction-data)/data
mapes <- colMeans(absp, na.rm=TRUE)
totalMAPE <- mean(mapes)
print(mapes)
cat("\ntotalMAPE: ", totalMAPE)