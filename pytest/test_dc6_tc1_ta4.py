import os
import re
import subprocess

PLAN_FILE = "plan.tfplan"
PASSWORD_PATTERN = r'\s*\+\s*password\s+=\s'
SENSITIVE_PATTERN = "(sensitive value)"

def test_dc6_tc1_ta4():
    """
    Testing for security defects.

    This test aims to confirm that attributes named 'password' in the Terraform plan 
    output are flagged as sensitive to ensure security. It accomplishes this by:
    1. Parsing the Terraform plan output to identify resources that contain an 
       attribute named 'password'.
    2. Confirming that the value of the 'password' attribute is flagged as 
       "(sensitive value)" to prevent the exposure of sensitive information.
    """

    # Check execution context
    if '.terraform' not in os.listdir('.'):
        current_path = os.getcwd()
        raise Exception(
            f"The test expects to be run in the context of the Terraform "
            f"configuration folder. Current execution context is {current_path}."
        )
    
    # Check if plan file exists in the current directory
    if not os.path.isfile(PLAN_FILE):
        raise Exception(
            f"Expected plan file {PLAN_FILE} to exist in the current "
            f"directory, but it does not."
        )
    
    # Initialize variables to store resource type and name
    resource_type = None
    resource_name = None
    
    # Convert the binary plan file without `-json` option to keep sensitive values redacted
    #   https://www.terraform.io/docs/commands/show.html: When using the -json command-line 
    #   flag, any sensitive values in Terraform state will be displayed in plain text
    result = subprocess.run(
        ["terraform", "show", "-no-color", PLAN_FILE], 
        stdout=subprocess.PIPE, check=True, text=True
    )
    content = result.stdout

    # Parse the content line by line
    for line in content.split('\n'):
        # Match and save resource type and name
        match_resource = re.match(
            r'\s*\+\s*resource\s+"([^"]+)"\s+"([^"]+)"\s+\{', 
            line
        )
        if match_resource:
            resource_type, resource_name = match_resource.groups()

        # Match password attribute using predefined pattern
        match_password = re.match(PASSWORD_PATTERN, line)
        if match_password:
            assert SENSITIVE_PATTERN in line, (
                f"The password attribute in resource {resource_type} "
                f"'{resource_name}' should be flagged as sensitive "
                "to conceal its value."
            )
