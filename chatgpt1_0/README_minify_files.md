# File Minifier

A Ruby utility to minify all files in a folder by removing non-printable characters.

## Description

This script processes all files in a specified folder and removes any non-printable characters, keeping only:
- ASCII printable characters (codes 32-126)
- Newlines (CR and LF)

All other characters, including control characters and Unicode characters, are removed.

## Usage

```bash
ruby minify_files.rb <input_folder> [<output_folder>]
```

### Parameters

- `<input_folder>`: Required. The folder containing files to be minified.
- `<output_folder>`: Optional. The folder where minified files will be saved. If not specified, original files will be overwritten.

### Examples

Process files and save to a new location:
```bash
ruby minify_files.rb my_files minified_files
```

Process files and overwrite the originals:
```bash
ruby minify_files.rb my_files
```

## What Gets Removed

- Control characters (ASCII 0-31, 127)
- Unicode characters (anything outside ASCII 32-126)
- Any other non-printable characters

## What Gets Preserved

- Letters, numbers, and punctuation (ASCII 32-126)
- Newlines (CR and LF)

## Notes

- The script processes all files in the input folder (not recursively)
- Binary files may be corrupted if processed, so use with caution
- Always back up important files before minifying them in place