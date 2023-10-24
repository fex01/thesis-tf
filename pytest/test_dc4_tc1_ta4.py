import os
import re

def test_dc4_tc1_ta4():
    """
    Testing for documentation defects.
    
    This test performs two primary checks:
    1. Verifies that the project has a readme file (readme.md) 
       in the current directory.
    2. Ensures that the readme file contains a section titled 
       'Acknowledgment' to express gratitude for both direct 
       and indirect contributions to the project.
    """
    
    # Check for 'readme.md' in the current folder
    files = os.listdir('.')
    assert any(fname.lower() == 'readme.md' for fname in files), \
        ("A readme.md file should exist in the current directory "
         "as part of this project's documentation.")
    
    # Open and read 'readme.md'
    with open('readme.md', 'r', encoding='utf-8') as f:
        content = f.read()

    # Search for 'Acknowledgment' section
    assert re.search(r'##\s*Acknowledgment', content, re.IGNORECASE), \
        ("The readme.md file should contain a section titled "
         "'Acknowledgment' to appreciate both direct and indirect "
         "contributions to the project.")
