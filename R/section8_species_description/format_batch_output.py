import json
import orjson
import pandas as pd
import os
import logging
import re

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def clean_json_string(json_str):
    """
    Removes invalid control characters from a JSON string.
    Allows common whitespace characters like \n and \t.
    """
    # Remove control characters except for \n (newline) and \t (tab)
    cleaned_str = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', json_str)
    return cleaned_str

def extract_json_content(response):
    """
    Extracts the JSON content from the response string.
    Removes Markdown code block markers if present.
    """
    prefix = '```json\n'
    suffix = '\n```'
    if response.startswith(prefix) and response.endswith(suffix):
        # Remove the prefix and suffix
        json_str = response[len(prefix):-len(suffix)].strip()
    else:
        # Handle cases where the format is unexpected
        json_str = response.strip()
    return json_str

def parse_outer_json(line):
    """
    Parses the outer JSON using orjson for performance.
    """
    try:
        return orjson.loads(line)
    except orjson.JSONDecodeError as e:
        logging.warning(f"orjson.JSONDecodeError while parsing outer JSON: {e}")
        return None

def parse_inner_json(json_str):
    """
    Parses the inner JSON using Python's json module with strict=False.
    """
    try:
        return json.loads(json_str, strict=False)
    except json.JSONDecodeError as e:
        logging.warning(f"json.JSONDecodeError while parsing inner JSON: {e}")
        return None

def format_jsonl_to_csv(input_dir, csv_file, problematic_log='problematic_entries.log'):
    all_data = []
    total_entries = 0
    skipped_entries = 0

    with open(problematic_log, 'w', encoding='utf-8') as log_file:
        for filename in os.listdir(input_dir):
            if filename.endswith('.jsonl'):
                jsonl_file = os.path.join(input_dir, filename)
                with open(jsonl_file, 'r', encoding='utf-8') as file:
                    for line_number, line in enumerate(file, start=1):
                        total_entries += 1
                        outer_json = parse_outer_json(line)
                        if not outer_json:
                            skipped_entries += 1
                            logging.warning(
                                f"Skipping line {line_number} in file {filename} due to outer JSON parsing error."
                            )
                            log_file.write(f"Filename: {filename}, Line: {line_number}\n")
                            log_file.write(f"Problematic Line: {line.strip()}\n\n")
                            continue
                        try:
                            custom_id = outer_json['custom_id']
                            response = outer_json['response']['body']['choices'][0]['message']['content']
                            
                            # Extract and clean the JSON string from content
                            json_str = extract_json_content(response)
                            json_str = clean_json_string(json_str)
                            
                            # Parse the cleaned JSON string using json.loads with strict=False
                            description_data = parse_inner_json(json_str)
                            if not description_data:
                                skipped_entries += 1
                                logging.warning(
                                    f"Skipping line {line_number} in file {filename} due to inner JSON parsing error."
                                )
                                log_file.write(f"Filename: {filename}, Line: {line_number}\n")
                                log_file.write(f"Problematic Line: {line.strip()}\n\n")
                                continue

                            # Extract the description
                            description = description_data.get('description', '')
                            description = description.replace('\n\n', ' ').replace('\n', ' ').replace('\t', ' ').strip()

                            # Extract the model used
                            model = outer_json['response']['body'].get('model', 'Unknown')

                            # Format custom_id with whitespace
                            binomial_name = custom_id.replace('request-', '').replace('_', ' ').strip()

                            all_data.append({
                                'Binomial name': binomial_name,
                                'Description': description,
                                'Model': model
                            })
                        except KeyError as e:
                            skipped_entries += 1
                            logging.warning(
                                f"KeyError in file {filename} at line {line_number}: {e}\nProblematic entry: {line.strip()}"
                            )
                            log_file.write(f"Filename: {filename}, Line: {line_number}\n")
                            log_file.write(f"Problematic Line: {line.strip()}\n\n")
                            continue

    # Create DataFrame and save to CSV
    df = pd.DataFrame(all_data)
    columns = ['Binomial name', 'Description', 'Model']
    df = df[columns]
    df.to_csv(csv_file, index=False)
    logging.info(f"Processed {total_entries} entries.")
    logging.info(f"Skipped {skipped_entries} entries due to errors.")
    logging.info(f"Data from all JSONL files has been saved to {csv_file}")
    logging.info(f"Problematic entries have been logged to {problematic_log}")

# Usage
input_dir1 = 'batch_output_4o'
csv_file1 = 'formatted_output_description_4o_new.csv'

# Ensure the output directory exists only if a directory path is provided
output_dir = os.path.dirname(csv_file1)
if output_dir:
    os.makedirs(output_dir, exist_ok=True)

# Process the input directory with problematic entry logging
format_jsonl_to_csv(input_dir1, csv_file1, problematic_log='problematic_entries.log')

logging.info("Input directories have been processed and saved to the CSV file.")