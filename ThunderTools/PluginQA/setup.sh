#!/bin/bash
################################################################################
# Thunder Plugin Quality Assurance Tool Setup Script
#
# This script configures VS Code to enable Thunder plugin review commands
# by adding the PluginQA prompts directory to chat.promptFilesLocations.
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_header() {
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
    echo
}

# Function to find VS Code settings file
find_vscode_settings() {
    local workspace_settings=".vscode/settings.json"
    local user_settings=""
    
    # Check for workspace settings first
    if [ -d ".vscode" ]; then
        echo "$workspace_settings"
        return
    fi
    
    # Determine user settings location based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        user_settings="$HOME/Library/Application Support/Code/User/settings.json"
    else
        # Linux
        user_settings="$HOME/.config/Code/User/settings.json"
    fi
    
    if [ -f "$user_settings" ]; then
        echo "$user_settings"
    else
        echo "$workspace_settings"
    fi
}

# Function to get the prompts path
get_prompts_path() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local prompts_dir="$script_dir/prompts"
    
    # Get workspace root (assuming it's parent of ThunderTools)
    local workspace_root="$(cd "$script_dir/../.." && pwd)"
    
    # Calculate relative path
    local rel_path=$(python3 -c "import os.path; print(os.path.relpath('$prompts_dir', '$workspace_root'))" 2>/dev/null || echo "ThunderTools/PluginQA/prompts")
    
    # Convert to forward slashes
    echo "$rel_path" | sed 's/\\/\//g'
}

# Function to update settings.json using Python
update_settings() {
    local settings_file="$1"
    local prompts_path="$2"
    
    python3 << EOF
import json
import os
from pathlib import Path

settings_file = Path("$settings_file")
prompts_path = "$prompts_path"

# Load existing settings
settings = {}
if settings_file.exists():
    try:
        with open(settings_file, 'r', encoding='utf-8') as f:
            content = f.read()
            # Simple comment removal for JSONC
            lines = []
            for line in content.split('\n'):
                if '//' in line:
                    line = line[:line.index('//')]
                lines.append(line)
            content = '\n'.join(lines)
            settings = json.loads(content)
    except json.JSONDecodeError:
        pass

# Ensure chat.promptFilesLocations exists
if 'chat.promptFilesLocations' not in settings:
    settings['chat.promptFilesLocations'] = {}

# Add our prompts directory
settings['chat.promptFilesLocations'][prompts_path] = True

# Save settings
settings_file.parent.mkdir(parents=True, exist_ok=True)
with open(settings_file, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print("OK")
EOF
}

# Main setup function
main() {
    print_header "Thunder Plugin Quality Assurance Tool - Setup"
    
    # Check if Python3 is available
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is required but not found"
        print_info "Please install Python3 and try again"
        exit 1
    fi
    
    # Find settings file
    local settings_file=$(find_vscode_settings)
    local settings_type="workspace"
    if [[ "$settings_file" == *"$HOME"* ]]; then
        settings_type="user"
    fi
    
    print_info "Using $settings_type settings: $settings_file"
    echo
    
    # Get prompts path
    local prompts_path=$(get_prompts_path)
    
    # Create backup if settings file exists
    if [ -f "$settings_file" ]; then
        cp "$settings_file" "$settings_file.backup"
        print_info "Created backup: $settings_file.backup"
    fi
    
    # Update settings
    local result=$(update_settings "$settings_file" "$prompts_path")
    
    if [ "$result" == "OK" ]; then
        print_success "Successfully configured VS Code settings"
        echo
        print_info "Added prompt location: $prompts_path"
        echo
        echo "Available commands in VS Code Copilot Chat:"
        echo "  /thunder-review     - Review a Thunder plugin against development rules"
        echo "  /thunder-generate   - Generate a new Thunder plugin skeleton"
        echo "  /thunder-pattern    - Get Thunder-specific code patterns"
        echo "  /thunder-interface  - Validate COM interface definitions"
        echo
        print_warning "Restart VS Code to activate the new commands."
        echo
    else
        print_error "Failed to update settings"
        exit 1
    fi
    
    print_header "Setup Complete"
}

# Run main function
main
