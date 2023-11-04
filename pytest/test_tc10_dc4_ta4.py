import os
import re

def test_tc10_dc4_ta4():
    """
    Testing for documentation defects.
    
    This test performs two primary checks:
    1. Verifies that the project has a readme file (readme.md) 
       in the current directory.
    2. Ensures that the readme file contains a section titled 
       'Acknowledgment' to express gratitude for both direct 
       and indirect contributions to the project.
    """

    # Check execution context
    if '.terraform' not in os.listdir('.'):
        current_path = os.getcwd()
        raise Exception(
            f"The test expects to be run in the context of the Terraform "
            f"configuration folder. Current execution context is {current_path}."
        )
    
    # Check for 'readme.md' in the current folder
    files = os.listdir('.')
    # Find the actual filename that matches 'readme.md' regardless of case
    readme_file = next((f for f in files if f.lower() == 'readme.md'), None)
    # Check if a matching file was found
    if readme_file is None: \
        assert False, ("A readme.md file should exist in the current directory "
         "as part of this project's documentation.")
    
    # Open and read 'readme.md'
    with open(readme_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Search for 'Acknowledgment' section
    assert re.search(r'##\s*Acknowledgment', content, re.IGNORECASE), \
        ("The readme.md file should contain a section titled "
         "'Acknowledgment' to appreciate both direct and indirect "
         "contributions to the project.")
