#!/usr/bin/env python3
"""
Thunder Plugin Quality Assurance Tool Setup Script

This script configures VS Code to enable Thunder plugin review commands
by adding the PluginQA prompts directory to chat.promptFilesLocations.
"""

import json
import os
import sys
from pathlib import Path


def find_vscode_settings_file():
    """
    Find the VS Code settings.json file.
    Checks both workspace and user settings locations.
    """
    # Check for workspace settings first
    workspace_settings = Path('.vscode/settings.json')
    if workspace_settings.parent.exists():
        return workspace_settings, 'workspace'
    
    # Check for user settings based on OS
    if sys.platform == 'win32':
        user_settings = Path(os.environ.get('APPDATA', '')) / 'Code' / 'User' / 'settings.json'
    elif sys.platform == 'darwin':
        user_settings = Path.home() / 'Library' / 'Application Support' / 'Code' / 'User' / 'settings.json'
    else:  # Linux
        user_settings = Path.home() / '.config' / 'Code' / 'User' / 'settings.json'
    
    if user_settings.exists():
        return user_settings, 'user'
    
    # Default to workspace settings
    return workspace_settings, 'workspace'


def load_settings(settings_file):
    """Load existing settings from settings.json, or return empty dict if file doesn't exist."""
    if settings_file.exists():
        try:
            with open(settings_file, 'r', encoding='utf-8') as f:
                # Handle JSON with comments (JSONC)
                content = f.read()
                # Simple comment removal (not perfect but works for most cases)
                lines = []
                for line in content.split('\n'):
                    # Remove // comments
                    if '//' in line:
                        line = line[:line.index('//')]
                    lines.append(line)
                content = '\n'.join(lines)
                return json.loads(content)
        except json.JSONDecodeError as e:
            print(f"Warning: Could not parse existing settings.json: {e}")
            print("Creating backup and starting fresh...")
            # Create backup
            backup = settings_file.with_suffix('.json.backup')
            settings_file.rename(backup)
            print(f"Backup saved to: {backup}")
            return {}
    return {}


def save_settings(settings_file, settings):
    """Save settings to settings.json with proper formatting."""
    # Ensure parent directory exists
    settings_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(settings_file, 'w', encoding='utf-8') as f:
        json.dump(settings, f, indent=2)
        f.write('\n')  # Add trailing newline


def get_prompt_path():
    """Get the relative path to the PluginQA prompts directory."""
    # Get the current script location
    script_dir = Path(__file__).parent
    
    # Assuming script is in ThunderTools/PluginQA/
    # The prompts are in ThunderTools/PluginQA/prompts/
    prompts_path = script_dir / 'prompts'
    
    # Get relative path from workspace root
    # Assuming workspace root is parent of ThunderTools
    workspace_root = script_dir.parent.parent
    try:
        relative_path = prompts_path.relative_to(workspace_root)
        # Convert to forward slashes for VS Code
        return str(relative_path).replace('\\', '/')
    except ValueError:
        # If relative path calculation fails, use absolute path
        return str(prompts_path).replace('\\', '/')


def update_prompt_locations(settings):
    """Add PluginQA prompts directory to chat.promptFilesLocations."""
    prompt_path = get_prompt_path()
    
    # Ensure chat.promptFilesLocations exists
    if 'chat.promptFilesLocations' not in settings:
        settings['chat.promptFilesLocations'] = {}
    
    # Add our prompts directory
    settings['chat.promptFilesLocations'][prompt_path] = True
    
    return prompt_path


def main():
    """Main setup function."""
    print("=" * 70)
    print("Thunder Plugin Quality Assurance Tool - Setup")
    print("=" * 70)
    print()
    
    # Find settings file
    settings_file, settings_type = find_vscode_settings_file()
    print(f"Using {settings_type} settings: {settings_file}")
    print()
    
    # Load existing settings
    settings = load_settings(settings_file)
    
    # Update prompt locations
    prompt_path = update_prompt_locations(settings)
    
    # Save updated settings
    save_settings(settings_file, settings)
    
    print("✓ Successfully configured VS Code settings")
    print()
    print(f"Added prompt location: {prompt_path}")
    print()
    print("Available commands in VS Code Copilot Chat:")
    print("  /thunder-review     - Review a Thunder plugin against development rules")
    print("  /thunder-generate   - Generate a new Thunder plugin skeleton")
    print("  /thunder-pattern    - Get Thunder-specific code patterns")
    print("  /thunder-interface  - Validate COM interface definitions")
    print()
    print("Restart VS Code to activate the new commands.")
    print()
    print("=" * 70)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nSetup cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\nError during setup: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
