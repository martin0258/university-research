## Parameters that control data set (either Idol or Chinese)
test_dataset <- ifelse(exists('test_dataset'), test_dataset, 'Idol')

# read data
ratings_file <- sprintf('data/%s_Drama_Ratings_AnotherFormat.csv', test_dataset)
ratings <- read.csv(ratings_file, fileEncoding='utf-8')

# process data: remove dramas that have missing values
ratings <- ratings[ratings$Drama!="我租了一個情人", ]
ratings <- droplevels(ratings)

num_dramas <- length(unique(ratings[, 'Drama']))
box <- boxplot(Ratings ~ Drama, data=ratings, col='orange', plot=F)
shorter_names <- substr(box$names, 0, 2)
thesis_names <- paste('D', seq(1, num_dramas), sep='')
boxplot(Ratings ~ Drama, data=ratings, col='orange', names=thesis_names,
        main=sprintf('Box plots of %s Dramas Ratings', test_dataset),
        ylab='Ratings', xlab='Dramas')
