#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}PR Command Installation Script${NC}"
echo "-------------------------------"

# Source script path - Get absolute path to ensure symlinks work from any directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/pr_script.sh"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Check if source script exists
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo -e "${RED}Error: Source script not found at $SOURCE_SCRIPT${NC}"
    exit 1
fi

# Check if templates directory exists
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo -e "${RED}Error: Templates directory not found at $TEMPLATES_DIR${NC}"
    exit 1
fi

# Make sure the script is executable
chmod +x "$SOURCE_SCRIPT"
echo -e "${GREEN}✓${NC} Made source script executable"

# Determine where to install the command
echo ""
echo "Where would you like to install the 'pr' command?"
echo "1) System-wide (/usr/local/bin/pr) - requires sudo"
echo "2) User-only (~/bin/pr) - no sudo required"
read -p "Enter choice [1-2]: " install_choice

# Create config directory and file
CONFIG_DIR="$HOME/.config/pr_cmd"
CONFIG_FILE="$CONFIG_DIR/config"
mkdir -p "$CONFIG_DIR"

case $install_choice in
    1)
        # System-wide installation
        echo -e "\n${YELLOW}Installing system-wide...${NC}"
        
        # Check if /usr/local/bin exists
        if [ ! -d "/usr/local/bin" ]; then
            echo "Creating /usr/local/bin directory..."
            sudo mkdir -p /usr/local/bin
        fi
        
        # Create the templates directory in the global location
        GLOBAL_TEMPLATES_DIR="/usr/local/share/pr_cmd/templates"
        if [ ! -d "$GLOBAL_TEMPLATES_DIR" ]; then
            echo "Creating templates directory in /usr/local/share/pr_cmd/templates..."
            sudo mkdir -p "$GLOBAL_TEMPLATES_DIR"
        fi
        
        # Copy templates to the global location
        echo "Copying templates to $GLOBAL_TEMPLATES_DIR..."
        sudo cp -R "$TEMPLATES_DIR"/* "$GLOBAL_TEMPLATES_DIR/"
        
        # Add template location to config file
        echo "TEMPLATE_FILE=\"$GLOBAL_TEMPLATES_DIR/pr_prompt_template.txt\"" > "$CONFIG_FILE"
        
        # Create symbolic link to the script
        sudo ln -sf "$SOURCE_SCRIPT" /usr/local/bin/pr
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Successfully installed to /usr/local/bin/pr"
            echo -e "\n${GREEN}Installation complete!${NC}"
            echo "You can now run the 'pr' command from any directory."
        else
            echo -e "${RED}Error: Failed to create symbolic link.${NC}"
            exit 1
        fi
        ;;
        
    2)
        # User-only installation
        echo -e "\n${YELLOW}Installing for current user only...${NC}"
        
        # Create ~/bin if it doesn't exist
        if [ ! -d "$HOME/bin" ]; then
            echo "Creating ~/bin directory..."
            mkdir -p "$HOME/bin"
        fi
        
        # Create local templates directory
        LOCAL_TEMPLATES_DIR="$HOME/.local/share/pr_cmd/templates"
        if [ ! -d "$LOCAL_TEMPLATES_DIR" ]; then
            echo "Creating templates directory in $LOCAL_TEMPLATES_DIR..."
            mkdir -p "$LOCAL_TEMPLATES_DIR"
        fi
        
        # Copy templates to the local location
        echo "Copying templates to $LOCAL_TEMPLATES_DIR..."
        cp -R "$TEMPLATES_DIR"/* "$LOCAL_TEMPLATES_DIR/"
        
        # Add template location to config file
        echo "TEMPLATE_FILE=\"$LOCAL_TEMPLATES_DIR/pr_prompt_template.txt\"" > "$CONFIG_FILE"
        
        # Create symbolic link
        ln -sf "$SOURCE_SCRIPT" "$HOME/bin/pr"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Successfully installed to ~/bin/pr"
            
            # Check if ~/bin is in PATH
            if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
                echo "Adding ~/bin to your PATH..."
                
                # Determine shell configuration file
                SHELL_CONFIG=""
                if [ -f "$HOME/.zshrc" ]; then
                    SHELL_CONFIG="$HOME/.zshrc"
                    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
                elif [ -f "$HOME/.bash_profile" ]; then
                    SHELL_CONFIG="$HOME/.bash_profile"
                    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
                elif [ -f "$HOME/.bashrc" ]; then
                    SHELL_CONFIG="$HOME/.bashrc"
                    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
                else
                    echo -e "${YELLOW}Warning: Could not determine shell configuration file.${NC}"
                    echo "Please manually add the following line to your shell configuration:"
                    echo 'export PATH="$HOME/bin:$PATH"'
                fi
                
                if [ -n "$SHELL_CONFIG" ]; then
                    echo -e "${GREEN}✓${NC} Added ~/bin to PATH in $SHELL_CONFIG"
                    echo -e "${YELLOW}Note:${NC} You need to run 'source $SHELL_CONFIG' or start a new terminal session for the PATH changes to take effect."
                fi
            else
                echo -e "${GREEN}✓${NC} ~/bin is already in your PATH"
            fi
            
            echo -e "\n${GREEN}Installation complete!${NC}"
            echo "You can now run the 'pr' command from any directory."
            echo "If the command isn't recognized right away, you may need to:"
            echo "1. Open a new terminal window, or"
            echo "2. Run 'source ~/.zshrc' or 'source ~/.bash_profile' to refresh your environment"
        else
            echo -e "${RED}Error: Failed to create symbolic link.${NC}"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}Invalid choice. Installation aborted.${NC}"
        exit 1
        ;;
esac

# Final instructions
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "Run 'pr' in any git repository to select and extract commit information."

# Ask for LLM Provider configuration
echo ""
echo -e "${YELLOW}LLM Provider Configuration:${NC}"
echo "This tool supports multiple AI providers:"
echo "1) Gemini API (requires Google API key)"
echo "2) OpenAI API (requires OpenAI API key)"
echo "3) Local LLM with OpenAI-compatible API (e.g., LM Studio)"
echo "4) Skip configuration (configure later manually)"
read -p "Choose an option [1-4]: " llm_choice

case $llm_choice in
    1)
        # Gemini Configuration
        read -p "Enter your Gemini API key: " api_key
        if [ -n "$api_key" ]; then
            # Add Gemini settings to config file
            echo "LLM_PROVIDER=\"gemini\"" >> "$CONFIG_FILE"
            echo "GEMINI_API_KEY=\"$api_key\"" >> "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"  # Secure the file containing the API key
            echo -e "${GREEN}✓${NC} Gemini API configured successfully"
        else
            echo -e "${YELLOW}No API key provided.${NC}"
            echo "You'll need to set the GEMINI_API_KEY environment variable before using the 'pr' command."
        fi
        ;;
    
    2)
        # OpenAI Configuration
        read -p "Enter your OpenAI API key: " api_key
        if [ -n "$api_key" ]; then
            # Add OpenAI settings to config file
            echo "LLM_PROVIDER=\"openai\"" >> "$CONFIG_FILE"
            echo "OPENAI_API_KEY=\"$api_key\"" >> "$CONFIG_FILE"
            echo "OPENAI_API_BASE_URL=\"https://api.openai.com/v1\"" >> "$CONFIG_FILE"
            read -p "Enter model name [default: gpt-3.5-turbo]: " model_name
            model_name=${model_name:-gpt-3.5-turbo}
            echo "OPENAI_API_MODEL=\"$model_name\"" >> "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"  # Secure the file containing the API key
            echo -e "${GREEN}✓${NC} OpenAI API configured successfully"
        else
            echo -e "${YELLOW}No API key provided.${NC}"
            echo "You'll need to set the OPENAI_API_KEY environment variable before using the 'pr' command."
        fi
        ;;
    
    3)
        # Local LLM Configuration
        echo "Setting up for local LLM with OpenAI-compatible API (e.g., LM Studio)"
        # Add Local LLM settings to config file
        echo "LLM_PROVIDER=\"openai\"" >> "$CONFIG_FILE"
        echo "OPENAI_API_KEY=\"local-llm\"" >> "$CONFIG_FILE"  # Placeholder value
        
        # Get the base URL
        read -p "Enter the API base URL [default: http://localhost:1234/v1]: " base_url
        base_url=${base_url:-http://localhost:1234/v1}
        echo "OPENAI_API_BASE_URL=\"$base_url\"" >> "$CONFIG_FILE"
        
        # Get the model name
        read -p "Enter the model name as shown in your LLM provider: " model_name
        if [ -n "$model_name" ]; then
            echo "OPENAI_API_MODEL=\"$model_name\"" >> "$CONFIG_FILE"
        fi
        
        chmod 600 "$CONFIG_FILE"  # Secure the file
        echo -e "${GREEN}✓${NC} Local LLM configured successfully"
        echo -e "${YELLOW}Note:${NC} Ensure your local LLM server is running when using the tool."
        echo "For LM Studio: Start the application and enable the local server with your chosen model."
        ;;
    
    4)
        echo -e "${YELLOW}Skipping LLM configuration.${NC}"
        echo "You'll need to configure an LLM provider manually before using the 'pr' command."
        echo "See README.md for configuration instructions."
        ;;
    
    *)
        echo -e "${YELLOW}Invalid choice. Skipping LLM configuration.${NC}"
        echo "You'll need to configure an LLM provider manually before using the 'pr' command."
        echo "See README.md for configuration instructions."
        ;;
esac

# Update the main script to source this config file
if ! grep -q "source \"$CONFIG_FILE\"" "$SOURCE_SCRIPT"; then
    # Add code to beginning of script to source the config file
    TMP_SCRIPT="${TEMP_DIR:-/tmp}/pr_script_tmp.sh"
    cat > "$TMP_SCRIPT" << EOF
#!/bin/bash

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

$(cat "$SOURCE_SCRIPT" | grep -v "^#!/bin/bash")
EOF
    mv "$TMP_SCRIPT" "$SOURCE_SCRIPT"
    chmod +x "$SOURCE_SCRIPT"
    echo -e "${GREEN}✓${NC} Updated script to load configuration automatically"
fi

# Function to create PR using GitHub CLI - adding the definition that was missing
create_github_pr() {
    local description_file="$1"
    
    # Check if GitHub CLI is installed
    if ! command -v gh >/dev/null 2>&1; then
        echo "Error: GitHub CLI (gh) is not installed."
        echo "Please install it using one of the following commands:"
        echo "  - macOS: brew install gh"
        echo "  - Linux (Debian/Ubuntu): apt install gh"
        echo "  - Linux (Fedora): dnf install gh"
        echo "  - Or visit: https://github.com/cli/cli#installation"
        return 1
    fi
    
    # Check if logged in to GitHub CLI
    if ! gh auth status >/dev/null 2>&1; then
        echo "You need to authenticate with GitHub CLI first."
        echo "Please run: gh auth login"
        return 1
    fi
    
    # Extract title from the PR description file
    local pr_title=$(grep -m 1 "^Title:" "$description_file" | sed 's/^Title: //')
    
    # If no title found, prompt the user
    if [ -z "$pr_title" ]; then
        read -p "Enter a title for your PR: " pr_title
    fi
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    
    # Get default branch (usually main or master)
    local default_branch=$(git remote show origin | grep "HEAD branch" | awk '{print $NF}')
    
    # Ask user for target branch
    read -p "Enter the target branch [default: $default_branch]: " target_branch
    target_branch=${target_branch:-$default_branch}
    
    echo "Creating PR from '$current_branch' to '$target_branch'..."
    echo "Title: $pr_title"
    
    # Create PR using GitHub CLI
    if gh pr create --title "$pr_title" --body-file "$description_file" --base "$target_branch"; then
        echo "PR created successfully!"
        
        # Get the URL of the newly created PR
        local pr_url=$(gh pr view --json url | jq -r .url)
        echo "PR URL: $pr_url"
        
        # Open PR in browser if requested
        read -p "Open PR in browser? (y/n): " open_browser
        if [[ "$open_browser" == "y" || "$open_browser" == "Y" ]]; then
            gh pr view --web
        fi
    else
        echo "Failed to create PR."
        return 1
    fi
}