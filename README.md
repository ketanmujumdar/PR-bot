# PR Script Tool

A powerful command-line tool to automate the process of pull request creation. This script helps you select commits, generate a well-formatted PR description using Gemini AI, and create a GitHub PR directly from your terminal.

## Features

- 📋 Interactive commit selection using GUI or text-based interface
- 🤖 AI-powered PR description generation using Google's Gemini AI
- 🔄 Automatic dependency checking and installation
- 📊 Complete commit analysis including diffs and messages
- 🚀 Seamless GitHub PR creation via GitHub CLI

## Requirements

- Git repository
- macOS or Linux
- Google Gemini API key
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
- Help you configure your Gemini API key
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

Run the script in your git repository:

```zsh
./pr_script.sh
```

### Workflow

1. **Select Commits**: Choose which commits to include in your PR
   - GUI interface with whiptail (if available)
   - Text-based fallback interface
   - Option to select all commits

2. **Generate Report**: The script creates a detailed report of all selected commits

3. **Generate PR Description**: Uses Google's Gemini API to create a well-formatted PR description with:
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

# Set your Gemini API key
export GEMINI_API_KEY="your-api-key-here"

# Customize the template file location
export TEMPLATE_FILE="path/to/template.txt"
```

## Customizing PR Template

The script uses a template file for the Gemini API prompt. You can modify the template at `templates/pr_prompt_template.txt` to customize the prompt sent to the AI.

## Troubleshooting

### API Key Issues

If you see authentication errors, verify your Gemini API key is correctly set as an environment variable.

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

Open source - feel free to modify and distribute.
