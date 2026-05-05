# Thunder Plugin Interactive Generator

**Quick way to create Thunder plugin skeletons with 8 simple questions!**

## Overview

`New-ThunderPlugin.ps1` is an interactive PowerShell script that generates a complete Thunder plugin skeleton by asking 8 questions. It creates all necessary files following Thunder best practices and validation rules.

## Features

✅ **Interactive CLI** - Just answer 8 questions  
✅ **Smart Defaults** - Press Enter for common configurations  
✅ **Thunder Compliant** - Follows all validation rules from PluginQA  
✅ **Complete Skeleton** - Generates 6 essential files  
✅ **Validation Ready** - Output ready for `@thunder-checkpoint-review`

## Quick Start

```powershell
cd ThunderTools
.\New-ThunderPlugin.ps1
```

## The 8 Questions

### 1️⃣ Plugin Name
**What is your plugin name?**  
Example: `NetworkMonitor`, `DeviceInfo`, `BluetoothControl`  
Must be PascalCase, no spaces.

### 2️⃣ Process Type
**Should the plugin run out-of-process (OOP)?**  
- `OOP` = Separate process, more isolation, requires RPC
- `IP` = In-Process (default), same process, faster

### 3️⃣ Custom Interface
**Does your plugin define a custom COM interface?**  
- `Y` = You need a custom `IYourPlugin` interface
- `N` = Only using `IPlugin` (simple plugins)

### 4️⃣ JSON-RPC Support
**Enable JSON-RPC support?**  
- `Y` (default) = Allows external clients to call via JSON-RPC
- `N` = No external API needed

### 5️⃣ Configuration Class
**Does your plugin need a configuration class?**  
- `Y` (default) = Reads settings from `.conf.in` file
- `N` = No configuration needed

### 6️⃣ Notification/Observer Pattern
**Does your plugin send notifications/events?**  
- `Y` = Uses `Core::SinkType<>` for event callbacks
- `N` (default) = No notifications

### 7️⃣ Subsystem Dependencies
**Any subsystem dependencies?**  
Comma-separated list: `Network, Bluetooth, Security`  
Leave empty if none.

### 8️⃣ Output Directory
**Output directory for generated files?**  
Default: `./${PluginName}`  
Creates directory with all files.

## Generated Files

The script generates 6 files:

```
YourPlugin/
├── Module.h              # MODULE_NAME declaration
├── Module.cpp            # MODULE_NAME_DECLARATION
├── YourPlugin.h          # Plugin class header
├── YourPlugin.cpp        # Plugin implementation
├── CMakeLists.txt        # Build configuration
└── YourPlugin.conf.in    # Runtime configuration
```

## Example Session

```powershell
PS> .\New-ThunderPlugin.ps1

═══════════════════════════════════════════════════════════
  Thunder Plugin Skeleton Generator
  Interactive Mode - 8 Questions
═══════════════════════════════════════════════════════════

1️⃣  What is your plugin name? (e.g., NetworkMonitor)
   → Must be PascalCase, no spaces
   Plugin Name: NetworkMonitor

2️⃣  Should the plugin run out-of-process (OOP)?
   → OOP = Separate process, more isolation, requires RPC
   → In-Process (IP) = Same process, faster, shared memory
   Enter 'OOP' or 'IP' [default: IP]: OOP

3️⃣  Does your plugin define a custom COM interface?
   → YES if you need a custom IYourPlugin interface
   → NO if only using IPlugin (simple plugins)
   Custom interface? (Y/N) [default: N]: Y
   → What is the interface name? (e.g., INetworkMonitor)
   Interface Name: INetworkMonitor

4️⃣  Enable JSON-RPC support?
   → Allows external clients to call plugin via JSON-RPC
   → Creates Exchange::JNetworkMonitor wrapper
   Enable JSON-RPC? (Y/N) [default: Y]: Y

5️⃣  Does your plugin need a configuration class?
   → Reads settings from .conf.in file
   → Examples: storage paths, timeouts, feature flags
   Needs configuration? (Y/N) [default: Y]: Y

6️⃣  Does your plugin send notifications/events?
   → Uses Core::SinkType<> for event callbacks
   → Examples: state changes, data updates, errors
   Needs notifications? (Y/N) [default: N]: Y

7️⃣  Any subsystem dependencies? (comma-separated)
   → Examples: Network, Bluetooth, Security, Time
   → Leave empty if no dependencies
   Subsystems [default: none]: Network

8️⃣  Output directory for generated files?
   → Will create ./NetworkMonitor/ with all files
   Output path [default: ./NetworkMonitor]: 

═══════════════════════════════════════════════════════════
  Configuration Summary
═══════════════════════════════════════════════════════════
Plugin Name:        NetworkMonitor
Process Type:       Out-of-Process (OOP)
Custom Interface:   YES - INetworkMonitor
JSON-RPC:           Enabled
Configuration:      YES
Notifications:      YES
Subsystems:         Network
Output Directory:   .\NetworkMonitor

Proceed with generation? (Y/N): Y

🔨 Generating plugin skeleton...
✅ Created directory: .\NetworkMonitor
✅ Generated Module.h
✅ Generated Module.cpp
✅ Generated NetworkMonitor.h
✅ Generated NetworkMonitor.cpp
✅ Generated CMakeLists.txt
✅ Generated NetworkMonitor.conf.in

═══════════════════════════════════════════════════════════
  ✅ Plugin Skeleton Generated Successfully!
═══════════════════════════════════════════════════════════

Generated files in .\NetworkMonitor/:
  📄 Module.h
  📄 Module.cpp
  📄 NetworkMonitor.h
  📄 NetworkMonitor.cpp
  📄 CMakeLists.txt
  📄 NetworkMonitor.conf.in

📋 Next Steps:
  1. Review generated files
  2. Implement TODO sections in NetworkMonitor.cpp
  3. Define INetworkMonitor interface in ThunderInterfaces/
  4. Implement JSON-RPC methods in NetworkMonitor.cpp
  5. Add plugin to parent CMakeLists.txt
  6. Run validation: @thunder-checkpoint-review NetworkMonitor

🎯 Validation with Thunder QA:
  cd .\NetworkMonitor
  # Run automated checks:
  @thunder-checkpoint-review NetworkMonitor

✨ Happy Thunder Plugin Development!
```

