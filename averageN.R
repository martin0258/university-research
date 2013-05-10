# Parameters (Set up by users)
n = 5

# Read input data
file = "~/Projects//BitBucket/SET//Chinese_Weekday_Drama.csv"
chinese_drama_ratings = read.csv(file, fileEncoding="utf-8")
cdr = chinese_drama_ratings

# Calculate the results
nrows = nrow(cdr)
ncols = ncol(cdr)
prediction = cdr
# We cannot predict these entries
prediction[1:n,] = NA
for(r in (n+1):nrows)
{
  for(c in 1:ncols)
  {
    prediction[r,c] = mean(cdr[(r-n):(r-1),c])
  }
}

# Compute MAPE
diff = cdr - prediction
absdiff = abs(diff)
absp = absdiff/cdr
mapes = colMeans(absp,na.rm=TRUE)
mape = mean(mapes)

# Print MAPE
print(mapes)
cat("\nAvgN: ",n)
cat("\nMAPE:", mape)