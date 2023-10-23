import os
import re

def test_dc4_tc1_ta4():
    # Check if readme.md exists in the current folder
    files = os.listdir('.')
    assert any(fname.lower() == 'readme.md' for fname in files), \
        "This project's readme should exist in the current directory."

    # Read the contents of readme.md
    with open('readme.md', 'r', encoding='utf-8') as f:
        content = f.read()

    # Check for the "## Acknowledgment" section
    assert re.search(r'##\s*Acknowledgment', content, re.IGNORECASE), \
        "This project's readme should always contain a section Acknowledgment to thank direct and indirect contributions."