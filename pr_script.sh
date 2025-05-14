#!/bin/bash

# Load configuration
if [ -f "/Users/ketanmujumdar/.config/pr_cmd/config" ]; then
    source "/Users/ketanmujumdar/.config/pr_cmd/config"
fi

# Use HOME variable to create a portable path to the config file
CONFIG_FILE="$HOME/.config/pr_cmd/config"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Environment variables (can be customized)
export TEMP_DIR="${TEMP_DIR:-/tmp/git-changes}"
export OUTPUT_FILE="${OUTPUT_FILE:-$TEMP_DIR/changes.txt}"
export NUM_COMMITS="${NUM_COMMITS:-20}"
export GEMINI_API_KEY="${GEMINI_API_KEY:-}"
export TEMPLATE_FILE="${TEMPLATE_FILE:-$(dirname "$0")/templates/pr_prompt_template.txt}"

# LLM API settings (OpenAI-compatible API support)
export LLM_PROVIDER="${LLM_PROVIDER:-gemini}"  # Options: gemini, openai
export GEMINI_API_MODEL="${GEMINI_API_MODEL:-gemini-2.0-flash-lite}"  # Default Gemini model
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export OPENAI_API_BASE_URL="${OPENAI_API_BASE_URL:-https://api.openai.com/v1}"
export OPENAI_API_MODEL="${OPENAI_API_MODEL:-gpt-3.5-turbo}"

# Check for required API key based on provider
if [[ "$LLM_PROVIDER" == "gemini" && -z "$GEMINI_API_KEY" ]]; then
    echo "ERROR: GEMINI_API_KEY environment variable is not set"
    echo "Please set it using: export GEMINI_API_KEY='your-api-key'"
    echo "Or switch to OpenAI-compatible API using: export LLM_PROVIDER='openai'"
    exit 1
elif [[ "$LLM_PROVIDER" == "openai" && -z "$OPENAI_API_KEY" ]]; then
    echo "ERROR: OPENAI_API_KEY environment variable is not set"
    echo "For local LLMs like LM Studio, you can set any value (e.g. 'lm-studio')"
    echo "Please set it using: export OPENAI_API_KEY='your-api-key'"
    echo "Or switch to Gemini API using: export LLM_PROVIDER='gemini'"
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Function to format the prompt with content
format_prompt() {
    local content="$1"
    # Read the template and replace %s with the content
    # Using printf to properly handle the template
    printf "$(cat "$TEMPLATE_FILE")" "$content"
}

# Function to estimate token count (rough approximation)
estimate_tokens() {
    local content="$1"
    # Approximate token count (rough estimate: ~4 chars per token)
    local char_count=$(echo "$content" | wc -c)
    echo $((char_count / 4))
}

