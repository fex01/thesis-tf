#!/bin/sh

# Function to display help message
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo " "
  echo "Mandatory options:"
  echo "  --build-number      Example: 1-999"
  echo "                      (Must be a number)"
  echo "  --test-folder       Example: tests"
  echo "                      (Must be a valid folder containing test files compatible with"
  echo "                         the '--test-command')"
  echo "  --test-command      Example: 'terraform test -filter=path/to/test'"
  echo "                      (Cannot be empty)"
  echo "  --csv-file          Example: timings.csv"
  echo "                      (Must not be empty)"
  echo "                      (Must end with .csv or .CSV)"
  echo "                      (If file doesn't exist, a new one will be created)"
  echo "                      (Otherwise, will append to existing file)"
  echo " "
  echo "Optional options:"
  echo "  --test-approach     Example: 4"
  echo "                      (Must be a number between 1 and 6, e.g., 4 for 'ta4')"
  echo "                      (Optional - can be provided if a folder contains test cases"
  echo "                         for multiple test approaches)"
  echo " "
  echo "Other options:"
  echo "  -h, --help        Show this help message and exit."
}



# Initialize variables
BUILD_NUMBER=""
TEST_FOLDER=""
TEST_APPROACH=""
TEST_COMMAND=""
CSV_FILE=""

# Parse named arguments
while [ "$#" -gt 0 ]; do
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

# Validate TEST_FOLDER
if [ ! -d "$TEST_FOLDER" ]; then
  echo "Error: TEST_FOLDER directory does not exist in the current path: $TEST_FOLDER"
  exit 1
fi

# Validate TEST_COMMAND
if [ -z "$TEST_COMMAND" ]; then
  echo "Error: The essential input variable TEST_COMMAND is missing"
  exit 1
fi

# Get applicable test file names into an array
test_files=$(scripts/get_test_file_names.sh \
              --test-folder "$TEST_FOLDER" \
              --test-approach "$TEST_APPROACH")

# initialize exit code
exit_code=0

# Iterate over the lines in test_files
IFS='
'
for test_file in $test_files; do
  sh scripts/run_test.sh \
    --test-command "${TEST_COMMAND}${test_file}" \
    --csv-file "$CSV_FILE" \
    --build-number "$BUILD_NUMBER"
  exit_code_tmp=$?
  if [ $exit_code_tmp -ne 0 ]; then
    # save non-zero exit code, but finish all tests in the group
    exit_code=$exit_code_tmp
  fi
done
unset IFS

# if any test failed, exit with the last exit code
if [ $exit_code -ne 0 ]; then
  exit $exit_code
fi
