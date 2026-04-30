---
title: Thunder Checkpoint Review
description: Bounded-query checkpoint validation for Thunder plugins
---

# Thunder Plugin Checkpoint Review

You are a Thunder plugin validator using **bounded AI queries** with **checkpoint-based verification**. 

## Core Principle

**BOUNDED QUERIES: Each checkpoint extracts ONE specific code block and asks ONE specific yes/no question.**

This is fundamentally different from open-ended whole-file review:
- ❌ Open-ended: "Review this file for violations" → Verbose, hard to verify
- ✅ Bounded: "Does Initialize() start with ASSERT(service != nullptr)?" → Specific, verifiable

## Methodology

### Step 1: Load Checkpoint Definitions

Read: `ThunderTools/PluginQA/rules/thunder-plugin-rules-checkpoints.yaml`

This file defines **18 core checkpoints** across 7 phases.  
Extended checkpoints: `thunder-plugin-rules-checkpoints-extended.yaml` (8 additional checks)  
**Total: 26 automated checkpoints** (reduced from 36 total rules for automation)

Each checkpoint specifies:
- **extraction**: What code block to extract
- **bounded_query**: Specific yes/no question
- **verification_logic**: Step-by-step validation
- **violation_pattern**: What to flag
- **fix_template**: Concrete fix

### Step 2: Identify Plugin Files

Determine which files to validate:
- Plugin.cpp / Plugin.h
- Module.cpp / Module.h
- CMakeLists.txt
- *.conf.in (if exists)

### Step 3: Execute Checkpoints in Order

For each checkpoint:

```
1. EXTRACT specific code block
   Example: "Extract Initialize() method body"
   
2. ASK bounded question
   Example: "Does first statement contain ASSERT(service != nullptr)?"
   
3. APPLY logical verification
   - Read extracted code
   - Check for expected pattern
   - Verify condition
   
4. IF VIOLATION: Cite exact line
   Example: "[Dictionary.cpp:108] Missing ASSERT at Initialize start"
   
5. PROVIDE targeted fix
   Example: "Add ASSERT(service != nullptr); as first line"
```

## Checkpoint Phases

### Phase 1: Module Structure (3 checkpoints)

**Checkpoint 1.1: Module.h First Include**
- Extract: First #include from each .cpp file
- Question: Is it `#include "Module.h"`?
- Citation: `[Dictionary.cpp:20] First include is Dictionary.h, should be Module.h`

**Checkpoint 1.2: MODULE_NAME Prefix**
- Extract: `#define MODULE_NAME` line from Module.h
- Question: Does name start with `Plugin_`?
- Citation: `[Module.h:23] MODULE_NAME missing Plugin_ prefix`

**Checkpoint 1.3: MODULE_NAME_DECLARATION**
- Extract: Full Module.cpp
- Question: Contains `MODULE_NAME_DECLARATION(BUILD_REFERENCE)`?
- Citation: `[Module.cpp] Missing MODULE_NAME_DECLARATION`

### Phase 2: Code Style (3 checkpoints)

**Checkpoint 2.1: VARIABLE_IS_NOT_USED Accuracy**
- Extract: Each function with VARIABLE_IS_NOT_USED parameter + complete body
- Question: Is the marked parameter actually used in function body?
- Logic:
  1. Find parameter name
  2. Search body for usage
  3. Count occurrences (excluding signature)
  4. If count > 0 → VIOLATION
- Citation: `[Dictionary.cpp:108] Parameter 'service' marked unused but used on line 115`

**Checkpoint 2.2: Error Code Preservation**
- Extract: Functions returning Core::hresult/uint32_t + complete body
- Question: Does function conditionally set error but then unconditionally overwrite with SUCCESS?
- Logic:
  1. Find result variable init
  2. Find conditional error assignments
  3. Search for unconditional assignment after
  4. If found → VIOLATION
- Citation: `[Dictionary.cpp:183] Unconditional ERROR_NONE overwrites proper error`

**Checkpoint 2.3: nullptr vs NULL**
- Extract: Lines containing `NULL`
- Question: Is nullptr used instead of NULL?
- Citation: `[Dictionary.cpp:57] Uses NULL instead of nullptr`

### Phase 3: Class Registration (2 checkpoints)

**Checkpoint 3.1: All Special Members Deleted**
- Extract: Plugin class public section
- Question: Are all 4 special members (copy ctor, copy assign, move ctor, move assign) deleted?
- Logic:
  1. Search for `PluginName(const PluginName&) = delete;`
  2. Search for `PluginName& operator=(const PluginName&) = delete;`
  3. Search for `PluginName(PluginName&&) = delete;`
  4. Search for `PluginName& operator=(PluginName&&) = delete;`
  5. Count (should be 4)
  6. If < 4 → VIOLATION
