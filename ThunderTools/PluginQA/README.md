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
│   ├── thunder-review.prompt.md           # Comprehensive review (36+ checks)
│   ├── thunder-checkpoint-review.prompt.md # Bounded query validation (17 checks)
│   ├── thunder-generate.prompt.md
│   ├── thunder-pattern.prompt.md
│   └── thunder-interface.prompt.md
├── rules/                       # Plugin review rules
│   ├── README.md                # Rules documentation
│   ├── thunder-plugin-rules.yaml # ⭐ Comprehensive YAML (36+ checks)
│   ├── thunder-plugin-rules-checkpoints.yaml # ⭐ Bounded query YAML (17 checks)
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

### `/thunder-review` - Comprehensive Plugin Review
Full systematic review covering 36+ checks across 7 phases.

**Usage:**
- Open a plugin file (`.cpp` or `.h`)
- Type `/thunder-review` in Copilot Chat
- Get comprehensive validation report

**Output:**
- Architecture analysis (IP/OOP, JSON-RPC, config detection)
- 7-phase checklist results
- Violations with line numbers, explanations, and fixes
- Warnings and suggestions

**Best for:** Complete plugin validation, compliance checking, pre-commit review

---

### `/thunder-checkpoint-review` - Bounded Query Validation
Focused checkpoint-based review using bounded AI queries for precise, verifiable validation.

**Usage:**
- Same as `/thunder-review`
- Get checkpoint-by-checkpoint verification

**Methodology:**
- **Bounded queries**: Each checkpoint = 1 code block + 1 yes/no question
- **17 focused checks** (key violations only)
- **Verifiable**: Every finding cites exact line from extracted code
- **Actionable**: Targeted fixes for specific blocks

**Example:**
```
Checkpoint 4.1: Initialize ASSERT
Extract: Initialize() body (lines 108-125)
Question: "Is first statement 'ASSERT(service != nullptr);'?"
Answer: No
Citation: [Dictionary.cpp:108] Missing ASSERT
Fix: Add ASSERT(service != nullptr); as first line
```

**Best for:** Precise verification, debugging specific issues, learning Thunder rules

---

### Comparison

| Aspect | Comprehensive | Checkpoint |
|--------|---------------|------------|
| Checks | 36+ | 17 focused |
| Approach | Whole-file | Bounded extraction |
| Output | Full report | Per-checkpoint |
| Speed | Thorough | Faster |

---

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

The tool validates plugins against Thunder development standards available in **two formats**:

### YAML Format (Machine-Readable)
- **thunder-plugin-rules.yaml** - Comprehensive, structured rule set with:
  - 7 review phases with 36+ checks
  - Architecture detection patterns
  - Verification templates
  - Common mistakes mappings
  - Rule citation guide

### Markdown Format (Human-Readable)

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

**Both formats contain the same rules** - YAML is used by the review tool, Markdown is for human reference.

See [rules/README.md](rules/README.md) for detailed YAML structure documentation.

## Development

### Adding New Rules

When adding or updating rules:

1. **Update Markdown files** in `rules/` for human readability:
   - Include frontmatter with `applyTo` glob pattern
   - Document rules with examples
   ```yaml
   ---
   applyTo: '**/*.cpp'
   ---
   ```

2. **Update YAML file** (`thunder-plugin-rules.yaml`) for tool consistency:
   - Add check to appropriate phase
   - Include verification steps
   - Update common_mistakes if applicable
   - Increment metadata.version

3. **Test changes**:
   - Run `/thunder-review` on sample plugins
   - Verify accuracy and no false positives

### Customizing Prompts

Edit the `.prompt.md` files in the `prompts/` directory to customize the AI behavior for each command.

## Support

For issues or questions:
- Check the [Thunder documentation](https://github.com/rdkcentral/Thunder)
- Review the rules in the `rules/` directory
- Open an issue in the Thunder repository

## License

This tool follows the same license as Thunder (Apache 2.0).
