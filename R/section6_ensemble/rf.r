### This script is used to train random forest models for each phenotype.
### It saves all the results in RDS files
library(randomForest)
library(caret)
library(dplyr)
library(openxlsx)

# load data
full_pred <- readRDS("data/all_models_new_long.rds")
full_truth <- read.csv("data/ground_truth.csv", header = TRUE, sep = ",")
full_groups <- readRDS("data/k_groups_new.rds")
# define target variables
target_vars <- colnames(full_truth)[3:15]

# Prepare a subset of ground truth table
subset_truth <- full_truth %>%
  select(phylum, Binomial.name, any_of(target_vars))
subset_truth <- subset_truth %>% rename(name = Binomial.name)
subset_truth$phylum[is.na(subset_truth$phylum)] <- "not given"
subset_truth$phylum <- as.factor(subset_truth$phylum)

# Initialize
accuracy_df <- data.frame()
importance_list <- list()
conf_mat_list <- list()
predictions_list <- list()
# Loop over each target variable
for (target in target_vars) {
  message("Processing ", target)
  
  # Create subset for the current target variable
  subset_pred <- data.frame(name = full_pred$Binomial.name,
                            model = full_pred$Model.Used,
                            target_var = full_pred[[target]])
  
  # Create wide version
  wide_subset_pred <- reshape(subset_pred, idvar = "name", timevar = "model", direction = "wide")
  
  # Rename columns for clarity
  colnames(wide_subset_pred) <- gsub("target_var", "", colnames(wide_subset_pred))
  
  # Prepare the groups for merging
  subset_groups <- data.frame(name = full_groups$Binomial.name,
                              knowledge_group = full_groups$knowledge_group,
                              model = full_groups$Model.Used)
  wide_subset_groups <- reshape(subset_groups, idvar = "name", timevar = "model", direction = "wide")
  
  # Merge the predictions and groups
  both <- merge(wide_subset_pred, wide_subset_groups, by = "name")
  
  # Replace NA values with "unknown"
  both[is.na(both)] <- "unknown"
  
  # Merge the 'phylum' column from 'subset_truth'
  both <- merge(both, subset_truth[, c("name", "phylum")], by = "name", all.x = TRUE)
  
  full_data <- both
  # Map the target column from subset_truth to both
  full_data$y <- subset_truth[[target]][match(full_data$name, subset_truth$name)]
  print(table(full_data$y))
  # if nrow table < 100, skip
  print(sum(table(full_data$y)))
  if (sum(table(full_data$y)) < 100) {
    message("Skipping ", target, " due to insufficient data")
    target_vars <- target_vars[-which(target_vars == target)]
    next
  }
  # Convert y to factor
  full_data$y <- as.factor(full_data$y)
  full_data_all <- full_data
  full_data <- na.omit(full_data)
  
  # Set up 5-fold cross-validation
  set.seed(88)  # for reproducibility
  kf <- 5
  # Create folds stratified by phylum
  folds <- createFolds(full_data$phylum, k = kf, list = TRUE, returnTrain = FALSE)
  full_data$phylum <- NULL
  
  # Initialize vector to store balanced accuracy
  balanced_accs <- numeric(kf)
  # Initialize variables to track best model
  best_model <- NULL
  best_acc <- -Inf
  # Perform k-fold cross-validation
  for (i in 1:kf) {
    # Split data into training and testing sets
    train_data <- full_data[-folds[[i]], ]
    test_data <- full_data[folds[[i]], ]
    train_data$name <- NULL
    test_data$name <- NULL
    # Upsample the training data to handle class imbalance
    train_data <- upSample(x = train_data[, -ncol(train_data)], y = train_data$y)
    # Rename the target variable back to 'y' after upSample
    colnames(train_data)[ncol(train_data)] <- "y"
    # Clean column names
    colnames(train_data) <- make.names(colnames(train_data))
    colnames(test_data) <- make.names(colnames(test_data))
    colnames(full_data_all) <- make.names(colnames(full_data_all))
    # Train random forest model
    rf_model <- randomForest(
      y ~ ., 
      data = train_data,
      ntree = 500,
      mtry = floor(sqrt(ncol(train_data) - 1)),
      importance = TRUE,
      nodesize = 10
    )
    if (i == 1) {  # Save only once per target (from first fold)
      importance_list[[target]] <- rf_model$importance
    }
    # Make predictions on test set
    predictions <- predict(rf_model, test_data)
    
    # Calculate confusion matrix and save to list
    conf_matrix_save <- confusionMatrix(predictions, test_data$y)
    if (i == 1) {
      conf_mat_list[[target]] <- conf_matrix_save
    }
    # Calculate confusion matrix and balanced accuracy
    conf_matrix <- confusionMatrix(predictions, test_data$y)
    if (is.matrix(conf_matrix$byClass)) {
      # Multi-class case
      balanced_acc <- mean(conf_matrix$byClass[, 'Balanced Accuracy'], na.rm = TRUE)
    } else {
      # Binary case
      balanced_acc <- conf_matrix$byClass['Balanced Accuracy']
    }
    
    # Save the model if it has the highest balanced accuracy
    if (balanced_acc > best_acc) {
      best_acc <- balanced_acc
      best_model <- rf_model  # Save the best model
    }
  }
  
  # Calculate mean balanced accuracy for this target
  mean_balanced_acc <- mean(balanced_accs, na.rm = TRUE)
  
  # Store accuracy results in dataframe
  accuracy_df <- rbind(accuracy_df, 
                       data.frame(target = target, 
                                  mean_balanced_acc = round(mean_balanced_acc, 4), 
                                  fold_accuracies = I(list(round(balanced_accs, 4)))))
  final_predictions <- predict(best_model, full_data_all %>% select(-name))
  predictions_list[[target]] <- data.frame(name = full_data_all$name, predicted = final_predictions)
}

importance_list <- lapply(importance_list, function(imp) {
  # Order by MeanDecreaseGini in descending order
  imp[order(imp[, "MeanDecreaseGini"], decreasing = TRUE), ]
})

top_features_list <- lapply(importance_list, function(imp) {
  # Extract the names of the top 3 features
  top_features <- rownames(imp)[1:3]
  paste(top_features, collapse = ", ")  # Return as a comma-separated string
})

# Add the top 3 features to the accuracy_df based on the target
accuracy_df$top_features <- unlist(top_features_list[accuracy_df$target])

# Combine all predictions into a single data frame
final_predictions_df <- data.frame(Binomial.name = full_truth$Binomial.name)
for (target in target_vars) {
  # Rename the "predicted" column to the current target
  predictions_list[[target]] <- predictions_list[[target]] %>%
    rename(!!target := predicted)  # Dynamically rename the column to the target variable name
  
  # Join the predictions to the final_predictions_df
  final_predictions_df <- final_predictions_df %>%
    left_join(predictions_list[[target]], by = c("Binomial.name" = "name"))
}
# remove row if all values are NA except Binomial.name
final_predictions_df <- final_predictions_df[rowSums(is.na(final_predictions_df)) < ncol(final_predictions_df) - 1, ]
# Save results as RDS
saveRDS(accuracy_df, "result/accuracy_df.rds")
saveRDS(importance_list, "result/importance_list.rds")
saveRDS(conf_mat_list, "result/conf_mat_list.rds")
write.xlsx(final_predictions_df, "result/best_model_predictions.xlsx")
