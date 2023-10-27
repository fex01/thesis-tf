#!/bin/bash

# Function to display help message
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Mandatory options:"
  echo "  --test-folder       Example: /path/to/folder"
  echo "                      (The folder path to search in)"
  echo ""
  echo "Optional options:"
  echo "  --test-approach     Example: 4"
  echo "                      (Must be empty or a number between 1 and 6, e.g., 4 for 'ta4')"
  echo ""
  echo "Other options:"
  echo "  -h, --help          Show this help message and exit."
}

# Initialize variables
TEST_FOLDER=""
TEST_APPROACH=""

# Parse named arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      show_help
      exit 0
      ;;
    --test-folder)
      TEST_FOLDER="$2"
      shift
      shift
      ;;
    --test-approach)
      TEST_APPROACH="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate TEST_FOLDER
if [ ! -d "$TEST_FOLDER" ]; then
  echo "Error: TEST_FOLDER directory does not exist."
  exit 1
fi

# Validate TEST_APPROACH
if ! [[ $TEST_APPROACH =~ ^[1-6]?$ ]]; then
  echo "Error: TEST_CASE is neither empty nor a number between 1 and 6: $TEST_APPROACH"
  exit 1
fi

# Initialize an array to hold matching file names
declare -a matching_files

# Search for files matching the pattern and add them to the array
while IFS= read -r -d '' file; do
  matching_files+=("$file")
done < <(find "$TEST_FOLDER" -maxdepth 1 -type f -name "*_ta${TEST_APPROACH}*" -print0)

# Check if any matching files were found
if [ ${#matching_files[@]} -eq 0 ]; then
  echo "No matching files found."
  exit 1
fi

# Print out the array of matching files
for file in "${matching_files[@]}"; do
  echo "$file"
done
