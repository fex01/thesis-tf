#!/usr/bin/env python3

import json
import argparse
import sys
import os

def calculate_costs(infracost_json, runtime, split_by):
    if not infracost_json or not os.path.exists(infracost_json) or not os.path.isfile(infracost_json):
        print(f"Error: File '{infracost_json}' does not exist or is not readable.")
        sys.exit(1)

    try:
        with open(infracost_json, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError:
        print(f"Error: '{infracost_json}' is not a valid JSON file")
        sys.exit(1)

    if 'projects' not in data or len(data['projects']) != 1:
        print("Error: The JSON does not contain exactly one 'projects' entry")
        sys.exit(1)

    resources = data['projects'][0]['breakdown']['resources']

    fine_granular_resource_types = ["aws_db_instance", "aws_eks_cluster", "aws_eks_node_group"]
    fixed_hourly_costs_resource_types = ["aws_vpc_endpoint", "aws_kms_key"]
    traffic_based_resource_types = ["aws_cloudwatch_log_group"]

    hourly_costs_fine_granular = 0
    hourly_costs_fixed = 0

    for resource in resources:
        resourceType = resource['resourceType']

        if (resourceType not in fine_granular_resource_types 
            and resourceType not in fixed_hourly_costs_resource_types 
            and resourceType not in traffic_based_resource_types):
            print(f"Error: '{resourceType}' is not one of the classified resource types.")
            print("As such, it is unknown if costs have to be calculated fine granular or per started hour.")
            print(f"Known fine granular resource types: {', '.join(fine_granular_resource_types)}")
            print(f"Known fixed hourly costs resource types: {', '.join(fixed_hourly_costs_resource_types)}")
            print(f"Known traffic based resource types: {', '.join(traffic_based_resource_types)}")
            sys.exit(1)
        elif resourceType in traffic_based_resource_types:
            # Skip traffic based resource types
            continue
        if 'hourlyCost' not in resource:
            print(f"Error: 'hourlyCost' not found in resource of type {resourceType}.")
            sys.exit(1)
        else: 
            hourlyCost = float(resource['hourlyCost'])

        if resourceType in fine_granular_resource_types:
            hourly_costs_fine_granular += hourlyCost
        elif resourceType in fixed_hourly_costs_resource_types:
            hourly_costs_fixed += hourlyCost

    # Calculate costs
    total_hourly_costs_fine_granular = hourly_costs_fine_granular * (runtime / 3600.0)
    total_hourly_costs_fixed = (hourly_costs_fixed * ((runtime // 3600) + 1)) / split_by
    total_costs = total_hourly_costs_fine_granular + total_hourly_costs_fixed

    return round(total_costs, 5)

def main():
    parser = argparse.ArgumentParser(
        description = (
          "This script calculates the runtime cost based on the given runtime in seconds. "
          "It extracts the cost components from the Infracost breakdown and computes the "
          "total cost, which is then returned, rounded to 5 decimal places. "
          "When multiple test cases are run for the same deployment, the '--split-by' "
          "argument can be used to distribute the costs proportionally across these test cases."
        )
    )
    parser.add_argument('--infracost-json', required=True, help='Path to infracost JSON file.')
    parser.add_argument('--runtime', required=True, help='Runtime in seconds.')
    parser.add_argument('--split-by', type=int, default=1, help='Divider for specific cost components. Default is 1.')
    args = parser.parse_args()

    # Validate that runtime is not empty
    if not args.runtime:
        print("Error: RUNTIME is empty.")
        sys.exit(1)

    # Validate that runtime contains an integer value
    try:
        runtime_val = int(args.runtime)
    except ValueError:
        print("Error: RUNTIME does not contain a valid integer value.")
        sys.exit(1)

    costs = calculate_costs(args.infracost_json, runtime_val, args.split_by)
    print(costs)

if __name__ == "__main__":
    main()
