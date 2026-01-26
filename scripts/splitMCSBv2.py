#!/usr/bin/env python3
"""
Split MCSB v2 Excel into separate files and generate Markdown pages
Similar to splitMCSB.py but for MCSB v2 hierarchical structure
"""

import pandas as pd
import os

# Define file locations
base_directory = "docs/assets/tables/"
excel_file_name = "Microsoft_cloud_security_benchmark_v2.xlsx"
full_file_path = base_directory + excel_file_name

# Check if Excel file exists
if not os.path.exists(full_file_path):
    print(f"Warning: {full_file_path} not found. Skipping MCSB v2 processing.")
    exit(0)

# Load Excel file with pandas
xl = pd.ExcelFile(full_file_path)

# Directory for split Excel files
split_files_directory = base_directory + "MCSBv2/"

# Create directory if it doesn't exist
os.makedirs(split_files_directory, exist_ok=True)

# Directory for Markdown files
markdown_files_directory = "docs/Azure/Security/MCSBv2/"

# Create directory if it doesn't exist
os.makedirs(markdown_files_directory, exist_ok=True)

for sheet in xl.sheet_names:
    # Skip Readme sheet
    if sheet.lower() == 'readme':
        continue

    df = pd.read_excel(xl, sheet_name=sheet)

    # Write each DataFrame to a separate Excel file in the defined directory
    split_file_path = split_files_directory + f"{sheet}.xlsx"
    df.to_excel(split_file_path, index=False)

    # Create a Markdown file for each Excel file in the specified directory
    markdown_file_path = markdown_files_directory + f"{sheet}.md"

    with open(markdown_file_path, 'w') as f:
        f.write(f"---\n")
        f.write(f"hide:  \n  - toc\n")
        f.write(f"---\n\n")
        f.write(f"# MCSB v2 - {sheet}\n\n")
        f.write(f"{{{{ read_excel('{split_file_path}', engine='openpyxl') }}}}\n")

print(f"✓ MCSB v2 processing completed: {len(xl.sheet_names)-1} domains processed")
