<#
.SYNOPSIS
    Interactive Thunder Plugin Skeleton Generator

.DESCRIPTION
    Creates a basic Thunder plugin skeleton by asking 8 questions.
    Generates all necessary files following Thunder best practices.

.EXAMPLE
    .\New-ThunderPlugin.ps1

.NOTES
    Version: 1.0.0
    Date: May 5, 2026
    Based on Thunder Plugin Development Rules (10-plugin-development.md)
#>

param()

# Color output functions
function Write-Question {
    param([string]$Message)
    Write-Host "`n$Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

# Banner
Clear-Host
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Thunder Plugin Skeleton Generator" -ForegroundColor Magenta
Write-Host "  Interactive Mode - 8 Questions" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta

# Question 1: Plugin Name
Write-Question "1️⃣  What is your plugin name? (e.g., NetworkMonitor)"
Write-Info "   → Must be PascalCase, no spaces"
$pluginName = Read-Host "   Plugin Name"

if ([string]::IsNullOrWhiteSpace($pluginName)) {
    Write-Error "❌ Plugin name cannot be empty!"
    exit 1
}

# Question 2: Process Type
Write-Question "2️⃣  Should the plugin run out-of-process (OOP)?"
Write-Info "   → OOP = Separate process, more isolation, requires RPC"
Write-Info "   → In-Process (IP) = Same process, faster, shared memory"
$processType = Read-Host "   Enter 'OOP' or 'IP' [default: IP]"

if ([string]::IsNullOrWhiteSpace($processType)) {
    $processType = "IP"
}
$isOOP = $processType.ToUpper() -eq "OOP"

# Question 3: Custom Interface
Write-Question "3️⃣  Does your plugin define a custom COM interface?"
Write-Info "   → YES if you need a custom IYourPlugin interface"
Write-Info "   → NO if only using IPlugin (simple plugins)"
$hasInterface = Read-Host "   Custom interface? (Y/N) [default: N]"
$hasCustomInterface = $hasInterface.ToUpper() -eq "Y"

$interfaceName = ""
if ($hasCustomInterface) {
    Write-Info "   → What is the interface name? (e.g., INetworkMonitor)"
    $interfaceName = Read-Host "   Interface Name"
}

# Question 4: JSON-RPC Support
Write-Question "4️⃣  Enable JSON-RPC support?"
Write-Info "   → Allows external clients to call plugin via JSON-RPC"
Write-Info "   → Creates Exchange::J${pluginName} wrapper"
$jsonRpc = Read-Host "   Enable JSON-RPC? (Y/N) [default: Y]"
$enableJsonRpc = [string]::IsNullOrWhiteSpace($jsonRpc) -or $jsonRpc.ToUpper() -eq "Y"

# Question 5: Configuration Class
Write-Question "5️⃣  Does your plugin need a configuration class?"
Write-Info "   → Reads settings from .conf.in file"
Write-Info "   → Examples: storage paths, timeouts, feature flags"
$needsConfig = Read-Host "   Needs configuration? (Y/N) [default: Y]"
$hasConfig = [string]::IsNullOrWhiteSpace($needsConfig) -or $needsConfig.ToUpper() -eq "Y"

# Question 6: Notification/Observer Pattern
Write-Question "6️⃣  Does your plugin send notifications/events?"
Write-Info "   → Uses Core::SinkType<> for event callbacks"
Write-Info "   → Examples: state changes, data updates, errors"
$needsNotif = Read-Host "   Needs notifications? (Y/N) [default: N]"
$hasNotifications = $needsNotif.ToUpper() -eq "Y"

# Question 7: Subsystem Dependencies
Write-Question "7️⃣  Any subsystem dependencies? (comma-separated)"
Write-Info "   → Examples: Network, Bluetooth, Security, Time"
Write-Info "   → Leave empty if no dependencies"
$subsystems = Read-Host "   Subsystems [default: none]"
$subsystemList = if ([string]::IsNullOrWhiteSpace($subsystems)) { @() } else { $subsystems -split ',' | ForEach-Object { $_.Trim() } }

# Question 8: Output Directory
Write-Question "8️⃣  Output directory for generated files?"
Write-Info "   → Will create ./${pluginName}/ with all files"
$outputDir = Read-Host "   Output path [default: ./${pluginName}]"

if ([string]::IsNullOrWhiteSpace($outputDir)) {
    $outputDir = ".\${pluginName}"
}

# Summary
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Configuration Summary" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Info "Plugin Name:        $pluginName"
Write-Info "Process Type:       $(if ($isOOP) { 'Out-of-Process (OOP)' } else { 'In-Process (IP)' })"
Write-Info "Custom Interface:   $(if ($hasCustomInterface) { "YES - $interfaceName" } else { 'NO' })"
Write-Info "JSON-RPC:           $(if ($enableJsonRpc) { 'Enabled' } else { 'Disabled' })"
Write-Info "Configuration:      $(if ($hasConfig) { 'YES' } else { 'NO' })"
Write-Info "Notifications:      $(if ($hasNotifications) { 'YES' } else { 'NO' })"
Write-Info "Subsystems:         $(if ($subsystemList.Count -gt 0) { $subsystemList -join ', ' } else { 'None' })"
Write-Info "Output Directory:   $outputDir"

$confirm = Read-Host "`nProceed with generation? (Y/N)"
if ($confirm.ToUpper() -ne "Y") {
    Write-Info "❌ Generation cancelled."
    exit 0
}

# Create output directory
Write-Host "`n🔨 Generating plugin skeleton..." -ForegroundColor Green
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Success "✅ Created directory: $outputDir"
}

