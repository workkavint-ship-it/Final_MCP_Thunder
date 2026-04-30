# Thunder Plugin QA AI Tool — Design Plan

## Overview

A three-layer AI-assisted tool that lives in `ThunderTools/PluginQA/` alongside the
PluginSkeletonGenerator (PSG). The core is a Python **MCP server** that VS Code Copilot
Agent mode connects to as a tool provider. Developers interact through **prompt files**
(`.prompt.md`) that appear as slash commands in Copilot Chat, and the CI layer runs
automated reviews on PRs using the **GitHub Models API** — the same pattern already
proven in the PSG workflow.

---

## Layer 1 — MCP Server (Core Engine)

A Python MCP server that Copilot Agent mode can call as a first-class tool. This makes
the PluginSkeletonGenerator *callable by the AI*, not just by humans. VS Code 1.99+
connects to local MCP servers via `mcp.json` — one-time setup per developer.

### Tools Exposed

| Tool | Input | What it does |
|------|-------|-------------|
| `review_plugin` | file path(s) | Parses C++ files, runs rule checks, returns structured findings with file:line citations |
| `generate_skeleton` | YAML config | Invokes PSG via subprocess, returns the generated file tree to the agent |
| `validate_interface` | header path | Checks COM interface rules: `hresult`, `virtual IUnknown`, `EXTERNAL`, ID registration, `/* @out */` annotations |
| `suggest_pattern` | natural-language description | Returns the matching Thunder pattern with context-correct code |
| `explain_rule` | rule ID or keyword | Returns the full explanation from the relevant instruction file |

### Delivery

`ThunderTools/PluginQA/mcp_server.py` + `ThunderTools/PluginQA/mcp.json` (sample VS Code
config). Ships as a sibling to PSG so external RDK partners can use it the same way they
use PSG today.

---

## Layer 2 — Prompt Files (VS Code Agent Mode UX)

`.prompt.md` files that appear as `/thunder-*` commands in Copilot Chat, giving developers
a guided, conversational entry point that orchestrates the MCP tools.

| Command | Interaction flow |
|---------|----------------|
| `/thunder-generate` | Agent asks: plugin name → OOP/IP → interface paths → subsystems → calls `generate_skeleton` → shows output → automatically follows with `review_plugin` on the result |
| `/thunder-review` | Agent calls `review_plugin` on the open/selected file(s) → renders structured findings grouped by severity (violation / warning / suggestion) |
| `/thunder-pattern` | Developer describes a scenario → agent calls `suggest_pattern` → returns canonical Thunder pattern with inline code |
| `/thunder-interface` | Agent calls `validate_interface` on selected header → reports missing `EXTERNAL`, wrong return types, missing ID, etc. |

### Location

`ThunderTools/PluginQA/prompts/`  
- `thunder-review.prompt.md`  
- `thunder-generate.prompt.md`  
- `thunder-pattern.prompt.md`  
- `thunder-interface.prompt.md`

---

## Layer 3 — CI AI Review (PR Gate)

A GitHub Actions workflow (`PluginQA.yml`) that triggers on PRs touching plugin
directories. Uses the GitHub Models API (same `GH_TOKEN` pattern as the PSG workflow).
Posts a structured code-review comment directly on the PR.

### Review Output Format

🔴 [DeviceInfo.cpp:88] _service stored without AddRef() — rule: 05/IShell-lifetime
🔴 [DeviceInfo.cpp:101] _deviceInfo->Release() without null check in Deinitialize()
🟡 [DeviceInfo.h:39] RegisterAll() in constructor — move to Initialize()
🟢 BEGIN_INTERFACE_MAP covers all implemented interfaces ✓


---

## End-to-End Interaction Example

Developer: /thunder-generate

Agent: What is your plugin name?

NetworkMonitor

Agent: Should it run out-of-process (OOP)?

Yes

Agent: Path to your interface header?

/ThunderInterfaces/interfaces/INetworkMonitor.h

Agent: [calls generate_skeleton → PSG runs → files generated in ./NetworkMonitor/]
[calls review_plugin on generated files]

   Skeleton looks good. One suggestion:
   🟡 NetworkMonitor.h:45 — _service member found; confirm AddRef() is called in Initialize()
   ✅ Interface map complete
   ✅ Metadata<T> registration present
   ✅ Deinitialize() has matching Unregister and Release calls


---

## Review Rule Categories

Derived from `.github/instructions/`:

1. **IPlugin contract** — Initialize/Deinitialize symmetry, `AddRef`/`Release` on `IShell*`
2. **COM interface rules** — `hresult` return, `virtual IUnknown`, `EXTERNAL`, immutability
3. **Interface map completeness** — `BEGIN_INTERFACE_MAP` covers all implemented interfaces
4. **Sink pattern** — `SinkType` vs heap, reference vs pointer, `Unavailable()` implemented
5. **JSONRPC symmetry** — every `Register` has a matching `Unregister` in `Deinitialize()`
6. **Config class pattern** — `JSON::Container`, read in `Initialize()` only, defaults in ctor
7. **No exceptions, no STL across boundaries, no `delete` on COM objects**
8. **Module.h first include** in every `.cpp`
9. **Path tokens** — no hardcoded absolute paths (`%datapath%`, `%persistentpath%`, etc.)
10. **Plugin registration** — `Metadata<T>` preferred over `SERVICE_REGISTRATION`
11. **Error handling** — `hresult`, no `throw`, `Deinitialize()` must always complete
12. **OOP-specific** — `EXTERNAL` macro, `connection->Terminate()` in `Deinitialize()`

---

## Relevant Files

| File | Role |
|------|------|
| `ThunderTools/PluginSkeletonGenerator/PluginSkeletonGenerator.py` | PSG entry — invoked by `generate_skeleton` tool |
| `ThunderTools/PluginSkeletonGenerator/Config.yaml` | YAML schema that `generate_skeleton` constructs |
| `ThunderTools/.github/workflows/PluginSkeletonGenerator.yml` | CI pattern to mirror for `PluginQA.yml` |
| `.github/instructions/10-plugin-development.md` | Primary plugin rule source |
| `.github/instructions/04-design-patterns.md` | Patterns reference |
| `.github/instructions/05-object-lifecycle-and-memory.md` | Ref-counting rules |
| `.github/instructions/07-interface-driven-development.md` | Interface rules |
| `.github/instructions/09-error-handling-and-logging.md` | Error handling rules |
| `rdkservices/DeviceInfo/DeviceInfo.cpp` | Real plugin — patterns and anti-patterns |
| `rdkservices/UserSettings/UserSettings.cpp` | Real plugin — OOP pattern reference |

---

## Open Decisions

### 1. Delivery location
**Options:** `ThunderTools/PluginQA/` vs `Thunder/Tools/PluginQA/`  
**Recommendation:** `ThunderTools/` — that is the existing developer-tools distribution channel, and PSG already lives there.

### 2. MCP server dependencies
**Options:**
- A: Plain `python mcp_server.py` (stdlib + PyYAML only, zero new deps)
- B: Official `mcp` Python SDK (`pip install mcp`)

**Recommendation:** `mcp` SDK — better protocol compliance, PyYAML is already a PSG dependency.

### 3. Review engine depth
**Options:**
- A: Regex/AST-lite only — fast, deterministic, offline, no LLM needed
- B: LLM-backed only — deeper semantic understanding, requires network + token
- C: Hybrid — regex/AST-lite first (always, offline), LLM pass on top (optional, when `GH_TOKEN` available)

**Recommendation:** Hybrid (C) — CI uses both; local offline uses regex-only.