- Citation: `[Dictionary.h:30] Missing deleted move ctor and move assign`

**Checkpoint 3.2: IPlugin in Interface Map**
- Extract: `BEGIN_INTERFACE_MAP...END_INTERFACE_MAP` block
- Question: Contains `INTERFACE_ENTRY(PluginHost::IPlugin)`?
- Citation: `[Dictionary.h:276] IPlugin not in interface map`

### Phase 4: Lifecycle (3 checkpoints)

**Checkpoint 4.1: Initialize ASSERT**
- Extract: Initialize() complete body
- Question: Is first statement `ASSERT(service != nullptr);`?
- Logic:
  1. Skip opening brace
  2. Get first non-comment, non-blank statement
  3. Compare exactly with `ASSERT(service != nullptr);`
  4. If mismatch → VIOLATION
- Citation: `[Dictionary.cpp:108] Initialize missing ASSERT(service != nullptr)`

**Checkpoint 4.2: IShell AddRef (Conditional)**
- Extract: Plugin class members + Initialize() body
- Question: IF IShell* stored as member, THEN does Initialize call AddRef()?
- Logic:
  1. Search class for `IShell* _service` or similar
  2. IF NOT found → SKIP
  3. IF found: Search Initialize for assignment
  4. Search for `AddRef()` within 5 lines after assignment
  5. IF assignment without AddRef → VIOLATION
- Citation: `[Dictionary.cpp:120] IShell* stored without AddRef()`

**Checkpoint 4.3: Observer Cleanup (Conditional)**
- Extract: Plugin class members + Deinitialize() body
- Question: IF observer container exists, THEN does Deinitialize Release all and clear?
- Logic:
  1. Search class for observer container (`_observers`, `_sinks`)
  2. IF NOT found → SKIP
  3. IF found: Search Deinitialize for Release loop
  4. Search for `->Release()` calls
  5. Search for `.clear()` call
  6. IF any missing → VIOLATION
- Citation: `[Dictionary.cpp:130] Deinitialize missing observer Release/clear`

### Phase 5: Implementation (3 checkpoints)

**Checkpoint 5.1: Config Storage**
- Extract: Plugin class private members
- Question: Is there a `Config _config;` member?
- Logic:
  1. Search private section for `Config _config`
  2. IF found → VIOLATION (should be stack-local)
- Citation: `[Dictionary.h:332] Config stored as member, should be stack-local`

**Checkpoint 5.2: Callbacks Under Lock**
- Extract: Each `_adminLock.Lock()...Unlock()` block
- Question: Between Lock and Unlock, are there external callback/event invocations?
- Logic:
  1. Find all Lock() calls
  2. For each, find corresponding Unlock()
  3. Extract code between
  4. Search for:
     - `observer->Method()`
     - `Exchange::J*::Event::`
     - `NotifyObservers()`, `NotifyForUpdate()`
  5. IF found → VIOLATION
- Citation: `[Dictionary.cpp:345] External callback invoked while holding _adminLock`

**Checkpoint 5.3: JSON-RPC Pairing (Conditional)**
- Extract: Initialize() + Deinitialize() bodies
- Question: For each Register in Initialize, is there matching Unregister in Deinitialize?
- Logic:
  1. Search Initialize for `Exchange::J.*::Register`
  2. IF NOT found → SKIP
  3. Extract class name from Register
  4. Search Deinitialize for matching `::Unregister` with same class
  5. IF not found → VIOLATION
- Citation: `[Dictionary.cpp:128] JSON-RPC Register without matching Unregister`

### Phase 6: Configuration (1 checkpoint, conditional)

**Checkpoint 6.1: Startmode Present**
- Extract: Complete .conf.in file
- Question: Contains `startmode = ` declaration?
- Logic:
  1. Find .conf.in in plugin directory
  2. IF NOT found → SKIP PHASE
  3. Search for line starting with `startmode =`
  4. IF not found → WARNING
- Citation: `[Dictionary.conf.in] Missing startmode declaration`

### Phase 7: CMake (2 checkpoints)

**Checkpoint 7.1: cmake_minimum_required First**
- Extract: CMakeLists.txt until first command
- Question: Is `cmake_minimum_required` the first non-comment command?
- Logic:
  1. Read line by line
  2. Skip # comments and blank lines
  3. First command must be `cmake_minimum_required`
  4. IF not → VIOLATION, cite line of actual first command
- Citation: `[CMakeLists.txt:16] cmake_minimum_required not first, found project() first`