# Function to send content to LLM API (supports both Gemini and OpenAI-compatible APIs)
send_to_gemini() {
    local content="$1"
    local formatted_prompt=$(format_prompt "$content")
    local estimated_tokens=$(estimate_tokens "$formatted_prompt")
    local provider="${LLM_PROVIDER:-gemini}"
    
    if [ "$estimated_tokens" -gt 1000000 ]; then
        echo "Warning: Content might exceed 1 million tokens (estimated: $estimated_tokens)"
        read -p "Do you want to continue? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Operation cancelled by user."
            exit 0
        fi
    fi
    
    # Create a temporary file for the request body
    local temp_request="${TEMP_DIR}/request.json"
    local temp_response="${TEMP_DIR}/response.json"
    
    if [[ "$provider" == "gemini" ]]; then
        echo "Sending content to Gemini API (estimated tokens: $estimated_tokens)..."
        
        # Create the JSON request body for Gemini
        cat > "$temp_request" << EOF
{
    "contents": [{
        "parts":[{
            "text": $(printf '%s' "$formatted_prompt" | jq -R -s '.')
        }]
    }]
}
EOF
        
        # Send request to Gemini API
        if curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/$GEMINI_API_MODEL:generateContent?key=$GEMINI_API_KEY" \
            -H "Content-Type: application/json" \
            -d "@$temp_request" > "$temp_response"; then
            
            # Debug: Show the raw response
            echo "Debug: Raw API Response:"
            cat "$temp_response"
            echo "----------------------"
            
            # Extract the generated text from the response
            if generated_text=$(jq -r '.candidates[0].content.parts[0].text // empty' "$temp_response") && [ -n "$generated_text" ]; then
                # Save both raw response and extracted text
                echo "$generated_text" > "${TEMP_DIR}/pr_description.md"
                mv "$temp_response" "${TEMP_DIR}/gemini_response.json"
                
                echo "Successfully generated PR description"
                echo "Full response saved to ${TEMP_DIR}/gemini_response.json"
                echo "PR description saved to ${TEMP_DIR}/pr_description.md"
                
                # Display the PR description
                echo -e "\nGenerated PR Description:"
                echo "------------------------"
                cat "${TEMP_DIR}/pr_description.md"
                echo "------------------------"
            else
                echo "Error: Could not extract generated text from response"
                echo "Response content:"
                jq '.' "$temp_response" || cat "$temp_response"
                return 1
            fi
        else
            echo "Error sending content to Gemini API"
            if [ -f "$temp_response" ]; then
                echo "Error response:"
                jq '.' "$temp_response" || cat "$temp_response"
            fi
            return 1
        fi
    elif [[ "$provider" == "openai" ]]; then
        echo "Sending content to OpenAI-compatible API (${OPENAI_API_BASE_URL}) (estimated tokens: $estimated_tokens)..."
        
        # Create the JSON request body for OpenAI-compatible API
        cat > "$temp_request" << EOF
{
    "model": "${OPENAI_API_MODEL}",
    "messages": [
        {
            "role": "user", 
            "content": $(printf '%s' "$formatted_prompt" | jq -R -s '.')
        }
    ],
    "temperature": 0.7,
    "max_tokens": 2048
}
EOF
        
        # Send request to OpenAI-compatible API
        if curl -s -X POST "${OPENAI_API_BASE_URL}/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${OPENAI_API_KEY}" \
            -d "@$temp_request" > "$temp_response"; then
            
            # Debug: Show the raw response
            echo "Debug: Raw API Response:"
            cat "$temp_response"
            echo "----------------------"
            
            # Extract the generated text from the response
            if generated_text=$(jq -r '.choices[0].message.content // empty' "$temp_response") && [ -n "$generated_text" ]; then
                # Save both raw response and extracted text
                echo "$generated_text" > "${TEMP_DIR}/pr_description.md"
                mv "$temp_response" "${TEMP_DIR}/openai_response.json"
                
                echo "Successfully generated PR description"
                echo "Full response saved to ${TEMP_DIR}/openai_response.json"
                echo "PR description saved to ${TEMP_DIR}/pr_description.md"
                
                # Display the PR description
                echo -e "\nGenerated PR Description:"
                echo "------------------------"
                cat "${TEMP_DIR}/pr_description.md"
                echo "------------------------"
            else
                echo "Error: Could not extract generated text from response"
                echo "Response content:"
                jq '.' "$temp_response" || cat "$temp_response"
                return 1
            fi
        else
            echo "Error sending content to OpenAI-compatible API"
            if [ -f "$temp_response" ]; then
                echo "Error response:"
                jq '.' "$temp_response" || cat "$temp_response"
            fi
            return 1
        fi
    else
        echo "Error: Unknown LLM provider '$provider'"
        echo "Supported providers: gemini, openai"
        return 1
    fi
    
    # Clean up temporary request file
    rm -f "$temp_request"
}

