## About
For each processed reference genome we generated GFF files using Prokka and reformatted the GFF file to generate a list of gene names. This lists are available at `data/gene_data/reformatted_gff_non_hyp``

To augment the predictions with these gene information we performed tests where we 
 - using only the gene-information as LLM input
 - using both, binomial name and gene lists as a LLM input

## microbeLLM

We used our tool microbeLLM https://github.com/GenomeNet/microbeLLM to generate the LLM output. For this analysis, the options `--use_genes` and `--gene_column` are relevant to control the incorporation of gene-lists to the LLM. Furthermore, we use further templates that have the ending (`_with_genes.txt`) and have tag `{gene_list}` in it that will be used to specify the location where the gene-list is added to the template.

For this, we added a column with the path information to the TXT file containing the gene list information using the script `add_gene_list_to_input_table.r` which produces `ground_truth_wa_with_gene_list_information.csv`. 

```
microbeLLM by_list  \
    --model gpt-4o-mini \
    --use_genes --gene_column Gene_location \
    --system_template templates/only_query_template_system_pred1.txt \
    --user_template  templates/only_query_template_user_pred1.txt \
    --input_file ground_truth_wa_with_gene_list_information_100.csv \
    --output microbeLLM_output_only_genes_batches_100.jsonl \
    --batchoutput
```

```
#!/bin/bash

# Loop through the 7 parts
for i in {1..7}
do
    echo "Processing part $i"
    
    microbeLLM by_list \
        --model gpt-4o-mini \
        --use_genes --gene_column Gene_location \
        --system_template templates/only_query_template_system_pred1.txt \
        --user_template  templates/only_query_template_user_pred1.txt \
        --input_file ground_truth_wa_with_gene_list_information_part${i}.csv \
        --output microbeLLM_output_only_genes_batches_part${i}.jsonl \
        --batchoutput

    echo "Finished processing part $i"
    echo "------------------------"
done

echo "All parts processed successfully"
```

- part1: `file-m6ejk6U61SETg0f4Deewskuy`
- part2: `file-JMk0ZwElFXwPIHrc6a89bTM6`
- part3: `file-n3E80oL1B1a04GZj72pwI9fI`
- part4: `file-m1oXhfhilfq9aTuSouJHiJV6`
- part5: `file-mLnMIaTW0jamKdrNWAq7NXXf`
- part6: `file-LVXJEAJmp6jvEDvEAt3qMCLs`
- part7: `file-OwUEXij4k0zsHkvytgCb3vCr`

Responses are written to `batch_results/`

Costs associated to this API calls were ~10€

now generate the csv version

```
python format_batch_output.py
```

which outputs `Data from all JSONL files has been saved to batch_results_csv/formatted_output.csv`

### Name-based run for comparison

```
microbeLLM by_list  \
    --model gpt-4o-mini \
    --system_template templates/only_query_template_system_pred1.txt \
    --user_template  templates/only_query_template_user_pred1.txt \
    --input_file ground_truth_wa_with_gene_list_information.csv \
    --output microbeLLM_output_binomial_names.jsonl \
    --batchoutput
``` 

output is saved to `batch_results_name`

and for knowlege groups

```
microbeLLM by_list  \
    --model gpt-4o-mini \
    --system_template templates/k_groups_system.txt \
    --user_template templates/k_groups_user.txt \
    --input_file ground_truth_wa_with_gene_list_information.csv \
    --output microbeLLM_output_binomial_names_k_groups.jsonl \
    --batchoutput
``` 

output is saved to `batch_results_kgroups`


## Data processing

The formatted predictions are available at `batch_results_csv/formatted_output.csv` while the ground truth information is available at `ground_truth.csv`. 

These needs to be compared to caluclate balanced accuracy scores per class, this can be done with the script `calc_metric.r`


