# Parameters (Set up by users)
n = 5

# Read input data
chinese_drama_ratings = read.csv("~/Projects//BitBucket/SET//Chinese_Weekday_Drama.csv")
cdr = chinese_drama_ratings

# Calculate the results
nrows = nrow(cdr)
prediction = cdr
# We cannot predict these entries
prediction[1:n,] = NA
prediction[!is.na(prediction)] = 0
for(i in 1:n)
{
  prediction[(n+1):nrows,] = prediction[(n+1):nrows,] + cdr[i:(nrows-n+i-1),]
  # prediction[(n+1):nrows,] = (cdr[1:(nrows-n),] + cdr[2:(nrows-(n-1)),])/2
}
prediction = prediction/n

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