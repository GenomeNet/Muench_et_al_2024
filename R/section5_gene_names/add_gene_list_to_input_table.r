# Will add a column `Gene_file` with the file path information to the gene list (located at `data/generated_data/gene_data/reformatted_gff_non_hyp`)


# import the ground truth table that only have FASTA file annoation but not for the GFF files/ gene lists 
truth <- read.csv("section5_gene_names/ground_truth.csv", sep = ",")

# Add Gff.file column, handling NA values
truth$Gff.file <- ifelse(is.na(truth$Fasta.file), 
                         NA, 
                         gsub("\\.fasta$", ".txt", truth$Fasta.file))


# Add new column to check if the file exists
truth$Gene_file <- sapply(truth$Gff.file, function(file) {
  if (is.na(file)) {
    return(NA)
  } else {
    file_path <- file.path("../data/generated_data/gene_data/reformatted_gff_non_hyp", file)
    return(file.exists(file_path))
  }
})

truth_wa <- truth[which(truth$Member.of.WA.subset == TRUE),]

# Add Gene_location, ensuring it's NA when Gff.file is NA
truth_wa$Gene_location <- ifelse(is.na(truth_wa$Gff.file), 
                                 NA, 
                                 file.path("../../data/generated_data/gene_data/reformatted_gff_non_hyp", truth_wa$Gff.file))

# Limit truth_wa to rows where Gene_location is not NA
truth_wa <- truth_wa[!is.na(truth_wa$Gene_location), ]

# Update the count of non-NA Gff.file entries
print(paste("Number of non-NA Gene_location entries:", nrow(truth_wa)))

# Update the check for file existence
print(table(file.exists(truth_wa$Gene_location)))

write.csv2(truth_wa, "section5_gene_names/ground_truth_wa_with_gene_list_information.csv", row.names = FALSE, quote = FALSE)



# Split the dataframe into chunks of maximum 500 samples
chunk_size <- 500
num_chunks <- ceiling(nrow(truth_wa) / chunk_size)

for (i in 1:num_chunks) {
  start_idx <- (i - 1) * chunk_size + 1
  end_idx <- min(i * chunk_size, nrow(truth_wa))
  
  chunk <- truth_wa[start_idx:end_idx, ]
  
  # Create the output filename
  output_file <- sprintf("section5_gene_names/ground_truth_wa_with_gene_list_information_part%d.csv", i)
  
  # Write the chunk to a CSV file
  write.csv2(chunk, output_file, row.names = FALSE, quote = FALSE)
  
  print(paste("Saved", output_file, "with", nrow(chunk), "samples"))
}

print(paste("Total number of files created:", num_chunks))