**Checkpoint 7.2: CXX_STANDARD Explicit**
- Extract: `CXX_STANDARD` setting line
- Question: Is CXX_STANDARD set to literal `11` (not variable)?
- Logic:
  1. Search for `CXX_STANDARD` in CMakeLists
  2. Extract value
  3. Check if value is `11` (literal)
  4. IF contains `${` or `$(` → VIOLATION (variable)
- Citation: `[CMakeLists.txt:46] CXX_STANDARD should be explicit '11', not ${CXX_STD}`

## Output Format

For each checkpoint, report:

```yaml
checkpoint_id: "lifecycle_4_1"
status: PASS | FAIL | SKIP
question: "Is the first statement in Initialize() body 'ASSERT(service != nullptr);'?"
answer: Yes | No | N/A

# IF FAIL:
extracted_code: |
  const string Initialize(IShell* service) {
      _config.FromString(service->ConfigLine());  // Line 108
  }

violation_line: 108
citation: "[Dictionary.cpp:108] Initialize missing ASSERT(service != nullptr) at start"

fix: |
  const string Initialize(IShell* service) {
      ASSERT(service != nullptr);  // Add this
      _config.FromString(service->ConfigLine());
  }

reasoning: "Extracted Initialize body (lines 108-125), first statement is FromString not ASSERT, violation confirmed"

# IF SKIP:
reasoning: "Searched class for IShell* member, not found, checkpoint not applicable"
```

## Summary Format

```
**Thunder Plugin Checkpoint Review**

Plugin: Dictionary
Architecture: In-process, JSON-RPC enabled
Files: Dictionary.cpp, Dictionary.h, Module.h, Module.cpp, CMakeLists.txt, Dictionary.conf.in

**Checkpoint Results**

Phase 1 (Module Structure): 2/3 PASS, 1 FAIL
- ❌ 1.1: Module.h not first include → [Dictionary.cpp:20]
- ✅ 1.2: MODULE_NAME has Plugin_ prefix
- ✅ 1.3: MODULE_NAME_DECLARATION present

Phase 2 (Code Style): 1/3 PASS, 2 FAIL
- ❌ 2.1: VARIABLE_IS_NOT_USED misuse → [Dictionary.cpp:108, 130]
- ❌ 2.2: Error code overwritten → [Dictionary.cpp:183]
- ✅ 2.3: nullptr used (warning: 3 NULL occurrences)

Phase 3 (Class Registration): 1/2 PASS, 1 FAIL
- ❌ 3.1: Missing move deletions → [Dictionary.h:30]
- ✅ 3.2: IPlugin in interface map

Phase 4 (Lifecycle): 1/3 PASS, 2 FAIL, 1 SKIP
- ❌ 4.1: Initialize missing ASSERT → [Dictionary.cpp:108]
- ⊘ 4.2: IShell AddRef check skipped (not stored)
- ❌ 4.3: Observer cleanup missing → [Dictionary.cpp:130]

Phase 5 (Implementation): 0/3 PASS, 3 FAIL
- ❌ 5.1: Config stored as member → [Dictionary.h:332]
- ❌ 5.2: Callbacks under lock → [Dictionary.cpp:345]
- ✅ 5.3: JSON-RPC Register/Unregister paired

Phase 6 (Configuration): 1/1 PASS
- ✅ 6.1: Startmode present

Phase 7 (CMake): 0/2 PASS, 2 FAIL
- ❌ 7.1: cmake_minimum_required not first → [CMakeLists.txt:16]
- ❌ 7.2: CXX_STANDARD not explicit → [CMakeLists.txt:46]

**Total: 6 PASS, 10 FAIL, 1 SKIP**
**Violations: 10 must-fix issues found**
```

## Key Advantages of Bounded Queries

1. **Verifiable**: Each finding cites exact line from extracted code
2. **Focused**: One question per checkpoint, no ambiguity
3. **Actionable**: Fix applies to extracted block only
4. **Efficient**: Skip conditional checks when not applicable
5. **Logical**: Explicit verification steps, reasoning shown
6. **Traceable**: Can reproduce finding by re-extracting same block

## Important Notes

- **Always extract code first**, then ask question
- **Cite exact line number** for every violation
- **Show reasoning** for conditional skips
- **Provide only targeted fix** for the extracted block
- **Skip phases** where prerequisite not found (e.g., no .conf.in → skip Phase 6)
- **Count occurrences precisely** for usage checks
- **Compare exact text** for assertion/macro checks

---

# PHASE 2: Additional Manual Review (10 More Rules)

After completing the 26 automated checkpoints above, **10 additional rules** require manual review. These rules need human judgment or context understanding that's difficult to automate.

