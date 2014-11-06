write_arff <- function(file_prefix) {
  # Write train (source + partial target), test (partial target) to file.
  #
  # Arguments:
  #   file_prefix: File prefix of UCI data file (e.g., new-autompg).
  #
  # Returns:
  #   No return. It writes arff files to current directory.

  folder <- 'data/transfer data/'
  files <- paste(folder, file_prefix, seq(1, 3), '.arff', sep='')

  # read and preprocess data
  library(foreign)
  uci_data <- list()
  for(file in files) {
    data <- read.arff(file)

    # ignore cases having missing values
    data <- na.omit(data)

    idx <- length(uci_data) + 1
    uci_data[[idx]] <- data
  }

  for(i in 1:length(uci_data)) {
    # prepare training data
    uci_train_data <- vector()
    train_data_idx <- 1:length(uci_data)
    train_data_idx <- train_data_idx[- i]
    for(j in train_data_idx) {
      uci_train_data <- rbind(uci_train_data, uci_data[[j]])
    }

    # prepare source data (for transfer learning algorithm)
    uci_train_src_data <- uci_train_data
    
    # add training instances from target data set
    num_training_from_target <- 25
    train_from_target <- uci_data[[i]][1:num_training_from_target, ]
    uci_train_data <- rbind(uci_train_data, train_from_target)
    
    # prepare target data (for transfer learning algorithm)
    uci_train_target_data <- train_from_target
    
    # prepare testing data
    uci_test_data <- uci_data[[i]][-1:-num_training_from_target, ]
    num_test_cases <- nrow(uci_test_data)
    num_features <- ncol(uci_data[[i]]) - 1
    
    # write source train file
    src_train_file <- paste(file_prefix, paste(train_data_idx, collapse=""),
                            "-src", ".arff", sep="")
    write.arff(uci_train_src_data, src_train_file)
    
    # write target train file
    target_train_file <- paste(file_prefix, i, "-target-train", ".arff", sep="")
    write.arff(uci_train_target_data, target_train_file)
    
    # write test file
    test_file <- paste(file_prefix, i, '-test', ".arff", sep="")
    write.arff(uci_test_data, test_file)
  }
}

file_prefixes <- c('new-concrete', 'new-housing', 'new-autompg')
for(i in 1:length(file_prefixes)) {
  write_arff(file_prefixes[i])
}
