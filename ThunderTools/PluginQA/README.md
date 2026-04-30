# Thunder Plugin Quality Assurance Tool

A comprehensive AI-assisted tool for reviewing and validating Thunder plugins against established development rules and best practices.

## Overview

This tool provides automated plugin quality checks for ThunderNanoServices plugins through:
- **VS Code Copilot Integration**: Slash commands for interactive plugin review
- **Automated Rules Checking**: Validates plugins against Thunder development standards
- **Developer-Friendly**: Works within your normal VS Code workflow

## Directory Structure

```
PluginQA/
├── README.md                    # This file
├── prompts/                     # VS Code Copilot prompt files
│   ├── thunder-review.prompt.md
│   ├── thunder-generate.prompt.md
│   ├── thunder-pattern.prompt.md
│   └── thunder-interface.prompt.md
├── rules/                       # Plugin review rules
│   ├── 10-plugin-development.md
│   ├── 10.1-plugin-module.md
│   ├── 10.2-plugin-codestyle.md
│   ├── 10.3-plugin-class-registration.md
│   ├── 10.4-plugin-lifecycle.md
│   ├── 10.5-plugin-implementation.md
│   ├── 10.6-plugin-config.md
│   └── 10.7-plugin-cmake.md
├── setup.py                     # Python setup script
└── setup.sh                     # Shell setup script
```

## Quick Start

### Automatic Setup

Run the setup script to configure VS Code settings automatically:

**Windows (PowerShell):**
```powershell
python setup.py
```

**Linux/Mac:**
```bash
./setup.sh
```

### Manual Setup

Add this to your VS Code `settings.json`:

```json
{
  "chat.promptFilesLocations": {
    "ThunderTools/PluginQA/prompts": true
  }
}
```

## Available Commands

Once configured, use these commands in VS Code Copilot Chat:

### `/thunder-review`
Review a plugin against Thunder development rules.

**Usage:**
- Open a plugin file (`.cpp` or `.h`)
- Type `/thunder-review` in Copilot Chat
- Get detailed feedback on rule violations and suggestions

### `/thunder-generate`
Generate a new plugin skeleton using PluginSkeletonGenerator.

**Usage:**
- Type `/thunder-generate` in Copilot Chat
- Answer the prompts about your plugin
- Get a generated plugin structure

### `/thunder-pattern`
Get Thunder-specific code patterns and examples.

**Usage:**
- Type `/thunder-pattern` in Copilot Chat
- Describe what pattern you need
- Receive canonical Thunder implementation examples

### `/thunder-interface`
Validate COM interface definitions.

**Usage:**
- Open an interface header file
- Type `/thunder-interface` in Copilot Chat
- Get validation feedback on interface structure

## Rules Reference

The tool validates plugins against these rule categories:

| Rule File | Focus Area |
|-----------|------------|
| `10-plugin-development.md` | Overall plugin development checklist |
| `10.1-plugin-module.md` | Module.h and Module.cpp requirements |
| `10.2-plugin-codestyle.md` | Code style, copyright, naming conventions |
| `10.3-plugin-class-registration.md` | IPlugin implementation and registration |
| `10.4-plugin-lifecycle.md` | Initialize/Deinitialize lifecycle rules |
| `10.5-plugin-implementation.md` | Internal implementation patterns |
| `10.6-plugin-config.md` | Plugin configuration file format |
| `10.7-plugin-cmake.md` | CMake build integration |

## Development

### Adding New Rules

1. Create a new markdown file in `rules/`
2. Include frontmatter with `applyTo` glob pattern:
   ```yaml
   ---
   applyTo: '**/*.cpp'
   ---
   ```
3. Document the rules with examples

### Customizing Prompts

Edit the `.prompt.md` files in the `prompts/` directory to customize the AI behavior for each command.

## Support

For issues or questions:
- Check the [Thunder documentation](https://github.com/rdkcentral/Thunder)
- Review the rules in the `rules/` directory
- Open an issue in the Thunder repository

## License

This tool follows the same license as Thunder (Apache 2.0).
