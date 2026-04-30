# Thunder Plugin QA Tool - Usage Guide

This guide explains how to use the Thunder Plugin Quality Assurance Tool for reviewing and validating Thunder plugins.

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Commands Reference](#commands-reference)
4. [Rules Reference](#rules-reference)
5. [Examples](#examples)
6. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites

- VS Code with GitHub Copilot extension installed
- Python 3.x (for setup scripts)
- Thunder workspace with ThunderNanoServices

### Setup Steps

#### Windows

```powershell
# Navigate to the PluginQA directory
cd ThunderTools\PluginQA

# Run setup (choose one):
# Option 1: Using batch file
setup.bat

# Option 2: Using Python directly
python setup.py
```

#### Linux/Mac

```bash
# Navigate to the PluginQA directory
cd ThunderTools/PluginQA

# Make the script executable
chmod +x setup.sh

# Run setup
./setup.sh
```

### What the Setup Does

The setup script:
1. Locates your VS Code settings file (workspace or user)
2. Adds `ThunderTools/PluginQA/prompts` to `chat.promptFilesLocations`
3. Creates a backup of your existing settings
4. Configures the tool for immediate use

After setup, **restart VS Code** to activate the commands.

---

## Configuration

### Manual Configuration

If you prefer to configure manually, add this to your `.vscode/settings.json`:

```json
{
  "chat.promptFilesLocations": {
    "ThunderTools/PluginQA/prompts": true
  }
}
```

### Verification

After restarting VS Code, open Copilot Chat and type `/`. You should see the Thunder commands:
- `/thunder-review`
- `/thunder-generate`
- `/thunder-pattern`
- `/thunder-interface`

---

## Commands Reference

### `/thunder-review` - Plugin Review

**Purpose**: Analyze a Thunder plugin against development rules

**Usage**:
1. Open a plugin file (e.g., `MyPlugin.cpp`, `Module.h`)
2. Open Copilot Chat (Ctrl+Alt+I or Cmd+Option+I)
3. Type `/thunder-review`
4. The AI will analyze the file and report findings

**Output Format**:
- 🔴 **Violations**: Critical issues that must be fixed
- 🟡 **Warnings**: Best practice issues that should be addressed
- 🟢 **Suggestions**: Nice-to-have improvements
- ✅ **Passes**: Rules that are correctly followed

**Example**:
```
User: /thunder-review

AI: Analyzing NetworkMonitor.cpp against Thunder rules...

### 🔴 Violations (Must Fix)
- [NetworkMonitor.cpp:45] _service stored without AddRef() - Rule: 10.4
  Fix: Add _service->AddRef(); after assignment

### 🟡 Warnings (Should Fix)
- [NetworkMonitor.h:28] RegisterAll() in constructor - Rule: 10.4
  Move JSONRPC registration to Initialize() method

### ✅ Passes
- Module name follows Plugin_ prefix ✓
- Copyright header present ✓
- Interface map complete ✓
```

---

### `/thunder-generate` - Generate Plugin Skeleton

**Purpose**: Create a new Thunder plugin using PluginSkeletonGenerator

**Usage**:
1. Open Copilot Chat
2. Type `/thunder-generate`
3. Answer the prompts about your plugin

**Questions Asked**:
- Plugin name
- Process mode (OOP/IP)
- Interface path
- Subsystems (optional)
- Additional features (optional)

**What It Does**:
1. Gathers requirements through conversation
2. Locates PluginSkeletonGenerator tool
3. Generates the plugin skeleton
4. Automatically reviews the generated code
5. Provides next steps

**Example**:
```
User: /thunder-generate

AI: What is your plugin name?

User: NetworkMonitor

AI: Should it run out-of-process (OOP) or in-process (IP)?

User: OOP

AI: Path to your interface header?

User: ThunderInterfaces/interfaces/INetworkMonitor.h

AI: Generating plugin skeleton...
   [Shows generated file tree]
   Now reviewing generated code...
   [Shows review results]
```

---

### `/thunder-pattern` - Get Code Patterns

**Purpose**: Get canonical Thunder implementation patterns

**Usage**:
1. Open Copilot Chat
2. Type `/thunder-pattern` followed by what you need
3. Receive Thunder-specific code examples

**Common Patterns**:
- IShell lifecycle management
- JSON-RPC registration/notification
- Interface AddRef/Release
- Thread-safe implementations
- Configuration parsing

**Example**:
```
User: /thunder-pattern How do I notify JSON-RPC clients?

AI: ## Pattern: JSON-RPC Event Notification

**When to use**: When your plugin needs to send events to clients

**Code**:
```cpp
// In Initialize():
_service->Register(&_notification);

// When notifying:
Exchange::JMyPlugin::Event::StatusChanged(*this, newStatus);

// In Deinitialize():
_service->Unregister(&_notification);
```

**Key points**:
- Always Register in Initialize(), Unregister in Deinitialize()
- Use Exchange::J* namespace for JSON-RPC events
- Thread-safe by default

**Rule reference**: 10.5 - Implementation Patterns
```

---

### `/thunder-interface` - Validate Interface

**Purpose**: Validate COM interface definitions

**Usage**:
1. Open an interface header file (e.g., `IMyPlugin.h`)
2. Open Copilot Chat
3. Type `/thunder-interface`

**Checks Performed**:
- EXTERNAL macro presence
- Return types (should be uint32_t)
- Parameter annotations (@in, @out, @inout)
- Virtual methods and IUnknown inheritance
- Interface ID registration
- Method signatures

**Example**:
```
User: /thunder-interface

AI: Validating INetworkMonitor interface...

### 🔴 Violations
- [INetworkMonitor.h:15] Missing EXTERNAL macro
- [INetworkMonitor.h:28] Method returns bool instead of uint32_t
- [INetworkMonitor.h:32] Missing @out annotation

### ✅ Validated
- Virtual inheritance from IUnknown ✓
- All methods are virtual ✓
- Copyright header correct ✓
```

---

## Rules Reference

The tool validates plugins against these rule documents:

| Rule | Focus Area | Key Requirements |
|------|-----------|------------------|
| **10-plugin-development.md** | Overall checklist | Plugin structure, development workflow |
| **10.1-plugin-module.md** | Module files | MODULE_NAME, Module.h/cpp structure |
| **10.2-plugin-codestyle.md** | Code style | Copyright headers, naming, formatting |
| **10.3-plugin-class-registration.md** | Plugin class | IPlugin implementation, metadata registration |
| **10.4-plugin-lifecycle.md** | Lifecycle | Initialize/Deinitialize patterns |
| **10.5-plugin-implementation.md** | Internal patterns | Notifications, threading, memory management |
| **10.6-plugin-config.md** | Configuration | .conf.in file format and structure |
| **10.7-plugin-cmake.md** | Build system | CMakeLists.txt structure and registration |

### Quick Rule Reference

**Module Structure**:
- MODULE_NAME must have `Plugin_` prefix
- Module.h must be first include in all .cpp files
- MODULE_NAME_DECLARATION in Module.cpp

**Lifecycle**:
- AddRef() when storing IShell*
- Release() in Deinitialize() (reverse order)
- All registration in Initialize(), unregister in Deinitialize()
- No logic in constructor/destructor

**Code Style**:
- Apache 2.0 copyright header required
- Use Thunder types (string, not std::string)
- Follow naming conventions (PascalCase for classes)

**Interfaces**:
- EXTERNAL macro required
- Return uint32_t for methods
- Parameter annotations required (@in, @out)
- Virtual inheritance from IUnknown

---

## Examples

### Example 1: Reviewing an Existing Plugin

```bash
# Open the plugin file in VS Code
code ThunderNanoServices/NetworkControl/NetworkControl.cpp

# In Copilot Chat:
User: /thunder-review

# AI analyzes the file and provides feedback
# Fix any violations reported
# Run review again to verify fixes
```

### Example 2: Creating a New Plugin

```bash
# In Copilot Chat:
User: /thunder-generate

# Follow the conversation:
AI: What is your plugin name?
User: SystemMonitor

AI: Should it run OOP or IP?
User: OOP

AI: Interface path?
User: ThunderInterfaces/interfaces/ISystemMonitor.h

# AI generates the skeleton and reviews it
# You get a ready-to-customize plugin structure
```

### Example 3: Getting a Specific Pattern

```bash
# In Copilot Chat:
User: /thunder-pattern How do I properly manage IShell lifetime?

# AI provides the canonical pattern:
# - Shows AddRef/Release pattern
# - Explains Initialize/Deinitialize usage
# - Provides complete code example
# - References relevant rules
```

### Example 4: Interface Validation

```bash
# Open your interface header
code ThunderInterfaces/interfaces/IMyNewInterface.h

# In Copilot Chat:
User: /thunder-interface

# AI validates:
# - Structure and macros
# - Method signatures
# - Parameter annotations
# - ID registration
```

---

## Troubleshooting

### Commands Not Appearing

**Problem**: Thunder commands don't show up in Copilot Chat

**Solutions**:
1. Verify setup was successful:
   ```bash
   cat .vscode/settings.json | grep promptFilesLocations
   ```
2. Restart VS Code completely
3. Check that GitHub Copilot extension is installed and activated
4. Run setup script again
5. Check VS Code settings UI: Search for "prompt files" in settings

### Rules Not Loading

**Problem**: AI doesn't seem to use the rules

**Solutions**:
1. Verify rules exist:
   ```bash
   ls ThunderTools/PluginQA/rules/
   ```
2. Check file permissions (Linux/Mac):
   ```bash
   chmod -R +r ThunderTools/PluginQA/rules/
   ```
3. Explicitly mention the rule in your query:
   ```
   /thunder-review using rule 10.4
   ```

### Python Not Found

**Problem**: Setup script fails with "Python not found"

**Solutions**:
1. Install Python 3: https://www.python.org/downloads/
2. Ensure Python is in PATH
3. Windows: Use `python` or `py` command
4. Linux/Mac: Use `python3` command

### Setup Script Permission Denied (Linux/Mac)

**Problem**: `./setup.sh: Permission denied`

**Solution**:
```bash
chmod +x setup.sh
./setup.sh
```

### Manual Configuration

If automated setup fails, configure manually:

1. Open VS Code settings (Ctrl+, or Cmd+,)
2. Click "Open Settings (JSON)" icon (top-right)
3. Add:
   ```json
   {
     "chat.promptFilesLocations": {
       "ThunderTools/PluginQA/prompts": true
     }
   }
   ```
4. Save and restart VS Code

---

## Tips and Best Practices

1. **Run review early**: Use `/thunder-review` during development, not just at the end
2. **Learn patterns**: Use `/thunder-pattern` to understand Thunder conventions
3. **Validate interfaces first**: Run `/thunder-interface` before implementing
4. **Iterative fixes**: Fix violations one at a time and re-review
5. **Combine with generation**: Let `/thunder-generate` create the boilerplate correctly
6. **Reference rules**: Check the rules/ directory for detailed explanations
7. **Context matters**: Open relevant files before running commands for better results

---

## Getting Help

- **Rules Documentation**: Check `ThunderTools/PluginQA/rules/`
- **Thunder Docs**: https://github.com/rdkcentral/Thunder
- **Issues**: Report problems in the Thunder GitHub repository
- **Examples**: Look at existing plugins in ThunderNanoServices

---

## Contributing

To add new rules or improve prompts:

1. **Add Rules**: Create new .md files in `rules/` with frontmatter:
   ```yaml
   ---
   applyTo: '**/*.cpp'
   ---
   # Rule Title
   [Content]
   ```

2. **Update Prompts**: Edit .prompt.md files in `prompts/`

3. **Test Changes**: Run commands and verify AI behavior

4. **Share**: Submit pull requests with improvements

---

*Thunder Plugin QA Tool - Making plugin development easier and more consistent*
