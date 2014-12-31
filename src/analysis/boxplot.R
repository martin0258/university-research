## Parameters that control data set (either Idol or Chinese)
test_dataset <- ifelse(exists('test_dataset'), test_dataset, 'Idol')

# read data
ratings_file <- sprintf('data/%s_Drama_Ratings_AnotherFormat.csv', test_dataset)
ratings <- read.csv(ratings_file, fileEncoding='utf-8')

# process data: remove dramas that have missing values

box <- boxplot(Ratings ~ Drama, data=ratings, col='orange', plot=F)
shorter_names <- substr(box$names, 0, 2)
boxplot(Ratings ~ Drama, data=ratings, col='orange', names=shorter_names,
        main=sprintf('Boxplot of %s Dramas Ratings', test_dataset),
        ylab='Ratings')
