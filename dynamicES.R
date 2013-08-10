# Summary: This script trains a Exponential smoothing for every time period.
# Dependencies:
#   HoltWinters() in a built-in package "stat"

# Parameters
file <- "Chinese_Weekday_Drama.csv"

# Read input data
data <- read.csv(file, fileEncoding="utf-8")

# Prepare data structures
prediction <- data
prediction[1,] <- NA  # Not able to predict the 1st period
prediction[!is.na(prediction)] <- 0

# Error Info
errInfo <- c()

for(drama in 1:ncol(data))
{
  nepisode <- max(which(!is.na(data[drama])))
  # Predict from the 2nd period
  for(episode in 2:nepisode)
  {
    trainingTS <- ts(data[drama][1:(episode-1),1])
    
    # Training phase
    # Error handling for training a HoltWinters model
    esModel <- tryCatch({
      HoltWinters( trainingTS, beta=FALSE, gamma=FALSE )
    }, error = function(err) {
      return(err)
    })
    # Error occurs when training. No prediction.
    if(inherits(esModel,"error"))
    {
      errInfo <- rbind(errInfo, c(drama=colnames(data[drama]),
                                  phase='train',
                                  episode=episode, 
                                  error=paste(esModel)))
      prediction[episode,drama] <- NA
      next
    }
    # Testing phase
    prediction[episode,drama] <- predict( esModel, n.ahead=1 )[1]
  }
}

# Calculate total MAPE
absp <- abs(prediction-data)/data
mapes <- colMeans(absp, na.rm=TRUE)
print(mapes)
print(errInfo)