# Check for macOS and install dependencies if needed
check_and_install_dependencies() {
    # Check if running on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Detected macOS system"
        
        # Check for Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH (for the current session)
            if [[ -d "/opt/homebrew/bin/" ]]; then
                # For Apple Silicon Macs
                export PATH="/opt/homebrew/bin:$PATH"
            else
                # For Intel Macs
                export PATH="/usr/local/bin:$PATH"
            fi
        fi
        
        # Check if using OpenAI-compatible API and provide LM Studio hint
        if [[ "$LLM_PROVIDER" == "openai" && "$OPENAI_API_BASE_URL" == *"localhost"* ]]; then
            echo "Info: Using a local OpenAI-compatible API endpoint."
            echo "If using LM Studio, ensure it's running with the server enabled."
            echo "LM Studio: https://lmstudio.ai/"
        fi
        
        # Check for whiptail/newt
        if ! command -v whiptail >/dev/null 2>&1; then
            echo "whiptail not found. Installing newt via Homebrew..."
            brew install newt
        fi
        
        # Check for git (just in case)
        if ! command -v git >/dev/null 2>&1; then
            echo "git not found. Installing git via Homebrew..."
            brew install git
        fi
        
        # Check for jq (needed for JSON parsing)
        if ! command -v jq >/dev/null 2>&1; then
            echo "jq not found. Installing jq via Homebrew..."
            brew install jq
        fi
        
        # Check for GitHub CLI (optional, will prompt later if needed)
        if ! command -v gh >/dev/null 2>&1; then
            echo "GitHub CLI not found. It's recommended for PR creation."
            read -p "Install GitHub CLI now? (y/n): " install_gh
            if [[ "$install_gh" == "y" || "$install_gh" == "Y" ]]; then
                brew install gh
                echo "After installation, please authenticate with: gh auth login"
            fi
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # For Linux systems
        echo "Detected Linux system"
        
        # Check distribution type
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            if ! command -v whiptail >/dev/null 2>&1; then
                echo "whiptail not found. Installing whiptail..."
                sudo apt-get update
                sudo apt-get install -y whiptail
            fi
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora/RHEL
            if ! command -v whiptail >/dev/null 2>&1; then
                echo "whiptail not found. Installing newt..."
                sudo dnf install -y newt
            fi
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            if ! command -v whiptail >/dev/null 2>&1; then
                echo "whiptail not found. Installing libnewt..."
                sudo pacman -S --noconfirm libnewt
            fi
        fi
    fi
    
    # Final verification
    if ! command -v git >/dev/null 2>&1; then
        echo "ERROR: Git is required but could not be installed automatically."
        echo "Please install git manually and try again."
        exit 1
    fi
}

# Run dependency check
check_and_install_dependencies

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

echo "Fetching recent commits..."

# Use arrays for storing commit information (compatible with older bash)
commit_hashes=()
commit_subjects=()
commit_dates=()

# Populate arrays using a more compatible approach
while IFS='|' read -r hash subject date; do
    commit_hashes+=("$hash")
    commit_subjects+=("$subject")
    commit_dates+=("$date")
done < <(git log -n "$NUM_COMMITS" --pretty=format:"%h|%s|%ad" --date=short)

