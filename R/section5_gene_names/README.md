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

## Data processing

- The file `gene_based.r` is processing the microbeLLM output `data/generated_data/gene_data/microbeLLM_output_only_genes.csv` and compares it with the bugphyzz ground truth infomration to calculated balanced accuracy values for the phenotypes. 

## Figures
- the code to reproduce Figure 4C is available at `figure_4c.r`
- the code to reproduce Figure 4D is available at `figure_4d.r`