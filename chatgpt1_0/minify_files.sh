#!/bin/bash

# minify_files.sh - Utility to minify all files in a folder by removing non-printable characters
# Usage: bash minify_files.sh <input_folder> [<output_folder>]
# If output_folder is not specified, files will be overwritten in place

# Function to display usage information
show_usage() {
    echo "Usage: bash minify_files.sh <input_folder> [<output_folder>]"
    echo "If output_folder is not specified, files will be overwritten in place."
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

input_folder="$1"
output_folder="$2"
overwrite=true

# Check if input folder exists
if [ ! -d "$input_folder" ]; then
    echo "Error: Input folder '$input_folder' not found."
    exit 1
fi

# Check if output folder is provided
if [ -n "$output_folder" ]; then
    overwrite=false
    # Create output directory if it doesn't exist
    if [ ! -d "$output_folder" ]; then
        mkdir -p "$output_folder"
    fi
fi

# Count the number of files in the input folder
file_count=$(find "$input_folder" -type f -maxdepth 1 | wc -l)

if [ "$file_count" -eq 0 ]; then
    echo "No files found in '$input_folder'."
    exit 1
fi

# Process each file in the input folder
processed_count=0
for file in "$input_folder"/*; do
    # Skip if not a file
    if [ ! -f "$file" ]; then
        continue
    fi
    
    filename=$(basename "$file")
    
    if [ "$overwrite" = true ]; then
        # Process and overwrite the original file
        temp_file=$(mktemp)
        cat "$file" | tr -cd '[:print:]\r\n' > "$temp_file"
        mv "$temp_file" "$file"
        echo "Minified: $file -> $file"
    else
        # Process and save to output folder
        output_file="$output_folder/$filename"
        cat "$file" | tr -cd '[:print:]\r\n' > "$output_file"
        echo "Minified: $file -> $output_file"
    fi
    
    processed_count=$((processed_count + 1))
done

echo "Successfully minified $processed_count files."
exit 0