if [ ${#commit_hashes[@]} -eq 0 ]; then
    echo "No commits found in the current repository."
    exit 1
fi

# Function for whiptail UI with multi-select
select_with_whiptail() {
    # Prepare menu items
    menu_items=()
    for i in "${!commit_hashes[@]}"; do
        menu_items+=("$i" "${commit_dates[$i]} - ${commit_subjects[$i]}" "OFF")
    done
    
    # Force terminal settings for better compatibility
    export TERM=xterm-256color
    
    # Calculate terminal dimensions
    term_height=$(tput lines)
    term_width=$(tput cols)
    
    # Adjust menu size based on terminal size (use 80% of terminal size)
    menu_height=$((term_height * 8 / 10))
    menu_width=$((term_width * 8 / 10))
    list_height=$((menu_height - 7))  # Leave room for borders and text
    
    # Display checklist with whiptail and directly capture output
    selected_indices=$(whiptail --clear --title "Select commits" \
        --checklist "Use space to select/deselect, Enter to confirm:" \
        $menu_height $menu_width $list_height \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)
    
    # Check the exit status
    if [ $? -eq 0 ]; then
        echo "$selected_indices"
        return 0
    else
        echo "Selection cancelled."
        exit 1
    fi
}

# Function for cursor-based multi-select (fallback)
select_with_cursors() {
    # Save terminal settings
    saved_stty=$(stty -g)
    
    # Disable echo and set raw input mode
    stty -echo raw
    
    # Selected indices
    declare -a selected_items
    
    # Draw menu function
    draw_menu() {
        clear
        echo "Select commits (use ↑/↓ arrows, SPACE to select/deselect, ENTER to confirm):"
        echo "-------------------------------------------------------------------"
        
        for i in "${!commit_hashes[@]}"; do
            # Check if this index is in the selected array
            is_selected=0
            for sel in "${selected_items[@]}"; do
                if [ "$sel" -eq "$i" ]; then
                    is_selected=1
                    break
                fi
            done
            
            if [ "$i" -eq "$1" ]; then
                if [ "$is_selected" -eq 1 ]; then
                    echo " → [X] ${commit_dates[$i]} - ${commit_subjects[$i]}"
                else
                    echo " → [ ] ${commit_dates[$i]} - ${commit_subjects[$i]}"
                fi
            else
                if [ "$is_selected" -eq 1 ]; then
                    echo "   [X] ${commit_dates[$i]} - ${commit_subjects[$i]}"
                else
                    echo "   [ ] ${commit_dates[$i]} - ${commit_subjects[$i]}"
                fi
            fi
        done
        
        echo ""
        echo "Selected: ${#selected_items[@]} commit(s)"
    }
    
    # Toggle selection
    toggle_selection() {
        local pos=$1
        local found=0
        local index=0
        
        for i in "${!selected_items[@]}"; do
            if [ "${selected_items[$i]}" -eq "$pos" ]; then
                found=1
                index=$i
                break
            fi
        done
        
        if [ "$found" -eq 1 ]; then
            # Remove from selection
            unset 'selected_items[$index]'
            # Reindex array
            selected_items=("${selected_items[@]}")
        else
            # Add to selection
            selected_items+=("$pos")
        fi
    }
    
    # Initial position
    position=0
    draw_menu $position
    
    # Handle key presses
    while true; do
        # Read a single keypress
        key=$(dd bs=1 count=1 2>/dev/null)
        
        # Handle arrow keys (they send escape sequences)
        if [[ "$key" = $'\e' ]]; then
            # Read the next two characters
            key="$key$(dd bs=1 count=2 2>/dev/null)"
            
            case "$key" in
                $'\e[A') # Up arrow
                    if [ $position -gt 0 ]; then
                        position=$((position-1))
                        draw_menu $position
                    fi
                    ;;
                $'\e[B') # Down arrow
                    if [ $position -lt $((${#commit_hashes[@]}-1)) ]; then
                        position=$((position+1))
                        draw_menu $position
                    fi
                    ;;
            esac
        elif [[ "$key" = " " ]]; then # Space key
            toggle_selection $position
            draw_menu $position
        elif [[ "$key" = "" ]]; then # Enter key
            # Restore terminal settings
            stty "$saved_stty"
            
            # Output the selected indices
            if [ ${#selected_items[@]} -eq 0 ]; then
                echo "No commits selected."
                exit 1
            fi
            
            # Format the output like whiptail does (quoted space-separated indices)
            out_str=""
            for sel in "${selected_items[@]}"; do
                out_str+="\"$sel\" "
            done
            echo "$out_str"
            return 0
        fi
    done
}

# Try to use whiptail, fall back to simpler selection methods
if command -v whiptail >/dev/null 2>&1; then
    clear  # Clear the screen first
    echo "Using whiptail selection dialog. Please select commits using SPACE, then press ENTER to confirm."
    echo "If the dialog is not visible, press Ctrl+C and the script will fall back to text mode."
    sleep 2  # Give user time to read the message
    
    # First attempt with whiptail
    selected_indices=$(select_with_whiptail)
    
    # If nothing was selected or whiptail failed, offer a text-based alternative
    if [[ -z "${selected_indices// }" ]]; then
        echo "Whiptail selection empty or failed. Would you like to:"
        echo "1. Select specific commits by number"
        echo "2. Use all commits"
        echo "3. Exit"
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            1)
                echo "Enter commit numbers separated by spaces (0-$((${#commit_hashes[@]}-1))):"
                echo "Available commits:"
                for i in "${!commit_hashes[@]}"; do
                    echo "$i: ${commit_dates[$i]} - ${commit_subjects[$i]}"
                done
                read -p "> " manual_selection
                selected_indices=$manual_selection
                ;;
            2)
                # Use all commits
                selected_indices=""  # Will be handled later
                ;;
            3)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid choice. Using all commits."
                selected_indices=""
                ;;
        esac
    fi
else
    echo "whiptail not found, using cursor-based selection"
    selected_indices=$(select_with_cursors)
fi

# Parse the result
# whiptail returns space-separated quoted values like: "1" "3" "5"
# We need to convert them to an array
selected_array=()

# Check if selected_indices is empty or only contains whitespace
if [[ -z "${selected_indices// }" ]]; then
    echo "No selection was made. Using all commits by default."
    # Use all commits by default
    for i in "${!commit_hashes[@]}"; do
        selected_array+=("$i")
    done
else
    # Process the selection
    for val in $selected_indices; do
        # Remove quotes
        val="${val//\"/}"
        if [[ "$val" =~ ^[0-9]+$ ]]; then
            selected_array+=("$val")
        fi
    done

    if [ ${#selected_array[@]} -eq 0 ]; then
        echo "No valid commits selected. Using all commits by default."
        # Use all commits by default
        for i in "${!commit_hashes[@]}"; do
            selected_array+=("$i")
        done
    fi
fi

# Ask for confirmation
echo "About to process ${#selected_array[@]} commits."
read -p "Continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled by user."
    exit 0
fi

echo "Selected ${#selected_array[@]} commits. Generating report..."

# Clear previous output file
> "$OUTPUT_FILE"

echo "===== SELECTED COMMITS =====" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process each selected commit
for index in "${selected_array[@]}"; do
    # Get commit hash
    commit_hash="${commit_hashes[$index]}"
    
    echo "Processing commit: $commit_hash (${commit_subjects[$index]})..."
    
    # Add commit info to output file
    echo "COMMIT: $commit_hash" >> "$OUTPUT_FILE"
    echo "DATE: ${commit_dates[$index]}" >> "$OUTPUT_FILE"
    echo "SUBJECT: ${commit_subjects[$index]}" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Get the commit message
    echo "Commit Message:" >> "$OUTPUT_FILE"
    git log -1 --pretty=format:"%b" "$commit_hash" >> "$OUTPUT_FILE"
    echo -e "\n\n===== CHANGES =====\n" >> "$OUTPUT_FILE"
    
    # Get the diff and append to output file
    git show --pretty=format:"" --patch "$commit_hash" >> "$OUTPUT_FILE"
    
    # Add separator between commits
    echo -e "\n\n--------------------------------------------------------------\n\n" >> "$OUTPUT_FILE"
done

echo "Changes for ${#selected_array[@]} commits have been saved to $OUTPUT_FILE"

# Ask if user wants to send to Gemini
read -p "Would you like to send these changes to Gemini for analysis? (y/n): " send_to_gemini_confirm
if [[ "$send_to_gemini_confirm" == "y" || "$send_to_gemini_confirm" == "Y" ]]; then
    # Read the content and send to Gemini
    content=$(cat "$OUTPUT_FILE")
    send_to_gemini "$content"
    
else
    echo "You can now use $OUTPUT_FILE for generating PR documentation."
fi

# Function to create PR using GitHub CLI
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

# Ask if user wants to create a GitHub PR
read -p "Would you like to create a GitHub PR for these changes? (y/n): " create_pr_confirm
if [[ "$create_pr_confirm" == "y" || "$create_pr_confirm" == "Y" ]]; then
    # Create PR using the generated description
    description_file="${TEMP_DIR}/pr_description.md"
    create_github_pr "$description_file"
fi

echo "Script completed."