# Generate Module.h
$moduleH = @"
#pragma once

#ifndef MODULE_NAME
#define MODULE_NAME Plugin_${pluginName}
#endif

#include <core/core.h>
#include <plugins/plugins.h>

#undef EXTERNAL
#define EXTERNAL

"@

$moduleH | Out-File -FilePath "$outputDir\Module.h" -Encoding UTF8
Write-Success "✅ Generated Module.h"

# Generate Module.cpp
$moduleCpp = @"
#include "Module.h"

MODULE_NAME_DECLARATION(BUILD_REFERENCE)

"@

$moduleCpp | Out-File -FilePath "$outputDir\Module.cpp" -Encoding UTF8
Write-Success "✅ Generated Module.cpp"

# Generate Plugin Header
$configSection = if ($hasConfig) { @"

        class Config : public Core::JSON::Container {
        public:
            Config(const Config&) = delete;
            Config& operator=(const Config&) = delete;

            Config()
                : Core::JSON::Container()
                , StoragePath(_T(""))
                , Enabled(true)
            {
                Add(_T("storagepath"), &StoragePath);
                Add(_T("enabled"), &Enabled);
            }
            ~Config() override = default;

        public:
            Core::JSON::String StoragePath;
            Core::JSON::Boolean Enabled;
        };
"@ } else { "" }

$notificationSection = if ($hasNotifications) { @"

        class Notification : public Core::IDispatch {
        public:
            Notification(const Notification&) = delete;
            Notification& operator=(const Notification&) = delete;

            Notification()
                : _parent(nullptr)
            {
            }
            ~Notification() override = default;

        public:
            void Initialize(${pluginName}* parent)
            {
                ASSERT(parent != nullptr);
                _parent = parent;
            }

            void Deinitialize()
            {
                _parent = nullptr;
            }

            // IDispatch override
            void Dispatch() override
            {
                // Handle notification
            }

        private:
            ${pluginName}* _parent;
        };
"@ } else { "" }

$interfaceEntry = if ($hasCustomInterface) {
    "            INTERFACE_ENTRY(${interfaceName})"
} else {
    ""
}

$pluginH = @"
#pragma once

#include "Module.h"

namespace Thunder {
namespace Plugin {

    class ${pluginName} : public PluginHost::IPlugin$(if ($enableJsonRpc) { ", public PluginHost::JSONRPC" }) {
    private:
        ${pluginName}(const ${pluginName}&) = delete;
        ${pluginName}& operator=(const ${pluginName}&) = delete;
${configSection}${notificationSection}
    public:
        ${pluginName}()
            : _adminLock()
            , _service(nullptr)
            , _connectionId(0)$(if ($hasNotifications) { "`n            , _notification()" })
        {
        }
        ~${pluginName}() override = default;

        // Build QueryInterface implementation
        BEGIN_INTERFACE_MAP(${pluginName})
            INTERFACE_ENTRY(PluginHost::IPlugin)${interfaceEntry}$(if ($enableJsonRpc) { "`n            INTERFACE_ENTRY(PluginHost::IDispatcher)" })
        END_INTERFACE_MAP

    public:
        // IPlugin methods
        const string Initialize(PluginHost::IShell* service) override;
        void Deinitialize(PluginHost::IShell* service) override;
        string Information() const override;

    private:
$(if ($enableJsonRpc) {@"
        // JSON-RPC methods
        void RegisterAll();
        void UnregisterAll();
        uint32_t endpoint_example(const Core::JSON::String& params);
"@})
    private:
        mutable Core::CriticalSection _adminLock;
        PluginHost::IShell* _service;
        uint32_t _connectionId;$(if ($hasNotifications) { "`n        Core::SinkType<Notification> _notification;" })
    };

} // namespace Plugin
} // namespace Thunder

"@

$pluginH | Out-File -FilePath "$outputDir\${pluginName}.h" -Encoding UTF8
Write-Success "✅ Generated ${pluginName}.h"

# Generate Plugin Implementation
$initConfig = if ($hasConfig) { @"

        Config config;
        config.FromString(service->ConfigLine());
        
        // Extract configuration values
        // string storagePath = config.StoragePath.Value();
        // bool enabled = config.Enabled.Value();
"@ } else { "" }

$initJsonRpc = if ($enableJsonRpc) { @"

        // Register JSON-RPC methods
        RegisterAll();
"@ } else { "" }

$deinitJsonRpc = if ($enableJsonRpc) { @"

        // Unregister JSON-RPC methods
        UnregisterAll();
"@ } else { "" }

$oopSection = if ($isOOP) { @"

        // OOP: Terminate RPC connection
        if (_connectionId != 0) {
            RPC::IRemoteConnection* connection = _service->RemoteConnection(_connectionId);
            if (connection != nullptr) {
                connection->Terminate();
                connection->Release();
            }
        }
"@ } else { "" }

$jsonRpcImpl = if ($enableJsonRpc) { @"

void ${pluginName}::RegisterAll()
{
    Register<Core::JSON::String, void>(_T("example"), &${pluginName}::endpoint_example, this);
}

void ${pluginName}::UnregisterAll()
{
    Unregister(_T("example"));
}

uint32_t ${pluginName}::endpoint_example(const Core::JSON::String& params)
{
    // TODO: Implement JSON-RPC method
    return Core::ERROR_NONE;
}
"@ } else { "" }

$pluginCpp = @"
#include "${pluginName}.h"

namespace Thunder {
namespace Plugin {

    namespace {
        static Plugin::Metadata<Plugin::${pluginName}> metadata(
            // Version
            1, 0, 0,
            // Preconditions
            {$(if ($subsystemList.Count -gt 0) { "`n                " + ($subsystemList | ForEach-Object { "PluginHost::ISubSystem::$_" }) -join ",`n                " + "`n            " } else { "" })},
            // Terminations
            {},
            // Controls
            {}
        );
    }

    const string ${pluginName}::Initialize(PluginHost::IShell* service)
    {
        ASSERT(service != nullptr);
        ASSERT(_service == nullptr);

        _service = service;
        _service->AddRef();

        _connectionId = 0;${initConfig}${initJsonRpc}

        // TODO: Initialize plugin logic

        return string();
    }

    void ${pluginName}::Deinitialize(PluginHost::IShell* service)
    {
        if (_service != nullptr) {
            ASSERT(_service == service);${deinitJsonRpc}${oopSection}

            // TODO: Cleanup plugin logic

            _service->Release();
            _service = nullptr;
        }
    }

    string ${pluginName}::Information() const
    {
        return string();
    }
${jsonRpcImpl}
} // namespace Plugin
} // namespace Thunder

"@

$pluginCpp | Out-File -FilePath "$outputDir\${pluginName}.cpp" -Encoding UTF8
Write-Success "✅ Generated ${pluginName}.cpp"

# Generate CMakeLists.txt
$cmakeLists = @"
cmake_minimum_required(VERSION 3.15)

project(Plugin${pluginName})

set(MODULE_NAME Plugin_${pluginName})

find_package(`${NAMESPACE}Plugins REQUIRED)
find_package(`${NAMESPACE}Definitions REQUIRED)
find_package(CompileSettingsDebug CONFIG REQUIRED)

add_library(`${MODULE_NAME} SHARED
    Module.cpp
    ${pluginName}.cpp
)

set_target_properties(`${MODULE_NAME} PROPERTIES
    CXX_STANDARD `${CXX_STD}
    CXX_STANDARD_REQUIRED YES
    FRAMEWORK FALSE
)

target_link_libraries(`${MODULE_NAME}
    PRIVATE
        CompileSettingsDebug::`${NAMESPACE}CompileSettingsDebug
        `${NAMESPACE}Plugins::`${NAMESPACE}Plugins
        `${NAMESPACE}Definitions::`${NAMESPACE}Definitions
)

install(
    TARGETS `${MODULE_NAME}
    DESTINATION lib/`${NAMESPACE}/plugins
)

write_config()

"@

$cmakeLists | Out-File -FilePath "$outputDir\CMakeLists.txt" -Encoding UTF8
Write-Success "✅ Generated CMakeLists.txt"

# Generate Config file
$confIn = @"
startmode = "@PLUGIN_${pluginName.ToUpper()}_STARTMODE@"

"@

$confIn | Out-File -FilePath "$outputDir\${pluginName}.conf.in" -Encoding UTF8
Write-Success "✅ Generated ${pluginName}.conf.in"

# Summary
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Plugin Skeleton Generated Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Info "`nGenerated files in $outputDir/:"
Write-Host "  📄 Module.h" -ForegroundColor White
Write-Host "  📄 Module.cpp" -ForegroundColor White
Write-Host "  📄 ${pluginName}.h" -ForegroundColor White
Write-Host "  📄 ${pluginName}.cpp" -ForegroundColor White
Write-Host "  📄 CMakeLists.txt" -ForegroundColor White
Write-Host "  📄 ${pluginName}.conf.in" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review generated files" -ForegroundColor White
Write-Host "  2. Implement TODO sections in ${pluginName}.cpp" -ForegroundColor White
if ($hasCustomInterface) {
    Write-Host "  3. Define $interfaceName interface in ThunderInterfaces/" -ForegroundColor White
}
if ($enableJsonRpc) {
    Write-Host "  4. Implement JSON-RPC methods in ${pluginName}.cpp" -ForegroundColor White
}
Write-Host "  5. Add plugin to parent CMakeLists.txt" -ForegroundColor White
Write-Host "  6. Run validation: @thunder-checkpoint-review $pluginName" -ForegroundColor White

Write-Host "`n🎯 Validation with Thunder QA:" -ForegroundColor Cyan
Write-Host "  cd $outputDir" -ForegroundColor White
Write-Host "  # Run automated checks:" -ForegroundColor White
Write-Host "  @thunder-checkpoint-review $pluginName" -ForegroundColor White

Write-Success "`n✨ Happy Thunder Plugin Development!"