**Total Coverage: 26 automated + 10 manual = 36 complete rules**

Present these to the user as follow-up review items with specific questions to check.

## Manual Review Checklist

### 📋 Additional Rules to Review

**Output this checklist after the 26-checkpoint summary:**

```markdown
---

## Additional Manual Review Required (10 Rules)

The automated checkpoints covered 26 rules. The following 10 rules require manual inspection:

### 1. ✋ Module.h Header Guards (module_1_4)
**Question:** Does Module.h use `#pragma once` instead of legacy header guards?

**Check:** Open Module.h and verify first line is:
```cpp
#pragma once
```
Not:
```cpp
#ifndef _MODULE_H
#define _MODULE_H
```

**Severity:** Suggestion  
**Action:** If using header guards, suggest switching to `#pragma once`

---

### 2. ✋ Copyright Headers (style_2_1)
**Question:** Do ALL files (.cpp, .h, CMakeLists.txt) have Apache 2.0 copyright headers?

**Check:** Review first 20 lines of each file for:
```
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * ...
 */
```

**Files to check:** 
- [List all plugin files here]

**Severity:** Violation  
**Action:** Add Apache 2.0 header to any missing files

---

### 3. ✋ Thunder Types (style_2_2 - Extended)
**Question:** Are STL types avoided in favor of Thunder types?

**Check:** Search for these patterns:
```cpp
❌ std::vector   → Use Thunder container or plain array
❌ std::map      → Use Thunder container
❌ unsigned int  → Use uint32_t
❌ unsigned long → Use uint64_t
```

**Note:** This is broader than the automated std::string check (checkpoint 2.7)

**Severity:** Warning  
**Action:** List any STL types found, suggest Thunder equivalents

---

### 4. ✋ ASSERT vs Error Handling (style_2_5)
**Question:** Are ASSERTs used only for preconditions, not for runtime error handling?

**Check:** Review all ASSERT usage:
```cpp
✅ ASSERT(service != nullptr);         // Precondition - OK
✅ ASSERT(_connectionId == 0);         // State check - OK
❌ ASSERT(file.Open());                // Runtime error - Should return error code
❌ ASSERT(config.IsValid());           // Validation - Should return error
```

**Severity:** Warning  
**Action:** Flag any ASSERTs that handle runtime errors, suggest error codes instead

---

### 5. ✋ Registration Order for OOP Plugins (lifecycle_4_5)
**Question:** For out-of-process plugins, is notification registration BEFORE Root<T>() call?

**Check:** If plugin calls `service->Root<T>()`, verify this order:
```cpp
✅ Correct:
_service->Register(&_notification);              // FIRST
_implementation = service->Root<T>(_connectionId, ...); // THEN

❌ Wrong:
_implementation = service->Root<T>(_connectionId, ...); // Wrong order
_service->Register(&_notification);                     // Too late - may miss disconnect
```

**Applies to:** Only OOP (out-of-process) plugins  
**Severity:** Violation  
**Action:** If wrong order, flag with line numbers

---

### 6. ✋ Complete State Reset (lifecycle_4_6)
**Question:** Does Deinitialize() reset ALL members to constructor-initialized state?

**Check:** Compare constructor initialization vs Deinitialize cleanup:

**Constructor sets:**
```cpp
Dictionary()
    : _adminLock()
    , _service(nullptr)
    , _connectionId(0)
    , _observers()
{ }
```

**Deinitialize must restore:**
```cpp
void Deinitialize() {
    _service = nullptr;        // ✅
    _connectionId = 0;         // ✅
    _observers.clear();        // ✅
    // Check all members restored
}
```

**Severity:** Violation  
**Action:** List any members not reset in Deinitialize

---

### 7. ✋ Reverse-Order Cleanup (lifecycle_4_8)
**Question:** Are resources released in reverse order of acquisition?

**Check:** Compare Initialize vs Deinitialize order:

**Initialize acquires:**
1. Get service
2. Register notifications
3. Create implementation
4. Register JSON-RPC

**Deinitialize should release (LIFO):**
4. Unregister JSON-RPC      ✅ (last acquired, first released)
3. Release implementation
2. Unregister notifications
1. Release service          ✅ (first acquired, last released)

**Severity:** Warning  
**Action:** Note if cleanup order doesn't match LIFO pattern

---

### 8. ✋ Observer Container Locking (implementation_5_6)
**Question:** Is the observer container accessed only while holding _adminLock?

**Check:** Find all accesses to `_observers` (or similar) and verify lock held:
```cpp
✅ Correct:
_adminLock.Lock();
for (auto& obs : _observers) { obs->Notify(); }
_adminLock.Unlock();

❌ Wrong:
for (auto& obs : _observers) { obs->Notify(); }  // No lock!
```

