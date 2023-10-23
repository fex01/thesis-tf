import os
import re
import subprocess

def test_dc6_tc1_ta4():
    # Initialize variables to store resource type and name
    resource_type = None
    resource_name = None
    
    # Convert the binary plan file without `-json` option to keep sensitive values redacted
    #   https://www.terraform.io/docs/commands/show.html: When using the -json command-line 
    #   flag, any sensitive values in Terraform state will be displayed in plain text
    result = subprocess.run(
        ["terraform", "show", "-no-color", "plan.tfplan"], 
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

        # Match password attribute
        match_password = re.match(r'\s*\+\s*password\s+=\s', line)
        if match_password:
            assert "(sensitive value)" in line, (
                f"The variable 'db_pwd' in resource {resource_type} "
                f"'{resource_name}' should be flagged as sensitive "
                "to hide its value where supported."
            )
