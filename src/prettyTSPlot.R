prettyTSPlot = function( file, subset=c(), title="", ylabel="" ){
  # Plot multiple time series at one time
  # Trick 1: use cut to rotate label values of y-axis
  # Trick 2: use auto.key=list(space="inside") to make the legend be inside the panel.
  library( "lattice" )
  ratings <- read.csv( file, fileEncoding="utf-8" )
  if( length(subset)>0 ) { ratings <- ratings[, subset] }
  xyplot( ts(ratings), superpose=TRUE, strip=FALSE, cut=1,
          ylab=ylabel, type="b", lwd=2, main=title,
          auto.key=list(space="inside"))
}