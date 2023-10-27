#!/bin/sh

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
while [ $# -gt 0 ]; do
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
if [ -z "$BUILD_NUMBER" ] || ! echo "$BUILD_NUMBER" | grep -Eq '^[0-9]+$'; then
  echo "Error: BUILD_NUMBER is not a number: $BUILD_NUMBER"
  exit 1
fi

# Validate CSV_FILE
if [ -z "$CSV_FILE" ]; then
  echo "Error: CSV_FILE must not be empty."
  exit 1
elif ! echo "$CSV_FILE" | tr '[:upper:]' '[:lower:]' | grep -Eq '\.csv$'; then
  echo "Error: CSV_FILE must end with .csv or .CSV."
  exit 1
fi
if [ ! -f $CSV_FILE ]; then
  echo "Creating new CSV file: $CSV_FILE"
  echo 'build,defect_category,test_case,test_approach,test_tool,runtime(millis)' > $CSV_FILE
fi

# Validate TEST_COMMAND
if [ -z "$TEST_COMMAND" ]; then
  echo "Error: TEST_COMMAND is missing."
  exit 1
fi


# TEST_TOOL is either set separatly or - if empty - the first part of TEST_COMMAND
if [ -z $TEST_TOOL ]; then
  TEST_TOOL=$(echo "$TEST_COMMAND" | awk -F' -' '{print $1}')
fi

# If DEFECT_CATEGORY and TEST_APPROACH are already provided, there's no need to extract them from the test command.
# This is particularly important for test approaches that do not support individual test cases, such as TA1 and TA2.
if [ -n "$DEFECT_CATEGORY" ] && [ -n "$TEST_APPROACH" ]; then
  : # Do nothing
else
  # Otherwise we try to extract DEFECT_CATEGORY, TEST_CASE and TEST_APPROACH from the test command.
  match=$(echo "$TEST_COMMAND" | grep -o -E 'dc([0-9]+)_tc([0-9]+)_ta([0-9]+)')
  if [ -n "$match" ]; then
    DEFECT_CATEGORY=$(echo "$match" | sed -E 's/dc([0-9]+)_tc([0-9]+)_ta([0-9]+)/\1/')
    TEST_CASE=$(echo "$match" | sed -E 's/dc([0-9]+)_tc([0-9]+)_ta([0-9]+)/\2/')
    TEST_APPROACH=$(echo "$match" | sed -E 's/dc([0-9]+)_tc([0-9]+)_ta([0-9]+)/\3/')
  # If none of the above conditions are met, the file name does not match the expected pattern.
  else
    echo "Error: File name does not match the expected pattern: $TEST_COMMAND"
    exit 1
  fi
fi

# Validate DEFECT_CATEGORY
if [ "$DEFECT_CATEGORY" -eq 0 ]; then DEFECT_CATEGORY="NA"; fi
if ! echo "$DEFECT_CATEGORY" | grep -Eq '^(NA|[1-8])$'; then
  echo "Error: DEFECT_CATEGORY is not a number between 1 and 8: $DEFECT_CATEGORY"
  exit 1
fi

# Validate TEST_CASE
if ! echo "$TEST_CASE" | grep -Eq '^(NA|[0-9]+)$'; then
  echo "Error: TEST_CASE is not a number, NA or empty: $TEST_CASE"
  exit 1
fi

# Validate TEST_APPROACH
if ! echo "$TEST_APPROACH" | grep -Eq '^[1-6]$'; then
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
if [ $? -ne 0 ]; then
  echo "Error: The test command \"$TEST_COMMAND\" failed."
  exit $?
fi

# Get end time
end_time=$(date +%s%3N)

# Calculate runtime
runtime=$(expr $end_time - $start_time)

# Prepare the CSV entry
csv_entry="$BUILD_NUMBER,$DEFECT_CATEGORY,$TEST_CASE,$TEST_APPROACH,$TEST_TOOL,$runtime"

# Append the CSV entry to the OUTPUT_FILE
echo "$csv_entry" >> $CSV_FILE
