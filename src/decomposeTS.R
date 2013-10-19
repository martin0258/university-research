decomposeTS = function( file ) {
  # Summary: This script decomposes time series via STL
  # Dependency: stl {stats}, na.approx {zoo}, seasadj {forecast}
  
  # Parameter
  #   file: the ratings file (e.g., Chinese_Weekday_Drama.csv)
  # Return
  #   A list containing objects of class "stl" with components

  library(zoo)
  library(forecast)

  # Hard-coding
  tsFrequency <- 5

  # Read input data
  data <- read.csv(file, fileEncoding="utf-8")
  
  fits <- list()
  errInfo <- c()
  
  for(dIndex in 1:ncol(data))
  {
    name <- names(data[dIndex])
    series <- ts(data[dIndex][,], frequency=tsFrequency)
    
    fit <- tryCatch({
      stl(series, s.window="periodic", 
               robust=TRUE, na.action=na.approx)
    }, error = function(err){
      return (err)
    })
    
    # Errors when executing STL
    if(inherits(fit, "error"))
    {
      errInfo <- rbind(errInfo, c(drama=name, error=paste(fit)))
      next
    }
    
    # Remove frequency to see episode in x-axis
    fit$time.series <- ts(fit$time.series)
    fits[[name]] <- fit
    
    # Plot decomposition
    folder <- "images/"
    filename <- paste("stl_", name, ".jpg", sep="")
    fullPath <- paste(folder, filename, sep="")
    jpeg(file = fullPath)
    plot(fit, main=paste("STL of ", name))
    dev.off()
    
    # Plot original data , trend-cycle, and seasonal adjustment
    filename <- paste("trend_seasadj_", name, ".jpg", sep="")
    fullPath <- paste(folder, filename, sep="")
    jpeg(file = fullPath)
    plot(ts(series), main=name, col="grey")
    lines(fit$time.series[,"trend"], col="red")
    lines(seasadj(fit), col="blue")
    legend("topleft", legend=c("data", "trend", "seasadj"), fill=c("grey", "red", "blue"))
    dev.off()
  }
  
  cat(errInfo)
  return(fits)
}
