library(dplyr)
library(tidyr)
library(ggplot2)
library(caret)

source("../utils.r")

pred1 <- read.csv("batch_results_csv/formatted_output.csv")
pred1$type <- "gene-based"
pred2 <- read.csv("batch_results_csv/formatted_output_name_based.csv")
pred2$type <- "name-based"

pred <- rbind(pred, pred2)

dat <- read.csv("ground_truth.csv")

# Get the common columns between pred and dat (excluding 'Binomial.name')
common_cols <- intersect(names(pred), names(dat))
common_cols <- setdiff(common_cols, "Binomial.name")


# Initialize a data frame to store the results
results_df <- data.frame(Model = character(),
                         Target = character(),
                         BalancedAcc = numeric(),
                         Precision = numeric(),
                         SampleSize = integer(),
                         type = character(),
                         stringsAsFactors = FALSE)

merged_data <- merge(dat, pred, by = "Binomial.name", suffixes = c(".true", ".pred"))

model_data <- merged_data
model <- "gpt-4o-mini"


# Get unique types
unique_types <- unique(pred$type)

# Calculate metrics for each common column and type
for (current_type in unique_types) {
    model_data <- merged_data[merged_data$type == current_type, ]
    
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
            results_df <- rbind(results_df, data.frame(Model = model, Target = col, BalancedAcc = NA, Precision = NA, SampleSize = sample_size, type = current_type))
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
            results_df <- rbind(results_df, data.frame(Model = model, 
                                                       Target = col,
                                                       BalancedAcc = metrics$balanced_accuracy, 
                                                       Precision = metrics$precision, 
                                                       SampleSize = sample_size,
                                                       type = current_type))
        }
    }
}

print(results_df)



# Reshape the data for plotting
plot_data <- results_df %>%
  select(Target, BalancedAcc, type) %>%
  pivot_wider(names_from = type, values_from = BalancedAcc)

# Print column names to check
print(names(plot_data))

# Assuming the column names are "gene-based" and "name-based"
plot_data <- plot_data %>%
  filter(!is.na(`gene-based`) & !is.na(`name-based`))


# Create the comparison plot
comparison_plot <- ggplot(plot_data, aes(x = `gene-based`, y = `name-based`)) +
  geom_point(aes(color = Target), size = 3) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  labs(title = "Comparison of Balanced Accuracy: Gene-based vs Name-based",
       x = "Gene-based Balanced Accuracy",
       y = "Name-based Balanced Accuracy",
       color = "Target") +
  theme_minimal() +
  theme(legend.position = "right") +
  coord_fixed(ratio = 1, xlim = c(0.5, 0.8), ylim = c(0.5, 0.8))

comparison_plot

cor.test(plot_data$`gene-based`, plot_data$`name-based`)

