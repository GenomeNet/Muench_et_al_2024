import json
import pandas as pd
import os

def format_jsonl_to_csv(input_dir, csv_file):
    all_data = []
    
    for filename in os.listdir(input_dir):
        if filename.endswith('.jsonl'):
            jsonl_file = os.path.join(input_dir, filename)
            with open(jsonl_file, 'r') as file:
                for line in file:
                    try:
                        entry = json.loads(line)
                        custom_id = entry['custom_id']
                        response = entry['response']['body']['choices'][0]['message']['content']
                        predictions = json.loads(response.strip('`json'))
                        
                        # Format custom_id with whitespace
                        predictions['custom_id'] = custom_id.replace('request-', '').replace('_', ' ')
                        
                        all_data.append(predictions)
                    except json.JSONDecodeError:
                        continue
                    except KeyError:
                        continue

    df = pd.DataFrame(all_data)
    
    # Rename 'custom_id' to 'Binomial name'
    df = df.rename(columns={'custom_id': 'Binomial name'})
    
    # Define the desired column order
    desired_column_order = [
        'Binomial name', 'Motility', 'Gram staining', 'Aerophilicity',
        'Extreme environment tolerance', 'Biofilm formation', 'Animal pathogenicity',
        'Biosafety level', 'Health association', 'Host association',
        'Plant pathogenicity', 'Spore formation', 'Hemolysis', 'Cell shape'
    ]
    
    # Rename columns
    column_mapping = {
        'gram_staining': 'Gram staining',
        'aerophilicity': 'Aerophilicity',
        'extreme_environment_tolerance': 'Extreme environment tolerance',
        'biofilm_formation': 'Biofilm formation',
        'animal_pathogenicity': 'Animal pathogenicity',
        'biosafety_level': 'Biosafety level',
        'health_association': 'Health association',
        'host_association': 'Host association',
        'plant_pathogenicity': 'Plant pathogenicity',
        'spore_formation': 'Spore formation',
        'cell_shape': 'Cell shape'
    }
    df = df.rename(columns=column_mapping)
    
    # Add missing columns with NaN values
    for col in desired_column_order:
        if col not in df.columns:
            df[col] = pd.NA
    
    # Reorder columns, including only those that exist
    new_column_order = [col for col in desired_column_order if col in df.columns]
    df = df[new_column_order]
    
    # Convert aerophilicity list to string
    if 'Aerophilicity' in df.columns:
        df['Aerophilicity'] = df['Aerophilicity'].apply(lambda x: ', '.join(x) if isinstance(x, list) else x)

    # Save to CSV
    df.to_csv(csv_file, index=False)
    print(f"Data from all JSONL files has been saved to {csv_file}")

# Usage
input_dir = 'batch_results'
csv_file = 'batch_results_csv/formatted_output.csv'

# Ensure the output directory exists
os.makedirs(os.path.dirname(csv_file), exist_ok=True)

format_jsonl_to_csv(input_dir, csv_file)