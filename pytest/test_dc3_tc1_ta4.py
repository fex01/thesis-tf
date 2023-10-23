import os
import json

def test_terraform_vpc_module():
    # Check if the directory exists
    dir_path = "./.terraform/modules/vpc"
    assert os.path.isdir(dir_path), f"Expected directory '{dir_path}' to exist, but it does not."

    # Parse module.json file and check the module version
    json_path = "./.terraform/modules/modules.json"
    assert os.path.isfile(json_path), f"Expected JSON file '{json_path}' to exist, but it does not."

    with open(json_path, "r") as f:
        data = json.load(f)

    found = False
    for module in data["Modules"]:
        if module["Key"] == "vpc":
            found = True
            assert module["Version"] == "5.1.2", f"Expected version 5.1.2, but found {module['Version']}"
            break

    assert found, "VPC module not found in modules.json"
