#!/usr/bin/env python3
"""
minify_files.py - Utility to minify all files in a folder by removing non-printable characters
Usage: python minify_files.py <input_folder> [<output_folder>]
If output_folder is not specified, files will be overwritten in place
"""

import os
import sys
import re
import shutil

class FileMinifier:
    def __init__(self, input_folder, output_folder=None):
        self.input_folder = input_folder
        self.output_folder = output_folder
        self.overwrite = output_folder is None
        
        # Create output directory if specified and doesn't exist
        if not self.overwrite and not os.path.exists(self.output_folder):
            os.makedirs(self.output_folder)
    
    def minify_all_files(self):
        # Check if input folder exists
        if not os.path.exists(self.input_folder):
            print(f"Error: Input folder '{self.input_folder}' not found.")
            return False
        
        # Get all files in the input folder
        files = [f for f in os.listdir(self.input_folder) 
                if os.path.isfile(os.path.join(self.input_folder, f))]
        
        if not files:
            print(f"No files found in '{self.input_folder}'.")
            return False
        
        # Process each file
        for file in files:
            self.minify_file(os.path.join(self.input_folder, file))
        
        print(f"Successfully minified {len(files)} files.")
        return True
    
    def minify_file(self, file_path):
        try:
            # Read file content
            with open(file_path, 'r', errors='replace') as f:
                content = f.read()
            
            # Remove non-printable characters
            # This keeps only ASCII printable characters (32-126) and newlines
            minified_content = re.sub(r'[^\x20-\x7E\r\n]', '', content)
            
            # Determine output path
            if self.overwrite:
                output_path = file_path
            else:
                output_path = os.path.join(self.output_folder, os.path.basename(file_path))
            
            # Write minified content
            with open(output_path, 'w') as f:
                f.write(minified_content)
            
            print(f"Minified: {file_path} -> {output_path}")
        except Exception as e:
            print(f"Error processing file '{file_path}': {str(e)}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python minify_files.py <input_folder> [<output_folder>]")
        print("If output_folder is not specified, files will be overwritten in place.")
        sys.exit(1)
    
    input_folder = sys.argv[1]
    output_folder = sys.argv[2] if len(sys.argv) > 2 else None
    
    minifier = FileMinifier(input_folder, output_folder)
    success = minifier.minify_all_files()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()