## What Gets Generated

### Key Features

✅ **Module.h** with `#pragma once` (checkpoint module_1_4)  
✅ **MODULE_NAME** with `Plugin_` prefix (checkpoint module_1_2)  
✅ **MODULE_NAME_DECLARATION** in Module.cpp (checkpoint module_1_3)  
✅ **Deleted special members** (checkpoint registration_3_3)  
✅ **IPlugin in interface map** (checkpoint registration_3_2)  
✅ **Metadata registration** (checkpoint registration_3_4)  
✅ **Initialize with ASSERT** (checkpoint lifecycle_4_1)  
✅ **IShell AddRef/Release** (checkpoint lifecycle_4_2)  
✅ **Constructor only initializes** (checkpoint lifecycle_4_9)  
✅ **Destructor = default** (checkpoint lifecycle_4_10)  
✅ **JSON-RPC Register/Unregister paired** (checkpoint implementation_5_2)  
✅ **Config stack-local** (checkpoint implementation_5_3)  
✅ **OOP connection->Terminate()** (checkpoint oop_9_1)  
✅ **CMake structure** (checkpoints cmake_7_1, cmake_7_3)

### Thunder Best Practices

- Uses `Core::CriticalSection` for thread safety
- Uses `Core::SinkType<>` for notifications (if enabled)
- Config class inherits from `Core::JSON::Container`
- Proper AddRef/Release pattern for IShell*
- OOP-specific connection termination (if OOP)
- Subsystem dependencies in Metadata
- JSON-RPC registration/unregistration symmetry

## Validation

After generation, validate with Thunder QA:

```powershell
cd YourPlugin
@thunder-checkpoint-review YourPlugin
```

Expected results:
- ✅ **25+ PASS** on automated checkpoints
- ⚠️ **Few TODOs** to implement (marked in code)
- ✅ **Clean structure** ready for implementation

## Integration with Thunder Build

Add to parent `CMakeLists.txt`:

```cmake
add_subdirectory(YourPlugin)
```

Build:

```bash
cd build
cmake ..
make Plugin_YourPlugin
```

## Comparison with Existing Generator

| Feature | `New-ThunderPlugin.ps1` | `PluginSkeletonGenerator.py` |
|---------|-------------------------|------------------------------|
| **Language** | PowerShell | Python |
| **Interaction** | 8 questions, interactive | Config file + CLI args |
| **Setup** | None (Windows built-in) | Requires Python + dependencies |
| **Speed** | Instant | Slower (Python startup) |
| **Validation** | Passes 25+ Thunder QA checks | Unknown compliance |
| **OOP Support** | ✅ Yes | ✅ Yes |
| **JSON-RPC** | ✅ Auto-generated | ❓ Unknown |
| **Notifications** | ✅ Core::SinkType pattern | ❓ Unknown |

## Troubleshooting

### Execution Policy Error
```powershell
# If you get "execution policy" error:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### File Already Exists
Script will **not overwrite** existing directories. Delete or rename first:
```powershell
Remove-Item -Recurse -Force .\YourPlugin
.\New-ThunderPlugin.ps1
```

## Advanced Usage

### Silent Mode (Future Enhancement)
```powershell
# TODO: Add parameter-based non-interactive mode
.\New-ThunderPlugin.ps1 -PluginName "MyPlugin" -ProcessType IP -JsonRpc $true
```

### Template Customization
Edit the script's `$pluginH`, `$pluginCpp` sections to customize generated code.

## Related Tools

- **Thunder QA Validation:** `ThunderTools/PluginQA/prompts/thunder-checkpoint-review.prompt.md`
- **Python Generator:** `ThunderTools/PluginSkeletonGenerator/PluginSkeletonGenerator.py`
- **Rule Reference:** `ThunderTools/PluginQA/rules/thunder-plugin-rules.yaml`

## Contributing

Improvements welcome! Follow Thunder best practices:
- Add validation checkpoints from `thunder-plugin-rules-checkpoints.yaml`
- Test generated code with `@thunder-checkpoint-review`
- Update this README with new features

## License

Same as Thunder framework (Apache 2.0)

---

**Created:** May 5, 2026  
**Version:** 1.0.0  
**Author:** Thunder Plugin QA Team
