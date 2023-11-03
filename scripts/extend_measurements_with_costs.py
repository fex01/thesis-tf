#!/usr/bin/env python3

import csv
import subprocess
import argparse
import sys
import os

def calculate_costs(infracost_json, runtime, split_by=1):
    print(f"   calculate_costs(infracost_json='{infracost_json}', runtime={runtime}, split_by={split_by})")
    result = subprocess.run(['python3', 'scripts/calculate_costs.py', '--infracost-json', infracost_json, '--runtime', str(runtime), '--split-by', str(split_by)], capture_output=True, text=True)
    return float(result.stdout.strip())

def process_csv(input_file, infracost_json):
    # Read the CSV file into memory
    with open(input_file, 'r') as f:
        reader = csv.reader(f)
        rows = list(reader)

    # Validate that the CSV contains the expected header row
    expected_header = "build,defect_category,test_case,test_approach,test_tool,runtime(seconds),costs($)"
    actual_header = rows[0]
    header_string = ",".join(actual_header).strip()
    
    if header_string.lower() != expected_header.lower():
        print(f"Error: The header in '{input_file}' does not match the expected header '{expected_header}'")
        sys.exit(1)

    i = 1  # Start with the first row after the header
    while i < len(rows):
        row = rows[i]

        # If the row contains 'terraform apply' in the 5th field
        if row[4] == 'terraform apply':
            start = i
            # find the matching 'terraform destroy' line
            while i < len(rows) and rows[i][4] != 'terraform destroy':
                i += 1
            end = i

            split_by = end - start
            shared_runtime = (int(rows[start][5]) + int(rows[end][5])) // split_by

            rows[start][6] = 'NA'
            rows[end][6] = 'NA'
            
            for j in range(start+1, end):
                if rows[j][3] == '5' or rows[j][3] == '6':
                    runtime = int(rows[j][5]) + shared_runtime
                    print(f"row: {rows[j]}")
                    cost = calculate_costs(infracost_json, runtime, split_by)
                    print(f"cost: {cost}")
                    rows[j][6] = str(cost)
        else:
            if row[3] == '5' or row[3] == '6':
                print(f"row: {rows[i]}")
                cost = calculate_costs(infracost_json, int(row[5]))
                print(f"cost: {cost}")
                row[6] = str(cost)
        i += 1

    # Write the modified rows back to the same CSV file
    with open(input_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser(
        description = (
          "This script processes an existing measurements.csv file, extending it by computing and appending cloud provider costs "
          "associated with each dynamic test case's runtime. By leveraging information from the Infracost breakdown, "
          "the script not only factors in individual test case costs, but also shared deployment costs, distributing them "
          "equitably among related test cases within the dataset."
        )
    )
    parser.add_argument('--infracost-json', required=True, help='Path to Infracost JSON file used for cost calculations.')
    parser.add_argument('--measurements-csv', required=True, help='Path to the measurements csv-file to be extended with calculated costs.')
    args = parser.parse_args()

    # Validate existence of Infracost JSON file
    if not os.path.exists(args.infracost_json) or not os.path.isfile(args.infracost_json):
        print(f"Error: File '{args.infracost_json}' does not exist or is not readable.")
        sys.exit(1)

    # Validate existence of csv file
    if not os.path.exists(args.measurements_csv) or not os.path.isfile(args.measurements_csv):
        print(f"Error: File '{args.measurements_csv}' does not exist or is not readable.")
        sys.exit(1)

    # Process the csv file
    process_csv(args.measurements_csv, args.infracost_json)

if __name__ == "__main__":
    main()

