library(dplyr)
library(tidyr)
library(ggplot2)
library(caret)

source("utils.r")

x <- process_file("../data/generated_data/gene_data/only_genes_2.csv")

x2 <- x[which(x$biosafety_level == "biosafety level 3"),]

#write.csv2(x, file = "only_genes.csv", quote =F)
x$aerophilicity <- NULL

x$num_genes <- NULL
x$Model.Used <- paste0(x$Model.Used, "_onlygenes")

# load the binomial-name based predictions
normal <- readRDS("../data/generated_data/all_models_new_long.rds")
dim(normal)
normal <- normal[which(normal$Model.Used == "openai/gpt-4o"),]
dim(normal)

pred <- x

dat <- read.csv("../data/ground_truth.csv", header = TRUE, sep = ",")

# Get the common columns between pred and dat (excluding 'Binomial.name')
common_cols <- intersect(names(pred), names(dat))
common_cols <- setdiff(common_cols, "Binomial.name")

# Initialize a data frame to store the results
results_df <- data.frame(Model = character(),
                         Target = character(),
                         BalancedAcc = numeric(),
                         Precision = numeric(),
                         SampleSize = integer(),
                         Query.Template = character(),
                         stringsAsFactors = FALSE)

# Unique models
unique_models <- unique(pred$Model.Used)


# Unique combinations of Model.Used, Query.Template
unique_combinations <- unique(pred[, c("Model.Used", "Query.Template")])

  
# Loop over each unique combination of model and query template
for (i in 1:nrow(unique_combinations)) {
  message(i)
  model <- unique_combinations$Model.Used[i]
  query_template <- unique_combinations$Query.Template[i]
  
  model_data_pred <- pred[pred$Model.Used == model & pred$Query.Template == query_template, ]
  merged_data <- merge(dat, model_data_pred, by = "Binomial.name", suffixes = c(".true", ".pred"))
  model_data <- merged_data
  
  # Calculate metrics for each common column
  for (col in common_cols) {
    if (any(model_data[[paste0(col, ".pred")]] == "TRUE", na.rm = TRUE)) {
      pred_col <- convert_to_logical(model_data[[paste0(col, ".pred")]])
      true_col <- convert_to_logical(model_data[[paste0(col, ".true")]])
    } else {
      pred_col <- model_data[[paste0(col, ".pred")]]
      true_col <- model_data[[paste0(col, ".true")]]
    }
    
    # Count valid (non-NA) comparisons
    valid_rows <- complete.cases(pred_col, true_col)
    sample_size <- sum(valid_rows)
    
    if (sample_size == 0) {
      # Append results with NA metrics if no valid data points
      results_df <- rbind(results_df, data.frame(Model = model, Target = col, BalancedAcc = NA, Precision = NA, SampleSize = sample_size, Query.Template = query_template))
    } else {
      # Calculate metrics for the current column
      if (col == "aerophilicity") {
        # Split predictions by comma and trim whitespace
        pred_split <- strsplit(as.character(pred_col[valid_rows]), ",\\s*")
        # Check if any of the split predictions match the ground truth
        pred_match <- sapply(seq_along(pred_split), function(i) {
          any(pred_split[[i]] == true_col[valid_rows][i])
        })
        metrics <- calc_metrics(pred_match, rep(TRUE, length(pred_match)))
      } else {
        metrics <- calc_metrics(pred_col[valid_rows], true_col[valid_rows])
      }
      
      # Append the results to the data frame
      results_df <- rbind(results_df, data.frame(Model = model, Target = col,
        BalancedAcc = metrics$balanced_accuracy, 
        Precision = metrics$precision, 
        SampleSize = sample_size,        
        Query.Template = query_template  # Use the extracted Query.Template value
        ))
    }
  }
}


# Print the results data frame
print(results_df)
unique(results_df$Model)

results_df <- results_df[complete.cases(results_df),]
rownames(results_df) <- NULL
# Save the results


write.csv(results_df, file = "results_onlygenes.csv", quote = F)











# Create a new variable that specifies the order of the targets by maximum BalancedAcc
results_df <- results_df %>%
  group_by(Target) %>%
  mutate(MaxBalancedAcc = max(BalancedAcc, na.rm = TRUE)) %>%
  ungroup()

library(ggplot2)

results_df <- results_df[which(results_df$Target != "health_association"),]

pdf("pred123456.pdf")
p <- ggplot(results_df, aes(x = reorder(Target, BalancedAcc) , y = BalancedAcc))
p <- p + geom_bar(stat = "identity", position = position_dodge(), width = .8) + coord_flip() 
print(p)
dev.off()


