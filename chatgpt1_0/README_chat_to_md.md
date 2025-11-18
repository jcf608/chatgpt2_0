# Chat to Markdown Converter

A utility script to convert chat text files to Markdown format.

## Overview

This utility script (`chat_to_md.rb`) converts chat text files from various formats to a standardized Markdown format. It automatically detects the format of the input file and applies the appropriate conversion rules.

## Supported Chat Formats

The utility can handle the following chat file formats:

1. **Emoji Format**: Files with messages prefixed with emoji indicators like "🤖 System:", "👤 User:", and "🤖 Assistant:".
2. **CLI Header Format**: Files with a metadata header and messages prefixed with "👤 USER:" and "🤖 AI:".
3. **CLI Format**: Files with user inputs prefixed with "> " and ChatGPT responses without a specific prefix.
4. **Unknown Format**: For any other format, the content is wrapped in a Markdown code block.

## Usage

### Converting a Single File

```bash
ruby chat_to_md.rb <input_file> [<output_file>]
```

#### Arguments

- `<input_file>`: The path to the chat text file to convert (required).
- `<output_file>`: The path to the output Markdown file (optional). If not provided, the output file will be created with the same name as the input file but with a `.md` extension.

#### Examples

```bash
# Convert a chat file to Markdown with default output filename
ruby chat_to_md.rb chats/example.txt

# Convert a chat file to Markdown with a specific output filename
ruby chat_to_md.rb chats/example.txt output/example_converted.md
```

### Converting All Chat Files

You can also convert all chat files in the `chats` directory at once using the `convert_all_chats.rb` script:

```bash
ruby convert_all_chats.rb [<output_dir>]
```

#### Arguments

- `<output_dir>`: The directory where the converted Markdown files will be saved (optional). If not provided, the output files will be created in the `chats/markdown` directory.

#### Examples

```bash
# Convert all chat files and save them in the default 'chats/markdown' directory
ruby convert_all_chats.rb

# Convert all chat files and save them in a specific directory
ruby convert_all_chats.rb output/markdown
```

This script has been tested with 38 chat files of various formats and successfully converted all of them to Markdown format.

## Output Format

The converted Markdown file will have the following structure:

```markdown
# Chat Conversation

## System (if present)

```json
System message content
```

## User

User message content

## Assistant

Assistant message content

...
```

## Requirements

- Ruby 2.0 or higher
- `fileutils` gem (included in Ruby standard library)

## Installation

No installation is required. Simply download the `chat_to_md.rb` script and run it with Ruby.

## License

This utility is provided as-is with no warranty. Feel free to modify and distribute it as needed.
