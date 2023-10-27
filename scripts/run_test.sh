#!/bin/bash

# Function to display help message
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  
  echo "Mandatory options:"
  echo "  --build-number      Example: 1-999"
  echo "                      (Must be a number)"
  echo "  --test-command      Example: 'terraform test -filter=path/to/test'"
  echo "                      (Cannot be empty)"
  echo "  --csv-file          Example: timings.csv"
  echo "                      (Must not be empty)"
  echo "                      (Must end with .csv or .CSV)"
  echo "                      (If file doesn't exist, a new one will be created)"
  echo "                      (Otherwise, will append to existing file)"
  echo ""
  
  echo "Optional options:"
  echo "  --defect-category   Example: 2"
  echo "                      (Must be a number between 1 and 8, e.g., 2 for 'dc2')"
  echo "                      (Optional for TAs supporting testing of individual test cases, will be parsed from '--test-command')"
  echo "                      (Mandatory for TAs not supporting testing of individual test cases (TA1, TA2) as it can not be parsed)"
  echo "  --test-case         Example: 1"
  echo "                      (Must be a number (-> tc1), empty, or 'NA',)"
  echo "                      (Empty defaults to 'NA' for 'not applicable')"
  echo "  --test-approach     Example: 4"
  echo "                      (Must be a number between 1 and 6, e.g., 4 for 'ta4')"
  echo "                      (Optional for TAs supporting testing of individual test cases, will be parsed from '--test-command')"
  echo "                      (Mandatory for TAs not supporting testing of individual test cases (TA1, TA2) as it can not be parsed)"
  echo "  --test-tool         Example: terraform test"
  echo "                      (If not provided, the first part of TEST_COMMAND is used)"
  echo ""
  
  echo "Other options:"
  echo "  -h, --help          Show this help message and exit."
}

# Initialize variables
BUILD_NUMBER=""
DEFECT_CATEGORY=""
TEST_CASE="NA"
TEST_APPROACH=""
TEST_TOOL=""
TEST_COMMAND=""
CSV_FILE=""

# Parse named arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      show_help
      exit 0
      ;;
    --build-number)
      BUILD_NUMBER="$2"
      shift
      shift
      ;;
    --defect-category)
      DEFECT_CATEGORY="$2"
      shift
      shift
      ;;
    --test-case)
      TEST_CASE="$2"
      shift
      shift
      ;;
    --test-approach)
      TEST_APPROACH="$2"
      shift
      shift
      ;;
    --test-tool)
      TEST_TOOL="$2"
      shift
      shift
      ;;
    --test-command)
      TEST_COMMAND="$2"
      shift
      shift
      ;;
    --csv-file)
      CSV_FILE="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate BUILD_NUMBER
if ! [[ $BUILD_NUMBER =~ ^[0-9]+$ ]]; then
  echo "Error: BUILD_NUMBER is not a number: $BUILD_NUMBER"
  exit 1
fi

# Validate CSV_FILE
if [[ -z "$CSV_FILE" ]]; then
  echo "Error: CSV_FILE must not be empty."
  exit 1
elif ! [[ ${CSV_FILE,,} =~ \.csv$ ]]; then
  echo "Error: CSV_FILE must end with .csv or .CSV."
  exit 1
fi
if [[ ! -f $CSV_FILE ]]; then
  echo "Creating new CSV file: $CSV_FILE"
  echo 'build,defect_category,test_case,test_approach,test_tool,runtime(millis)' > $CSV_FILE
fi

# Validate that essential variables are set
missing_vars=()
if [[ -z $TEST_COMMAND ]]; then
  missing_vars+=("TEST_COMMAND")
fi

if [[ ${#missing_vars[@]} -ne 0 ]]; then
  echo "Error: The following essential input variables are missing: ${missing_vars[@]}"
  exit 1
fi

# TEST_TOOL is either set separatly or - if empty - the first part of TEST_COMMAND
if [[ -z $TEST_TOOL ]]; then
  TEST_TOOL=${TEST_COMMAND%% -*}
fi

# If DEFECT_CATEGORY and TEST_APPROACH are already provided, there's no need to extract them from the test command.
# This is particularly important for test approaches that do not support individual test cases, such as TA1 and TA2.
if [[ -n $DEFECT_CATEGORY && -n $TEST_APPROACH ]]; then
  : # Do nothing
# Otherwise we try to extract DEFECT_CATEGORY, TEST_CASE and TEST_APPROACH from the test command.
elif [[ $TEST_COMMAND =~ dc([0-9]+)_tc([0-9]+)_ta([0-9]+) ]]; then
  DEFECT_CATEGORY="${BASH_REMATCH[1]}"
  TEST_CASE="${BASH_REMATCH[2]}"
  TEST_APPROACH="${BASH_REMATCH[3]}"
# If none of the above conditions are met, the file name does not match the expected pattern.
else
  echo "Error: File name does not match the expected pattern: $TEST_COMMAND"
  exit 1
fi

# Validate DEFECT_CATEGORY
if [[ $DEFECT_CATEGORY == 0 ]]; then DEFECT_CATEGORY="NA"; fi
if ! [[ $DEFECT_CATEGORY == "NA" || $DEFECT_CATEGORY =~ ^[1-8]$ ]]; then
  echo "Error: DEFECT_CATEGORY is not a number between 1 and 8: $DEFECT_CATEGORY"
  exit 1
fi

# Validate TEST_CASE
if ! [[ $TEST_CASE =~ ^[0-9]+$ || $TEST_CASE == "NA" ]]; then
  echo "Error: TEST_CASE is not a number, NA or empty: $TEST_CASE"
  exit 1
fi

# Validate TEST_APPROACH
if ! [[ $TEST_APPROACH =~ ^[1-6]$ ]]; then
  echo "Error: TEST_CASE is not a number between 1 and 6: $TEST_APPROACH"
  exit 1
fi


# ==========================
# End of Variable Validation
# ==========================

# Execution Starts Below
 
# Get start time
start_time=$(date +%s%3N)

# Execute the test command with filter
eval "$TEST_COMMAND"

# Check if the last command was successful
if [[ $? -ne 0 ]]; then
  echo "Error: The test command \"$TEST_COMMAND\" failed."
  exit $?
fi

# Get end time
end_time=$(date +%s%3N)

# Calculate runtime
runtime=$(($end_time - $start_time))

# Prepare the CSV entry
csv_entry="$BUILD_NUMBER,$DEFECT_CATEGORY,$TEST_CASE,$TEST_APPROACH,$TEST_TOOL,$runtime"

# Append the CSV entry to the OUTPUT_FILE
echo "$csv_entry" >> $CSV_FILE
