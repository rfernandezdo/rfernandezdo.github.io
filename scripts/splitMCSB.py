import pandas as pd
from urllib.request import urlretrieve

# Define file locations
url = (
    "https://github.com/MicrosoftDocs/SecurityBenchmarks/raw/master/Microsoft%20Cloud%20Security%20Benchmark/Microsoft_cloud_security_benchmark_v1.xlsx"
)
base_directory = "docs/assets/tables/"
excel_file_name = "Microsoft_cloud_security_benchmark_v1.xlsx"
full_file_path = base_directory + excel_file_name

# Retrieve file from URL
urlretrieve(url, full_file_path) 

# Load Excel file with pandas
xl = pd.ExcelFile(full_file_path)

# Directory for split Excel files
split_files_directory = base_directory + "MCSB/"

# Directory for Markdown files
markdown_files_directory = "docs/Azure/Security/MCSB/"

for sheet in xl.sheet_names:
    df = pd.read_excel(xl, sheet_name=sheet)
    
    # Write each DataFrame to a separate Excel file in the defined directory
    split_file_path = split_files_directory + f"{sheet}.xlsx"
    df.to_excel(split_file_path, index=False)
    
    # Create a Markdown file for each Excel file in the specified directory
    markdown_file_path = markdown_files_directory + f"{sheet}.md"
    
    with open(markdown_file_path, 'w') as f:
        f.write(f"---\n")
        f.write(f"hide:  \n  - toc\n")
        f.write(f"---\n")

        f.write(f"# MCSB_v1 - {sheet}\n\n")
        f.write(f"{{{{ read_excel('{split_file_path}', engine='openpyxl') }}}}\n")
