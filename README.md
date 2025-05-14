# PR Script Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![AI: Gemini](https://img.shields.io/badge/AI-Gemini-blue.svg)](https://deepmind.google/technologies/gemini/)
[![AI: OpenAI Compatible](https://img.shields.io/badge/AI-OpenAI%20Compatible-orange.svg)](https://lmstudio.ai/)

A powerful command-line tool to automate the process of pull request creation. It helps you:
- Select commits interactively
- Generate PR descriptions using Gemini AI or OpenAI-compatible APIs (including local models)
- Create GitHub PRs directly from your terminal

![Demo](recording.gif)

[Features](#features) •
[Requirements](#requirements) •
[Installation](#installation) •
[Usage](#usage) •
[Configuration](#configuration)

## Features

- 📋 Interactive commit selection using GUI or text-based interface
- 🤖 AI-powered PR description generation using Google's Gemini AI or OpenAI-compatible APIs
- 🏠 Support for local LLMs like LM Studio for privacy and offline use
- 🔄 Automatic dependency checking and installation
- 📊 Complete commit analysis including diffs and messages
- 🚀 Seamless GitHub PR creation via GitHub CLI

## Requirements

- Git repository
- macOS or Linux
- One of the following:
  - Google Gemini API key for Gemini API
  - OpenAI API key or access to an OpenAI-compatible API (like LM Studio)
- GitHub CLI (optional, for PR creation)

## Dependencies

The script will check for and help install the following dependencies:

- `git` - For repository operations
- `whiptail` or `newt` - For GUI-based selection
- `jq` - For JSON processing
- `gh` - GitHub CLI (optional, for PR creation)

## Installation

### Easy Installation (Recommended)

Use the provided installation script to set up the tool:

1. Clone the repository or download the files
2. Run the installation script:
   ```zsh
   ./install.sh
   ```

The script will:
- Make the PR script executable
- Install the command as `pr` (either system-wide or in your user bin)
- Set up the template directory
- Help you configure your preferred LLM provider:
  - Gemini API
  - OpenAI API
  - Local LLM with OpenAI-compatible API (like LM Studio)
- Add the necessary paths to your shell configuration

### Manual Installation

If you prefer to set things up manually:

1. Clone the repository or download `pr_script.sh`
2. Make the script executable:
   ```zsh
   chmod +x pr_script.sh
   ```
3. Set up your Gemini API key:
   ```zsh
   export GEMINI_API_KEY="your-api-key"
   ```

## Usage

### Quick Start

```zsh
# Navigate to your git repository
cd your-repo

# Run the script
pr

# Or with the full path
./pr_script.sh
```

### Workflow

1. **Select Commits**: Choose which commits to include in your PR
   - GUI interface with whiptail (if available)
   - Text-based fallback interface
   - Option to select all commits

2. **Generate Report**: The script creates a detailed report of all selected commits

3. **Generate PR Description**: Uses Gemini API or OpenAI-compatible APIs to create a well-formatted PR description with:
   - A descriptive title with appropriate prefix (feat:, fix:, etc.)
   - Clear summary of changes
   - Implementation details
   - Testing considerations
   - List of changed files

4. **Create GitHub PR**: Optionally create a PR directly from the command line using GitHub CLI
   - Extracts title from the generated description
   - Uses the description as the PR body
   - Handles branch selection
   - Opens the PR in your browser if desired

## Configuration

You can customize the script behavior with environment variables:

```zsh
# Set a custom location for temporary files
export TEMP_DIR="/custom/temp/dir"

# Change the output file location
export OUTPUT_FILE="my-changes.txt"

# Adjust number of commits to fetch
export NUM_COMMITS=30

# Choose your LLM provider (default is "gemini")
export LLM_PROVIDER="gemini" # or "openai" for OpenAI or OpenAI-compatible APIs

# For Gemini API
export GEMINI_API_KEY="your-gemini-api-key-here"

# For OpenAI or compatible APIs (like LM Studio)
export OPENAI_API_KEY="your-openai-api-key-here"
export OPENAI_API_BASE_URL="https://api.openai.com/v1" # default OpenAI API URL
# For LM Studio: export OPENAI_API_BASE_URL="http://localhost:1234/v1" (adjust port as needed)
export OPENAI_API_MODEL="gpt-3.5-turbo" # or other compatible model name

# Customize the template file location
export TEMPLATE_FILE="path/to/template.txt"
```

## Customizing PR Template

The script uses a template file for the AI prompt. You can modify the template at `templates/pr_prompt_template.txt` to customize the prompt sent to the AI.

## Using with LM Studio or Other Local LLMs

You can use this tool with local language models through LM Studio or similar OpenAI-compatible API servers:

### Setting Up LM Studio

1. Download and install [LM Studio](https://lmstudio.ai/)
2. Launch LM Studio and download a model
3. Start the local server:
   - Click on "Local Server" tab
   - Select your model
   - Click "Start Server"
   - Note the server URL and port (typically `http://localhost:1234`)

### Configure the Script for LM Studio

```zsh
# Set the LLM provider to OpenAI-compatible API
export LLM_PROVIDER="openai"

# For local LLMs, you can use any placeholder value as API key
export OPENAI_API_KEY="lm-studio"

# Set the API base URL to your local LM Studio server
export OPENAI_API_BASE_URL="http://localhost:1234/v1"

# Specify the model (use the name shown in LM Studio)
export OPENAI_API_MODEL="your-model-name"
```

### Model Compatibility Notes

- Check your model's context window and adjust parameters accordingly
- Some models may be better than others at formatting PR descriptions
- If you're experiencing formatting issues, try a different model

## Troubleshooting

### API Key Issues

If you see authentication errors:
- For Gemini: Verify your Gemini API key is correctly set as an environment variable.
- For OpenAI: Check that your OpenAI API key is correctly set.
- For local LLMs: Make sure your LLM server is running and the API base URL is correctly configured.

### GUI Selection Not Working

If whiptail/dialog doesn't work correctly, the script will automatically fall back to a text-based interface.

### GitHub CLI Authentication

If PR creation fails, ensure you're authenticated with GitHub CLI:

```zsh
gh auth login
```

### JSON Parsing Errors

If you encounter JSON-related errors, ensure jq is installed:

```zsh
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

## License

This project is open source under the MIT License - feel free to modify and distribute.

<!-- markdownlint-configure-file {
  "MD013": {
    "code_blocks": false,
    "tables": false
  },
  "MD033": false,
  "MD041": false
} -->