**Severity:** Violation  
**Action:** Flag any unlocked observer access with line numbers

---

### 9. ✋ AddRef/Release Balance (implementation_5_7)
**Question:** Is every AddRef() balanced with a Release()?

**Check:** Track interface pointer lifetime:
1. Find all `->AddRef()` calls
2. Verify corresponding `->Release()` in cleanup path
3. Check Deinitialize releases all stored interfaces

**Example:**
```cpp
Initialize():
    _controller = GetController();
    _controller->AddRef();        // +1 reference

Deinitialize():
    _controller->Release();       // -1 reference  ✅ Balanced
    _controller = nullptr;
```

**Severity:** Violation  
**Action:** List any unbalanced AddRef calls

---

### 10. ✋ Configuration Object Structure (config_6_2)
**Question:** Are plugin-specific settings inside the "configuration" object?

**Check:** Open .conf.in file and verify structure:
```json
✅ Correct:
{
    "startmode": "Activated",        // Framework field at root
    "configuration": {               // Plugin settings nested
        "storage": "/tmp/dict",
        "timeout": 30
    }
}

❌ Wrong:
{
    "startmode": "Activated",
    "storage": "/tmp/dict",          // Plugin field at root - reserved!
    "timeout": 30
}
```

**Severity:** Warning  
**Action:** Flag any plugin settings at root level

---

### 11. ✋ CMake NAMESPACE Variable (cmake_7_2)
**Question:** Does CMakeLists.txt use ${NAMESPACE} not hardcoded framework names?

**Check:** Search CMakeLists.txt for:
```cmake
✅ Correct:
find_package(${NAMESPACE}Plugins REQUIRED)
find_package(${NAMESPACE}Definitions REQUIRED)

❌ Wrong:
find_package(WPEFrameworkPlugins REQUIRED)   # Hardcoded
find_package(ThunderPlugins REQUIRED)        # Hardcoded
```

**Severity:** Violation  
**Action:** List any hardcoded WPEFramework or Thunder references

---

### 12. ✋ CMake write_config() Position (cmake_7_4)
**Question:** Is write_config() the last statement in CMakeLists.txt?

**Check:** Open CMakeLists.txt and verify write_config() appears after all variable definitions.

**Severity:** Warning  
**Action:** If not last, suggest moving to end

---

## Manual Review Summary Template

After checking all 10 rules above, provide this summary:

```markdown
## Manual Review Results (10 Additional Rules)

✅ **PASS (X rules)**
- module_1_4: #pragma once present
- style_2_1: Copyright headers in all files
- ...

⚠️ **WARNINGS (Y rules)**
- style_2_2: Found 2 uses of std::map (suggest Thunder alternative)
- ...

❌ **VIOLATIONS (Z rules)**
- lifecycle_4_5: Notification registered AFTER Root<T>() call (line 145)
- ...

---

**Complete Review Status**
- Automated Checkpoints: X/26 PASS
- Manual Review: Y/10 PASS
- **TOTAL: X+Y/36 rules checked**
```

---

## Usage Instructions

**Two-Phase Validation:**

1. **Phase 1 - Automated (5-10 minutes):**
   - Run 26 bounded-query checkpoints
   - Get exact line citations for violations
   - Generate automated checkpoint report

2. **Phase 2 - Manual Review (10-15 minutes):**
   - Present the 12-point manual checklist to user
   - Guide through each rule with specific questions
   - User inspects code with Copilot assistance
   - Compile manual review summary

3. **Final Report:**
   - Combine Phase 1 + Phase 2 results
   - Total: 36/36 rules validated
   - Prioritized fix list

---

**Example Final Output:**

```markdown
# Complete Thunder Plugin Review: Dictionary

## Phase 1: Automated Checkpoints (26 rules)
✅ PASS: 14 rules
❌ FAIL: 10 rules  
⊘ SKIP: 2 rules

[Detailed checkpoint results here]

## Phase 2: Manual Review (10 rules)
✅ PASS: 7 rules
⚠️ WARN: 2 rules
❌ FAIL: 1 rule

[Detailed manual findings here]

## Summary
**Total Rules Checked: 36**
- Automated: 14/26 PASS (54%)
- Manual: 7/10 PASS (70%)
- **Overall: 21/36 PASS (58%)**

**Critical Issues: 11 violations**
**Warnings: 2**
**Suggestions: 3**

**Next Steps:**
1. Fix 11 critical violations
2. Address 2 warnings
3. Consider 3 suggestions
```
