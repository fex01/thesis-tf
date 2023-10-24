import os
import json

# Constants
MODULE_NAME = "vpc"
MODULE_VERSION = "5.1.2"

def test_dc3_tc1_ta4():
    """
    Testing for dependency defects.

    Checks if the module named MODULE_NAME is locally available in version MODULE_VERSION.
    """

    # Check execution context
    if '.terraform' not in os.listdir('.'):
        current_path = os.getcwd()
        raise Exception(
            f"The test expects to be run in the context of the Terraform "
            f"configuration folder. Current execution context is {current_path}."
        )
    
    # Construct the directory path based on the MODULE_NAME
    dir_path = f"./.terraform/modules/{MODULE_NAME}"
    assert os.path.isdir(dir_path), f"Module '{MODULE_NAME}' not locally available at '{dir_path}'."

    # Parse module.json file and check for the MODULE_NAME and MODULE_VERSION
    json_path = "./.terraform/modules/modules.json"
    assert os.path.isfile(json_path), f"Expected JSON file '{json_path}' to exist, but it does not."

    with open(json_path, "r") as f:
        data = json.load(f)

    found = False
    for module in data["Modules"]:
        if module["Key"] == MODULE_NAME:
            found = True
            assert module["Version"] == MODULE_VERSION, f"Expected {MODULE_NAME} {MODULE_VERSION}, but found {module['Version']}"
            break

    assert found, f"{MODULE_NAME} module not found in modules.json"
