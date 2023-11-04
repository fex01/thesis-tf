import os
import re
import subprocess

PLAN_TXT = "plan.txt"
PLAN_TFPLAN = "plan.tfplan"
PASSWORD_PATTERN = r'\s*\+\s*password\s+=\s'
SENSITIVE_PATTERN = "(sensitive value)"

def test_tc13_dc6_ta4():
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

    # Determine the source of the Terraform plan content
    if os.path.isfile(PLAN_TXT):
        with open(PLAN_TXT, 'r') as f:
            content = f.read()
    else:
        if not os.path.isfile(PLAN_TFPLAN):
            raise Exception(f"{PLAN_TFPLAN} file does not exist.")
        
        # Check that 'terraform' executable is available
        if subprocess.run(["which", "terraform"], stdout=subprocess.PIPE).returncode != 0:
            raise Exception("Terraform executable not found.")
        
        result = subprocess.run(
            ["terraform", "show", "-no-color", PLAN_TFPLAN], 
            stdout=subprocess.PIPE, check=True, text=True
        )
        content = result.stdout
    
    # Initialize variables to store resource type and name
    resource_type = None
    resource_name = None

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
