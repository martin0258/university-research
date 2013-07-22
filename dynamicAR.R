# Summary: This script trains a AR model for every time period.

# Parameters
file <- "Chinese_Weekday_Drama.csv"

# Read input data
data <- read.csv(file, fileEncoding="utf-8")

# Prepare data structures
prediction <- data
prediction[1:2,] <- NA
prediction[!is.na(prediction)] <- 0
bestOrder <- prediction

# Error Info
errInfo <- c()

for(drama in 1:ncol(data))
{
  nepisode <- max(which(!is.na(data[drama])))
  # Predict from the 3rd episdoe for each drama
  # Because We have no way to predict the 1st, and can only guess the 1st for the 2nd
  for(episode in 3:nepisode)
  {
    tbestOrder <- 0
    trainingTS <- ts(data[drama][1:(episode-1),1])
    
    # Error handling for methods other than yw
    arModel <- tryCatch({
      ar(trainingTS, method="mle", na.action=na.exclude)
    }, error = function(err) {
      return(err)
    })
    # Error occurs. No prediction.
    if(inherits(arModel,"error"))
    {
      errInfo <- rbind(errInfo, c(drama=colnames(data[drama]), episode=episode, error=paste(arModel)))
      bestOrder[episode,drama] <- NA
      prediction[episode,drama] <- NA
      next
    }
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
cat("\ntotalMAPE: ", totalMAPE, "\n")
print(errInfo)