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

case $install_choice in
    1)
        # System-wide installation
        echo -e "\n${YELLOW}Installing system-wide...${NC}"
        
        # Check if /usr/local/bin exists
        if [ ! -d "/usr/local/bin" ]; then
            echo "Creating /usr/local/bin directory..."
            sudo mkdir -p /usr/local/bin
        fi
        
        # Create the templates directory in a global location
        if [ ! -d "/usr/local/share/pr_cmd" ]; then
            echo "Creating templates directory in /usr/local/share/pr_cmd..."
            sudo mkdir -p "/usr/local/share/pr_cmd"
        fi
        
        # Copy templates to the global location
        echo "Copying templates to /usr/local/share/pr_cmd..."
        sudo cp -R "$TEMPLATES_DIR" "/usr/local/share/pr_cmd/"
        
        # Create a wrapper script that sets the correct template path
        WRAPPER_SCRIPT=$(cat << 'EOF'
#!/bin/bash
# Set the template path for the PR script
export TEMPLATE_FILE="/usr/local/share/pr_cmd/templates/pr_prompt_template.txt"
# Run the actual script with absolute path
exec "/usr/local/bin/pr_script.sh" "$@"
EOF
)
        
        # Write the wrapper script to a temporary file
        echo "$WRAPPER_SCRIPT" > /tmp/pr_wrapper.sh
        chmod +x /tmp/pr_wrapper.sh
        
        # Create symbolic link to the wrapper script
        sudo cp /tmp/pr_wrapper.sh /usr/local/bin/pr
        sudo chmod +x /usr/local/bin/pr
        sudo ln -sf "$SOURCE_SCRIPT" /usr/local/bin/pr_script.sh
        
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

# Ask for Gemini API key
echo ""
echo -e "${YELLOW}Gemini API Key Configuration:${NC}"
read -p "Would you like to set up your Gemini API key now? (y/n): " setup_api
if [[ "$setup_api" == "y" || "$setup_api" == "Y" ]]; then
    read -p "Enter your Gemini API key: " api_key
    
    if [ -n "$api_key" ]; then
        # Determine the appropriate config file
        CONFIG_DIR="$HOME/.config/pr_cmd"
        CONFIG_FILE="$CONFIG_DIR/config"
        
        # Create config directory if it doesn't exist
        mkdir -p "$CONFIG_DIR"
        
        # Write API key to config file
        echo "GEMINI_API_KEY=\"$api_key\"" > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"  # Secure the file containing the API key
        
        echo -e "${GREEN}✓${NC} API key configured successfully"
        
        # If global installation, update the wrapper script to source the config file
        if [ "$install_choice" -eq 1 ]; then
            WRAPPER_SCRIPT=$(cat << EOF
#!/bin/bash
# Source the config file if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi
# Set the template path for the PR script
export TEMPLATE_FILE="/usr/local/share/pr_cmd/templates/pr_prompt_template.txt"
# Run the actual script with absolute path
exec "/usr/local/bin/pr_script.sh" "\$@"
EOF
)
            # Update the wrapper script
            echo "$WRAPPER_SCRIPT" > /tmp/pr_wrapper.sh
            chmod +x /tmp/pr_wrapper.sh
            sudo cp /tmp/pr_wrapper.sh /usr/local/bin/pr
            sudo chmod +x /usr/local/bin/pr
            
            echo -e "${GREEN}✓${NC} Updated wrapper script to use the config file"
        fi
    else
        echo -e "${YELLOW}No API key provided.${NC}"
        echo "You'll need to set the GEMINI_API_KEY environment variable before using the 'pr' command."
    fi
else
    echo -e "${YELLOW}Note:${NC} You'll need to set the GEMINI_API_KEY environment variable before using the 'pr' command."
    echo "You can do this by running: export GEMINI_API_KEY='your-api-key'"
fi