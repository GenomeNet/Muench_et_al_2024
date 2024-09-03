
# Function to check if predicted values are mutually exclusive with the ground truth
is_mutually_exclusive <- function(pred_values, true_value) {
  mutually_exclusive_pairs <- list(
    c("aerobic", "anaerobic"),
    c("aerobic", "aerotolerant"),
    c("anaerobic", "facultatively anaerobic")
  )
  
  for (pair in mutually_exclusive_pairs) {
    if (true_value %in% pair && any(pred_values %in% pair)) {
      return(TRUE)
    }
  }
  return(FALSE)
}

# Function to calculate metrics for aerophilicity
calc_metrics_aerophilicity <- function(pred_match, true_match) {
  # Calculate balanced accuracy and precision
  balanced_accuracy <- mean(pred_match == true_match, na.rm = TRUE)
  precision <- sum(pred_match & true_match) / sum(pred_match, na.rm = TRUE)
  
  return(list(balanced_accuracy = balanced_accuracy, precision = precision))
}

normalize_column <- function(column, output_values, search_terms) {
  # Convert the column to character type
  column <- as.character(column)
  
  # Create a named list of search terms for each output value
  search_list <- setNames(as.list(search_terms), output_values)
  
  # Function to check if a value matches any search term within an output value
  match_search_terms <- function(value, search_terms) {
    any(sapply(search_terms, function(term) grepl(term, value, ignore.case = TRUE)))
  }
  
  # Normalize the column values based on search terms
  normalized_column <- sapply(column, function(x) {
    matches <- sapply(search_list, function(terms) match_search_terms(x, terms))
    
    if (sum(matches) == 1) {
      output_values[which(matches)]
    } else if (sum(matches) > 1) {
      NA_character_
    } else {
      NA_character_
    }
  })
  
  return(normalized_column)
}

# Function to convert string columns to logical while preserving NAs
convert_to_logical <- function(column) {
  if (is.character(column)) {
    column <- ifelse(column == "TRUE", TRUE,
                     ifelse(column == "FALSE", FALSE, NA))
  }
  return(column)
}

# Function to calculate balanced accuracy and precision for a single class
calc_metrics <- function(pred_col, true_col) {
  # Remove rows with NA values
  valid_rows <- complete.cases(pred_col, true_col)
  pred_col <- pred_col[valid_rows]
  true_col <- true_col[valid_rows]
  
  # Check the number of unique levels in pred_col and true_col
  pred_levels <- unique(pred_col)
  true_levels <- unique(true_col)
  
  if (length(pred_levels) < 2 || length(true_levels) < 2) {
    return(list(balanced_accuracy = NA, precision = NA))
  }
  
  # Convert to factors with combined levels
  levels_combined <- union(levels(factor(pred_col)), levels(factor(true_col)))
  pred_col <- factor(pred_col, levels = levels_combined)
  true_col <- factor(true_col, levels = levels_combined)
  
  # Calculate confusion matrix
  conf_matrix <- confusionMatrix(pred_col, true_col)
  
  # Calculate balanced accuracy
  if (is.matrix(conf_matrix$byClass)) {
    balanced_accuracy <- mean(conf_matrix$byClass[,"Balanced Accuracy"], na.rm = TRUE)
    precision <- mean(conf_matrix$byClass[,"Precision"], na.rm = TRUE)
  } else {
    balanced_accuracy <- conf_matrix$byClass["Balanced Accuracy"]
    precision <- conf_matrix$byClass["Precision"]
  }
  
  return(list(balanced_accuracy = balanced_accuracy, precision = precision))
}


# Define the color palette
color_palette <- c(
  "openai/gpt-3.5-turbo-0125" = "#10A37F",
  "openai/gpt-4o" = "#1A7F64",
  "openai/gpt-4" = "#0E5C4F",
  "meta-llama/llama-3-8b-instruct:nitro" = "#0668E1",
  "meta-llama/llama-3-70b-instruct:nitro" = "#0456BF",
  "perplexity/llama-3-sonar-small-32k-chat" = "#8A2BE2",
  "mistralai/mixtral-8x7b-instruct:nitro" = "#1E3A8A",
  "anthropic/claude-3-haiku:beta" = "#FF4D4D",
  "google/gemini-flash-1.5" = "#4285F4",
  "google/gemini-pro" = "#0F9D58",
  "openchat/openchat-7b" = "#FFA500",
  "google/gemma-7b-it" = "#F4B400",
  "anthropic/claude-3.5-sonnet" = "#CC0000",
  "google/palm-2-chat-bison-32k" = "#DB4437",
  "mistralai/mistral-7b-instruct" = "#172554",
  "google/gemini-pro-1.5" = "#4285F4",
  "microsoft/wizardlm-2-8x22b" = "#00A4EF",
  "microsoft/phi-3-mini-128k-instruct" = "#0078D4"
)



# Function to process a single file
process_file <- function(file_path) {
  pred <- read.csv(file_path, sep = ";", header = TRUE)
  
  # Normalize columns as in the original script
  pred$gram_staining <- normalize_column(
    pred$gram_staining,
    c("gram stain positive", "gram stain negative", "gram stain variable"),
    list("pos", "neg", "variable")
  )
  
  pred$motility <- normalize_column(
    pred$motility,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$extreme_environment_tolerance <- normalize_column(
    pred$extreme_environment_tolerance,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$biofilm_formation <- normalize_column(
    pred$biofilm_formation,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$animal_pathogenicity <- normalize_column(
    pred$animal_pathogenicity,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$biosafety_level <- normalize_column(
    pred$biosafety_level,
    c("biosafety level 1", "biosafety level 2", "biosafety level 3"),
    list("1", "2", "3")
  )
  
  pred$health_association <- normalize_column(
    pred$health_association,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$host_association <- normalize_column(
    pred$host_association,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$plant_pathogenicity <- normalize_column(
    pred$plant_pathogenicity,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$spore_formation <- normalize_column(
    pred$spore_formation,
    c("TRUE", "FALSE"),
    list("true", "false")
  )
  
  pred$hemolysis <- normalize_column(
    pred$hemolysis,
    c("alpha", "beta", "gamma", "non-hemolytic"),
    list("alpha", "beta", "gamma", "non-hemolytic")
  )
  
  pred$cell_shape <- normalize_column(
    pred$cell_shape,
    c("bacillus", "coccus", "spirillum", "tail"),
    list("bacillus", "coccus", "spirillum", "tail")
  )
  
  return(pred)
}