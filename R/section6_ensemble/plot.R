### This file creates the plots needed in the supplementary material of the paper.
library(ggplot2)
library(dplyr)
library(scales)
accuracy_df <- readRDS("result/accuracy_df.rds")
conf_mat_list <- readRDS("result/conf_mat_list.rds")

## Plot the confusion matrix for cell shape and hemolysis

# Cell shape
cellshape <- conf_mat_list[["cell_shape"]][["table"]]
cellshape_df <- as.data.frame(cellshape)
# Calculate percentages within each Reference group
cellshape_df <- cellshape_df %>%
  group_by(Reference) %>%
  mutate(Percentage = (Freq / sum(Freq)) * 100) %>%
  ungroup()
# Capitalize the first letter of each word in the column names
cellshape_df$Prediction <- factor(cellshape_df$Prediction,
                                  levels = c("bacillus", "coccus", "spirillum", "tail"),
                                  labels = c("Bacillus", "Coccus", "Spirillum", "Tail"))
cellshape_df$Reference <- factor(cellshape_df$Reference,
                                 levels = c("bacillus", "coccus", "spirillum", "tail"),
                                 labels = c("Bacillus", "Coccus", "Spirillum", "Tail"))
# Create the confusion matrix plot using ggplot2
ggplot(cellshape_df, aes(x = Reference, y = Prediction)) +
  geom_tile(aes(fill = Percentage), color = "black") +  # Add black borders to each square
  scale_fill_gradient(low = "white", high = "brown", labels = label_number(suffix = "%", accuracy = 1)) +  # Add "%" to legend labels
  geom_text(aes(label = paste(Freq, "\n(", round(Percentage, 1), "%)", sep = ""),
                color = ifelse(Prediction == Reference, "white", "black")), size = 5) +
  scale_color_identity() +
  theme_minimal() +
  labs(x = "Ground Truth", y = "LLM Prediction", fill = "Percentage", subtitle = "Cell shape prediction") +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(hjust = 1),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks = element_blank(),
    plot.subtitle = element_text(hjust = 0.5)
  )
ggsave("graph/cell_shape.svg", width = 5, height = 4, units = "in", device = "svg")

# Hemolysis
hemolysis <- conf_mat_list[["hemolysis"]][["table"]]
hemolysis_df <- as.data.frame(hemolysis)
# Calculate percentages within each Reference group
hemolysis_df <- hemolysis_df %>%
  group_by(Reference) %>%
  mutate(Percentage = (Freq / sum(Freq)) * 100) %>%
  ungroup()
# Capitalize the first letter of each word in the column names
hemolysis_df$Prediction <- factor(hemolysis_df$Prediction,
                                  levels = c("alpha", "beta", "gamma"),
                                  labels = c("Alpha", "Beta", "Gamma"))
hemolysis_df$Reference <- factor(hemolysis_df$Reference,
                                 levels = c("alpha", "beta", "gamma"),
                                 labels = c("Alpha", "Beta", "Gamma"))
# Create the confusion matrix plot using ggplot2
ggplot(hemolysis_df, aes(x = Reference, y = Prediction)) +
  geom_tile(aes(fill = Percentage), color = "black") +  # Add black borders to each square
  scale_fill_gradient(low = "white", high = "brown", labels = label_number(suffix = "%", accuracy = 1)) +  # Add "%" to legend labels
  geom_text(aes(label = paste(Freq, "\n(", round(Percentage, 1), "%)", sep = ""),
                color = ifelse(Prediction == Reference, "white", "black")), size = 5) +
  scale_color_identity() +
  theme_minimal() +
  labs(x = "Ground Truth", y = "LLM Prediction", fill = "Percentage", subtitle = "Hemolysis prediction") +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(hjust = 1),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks = element_blank(),
    plot.subtitle = element_text(hjust = 0.5)
  )
ggsave("graph/hemolysis.svg", width = 5, height = 4, units = "in", device = "svg")
