# Missing Rules Analysis
## 36 Comprehensive Rules vs 26 Automated Checkpoints

---

## Summary

**Total Rules:** 36 (in thunder-plugin-rules.yaml)  
**Automated Checkpoints:** 26 (in checkpoint files)  
**Missing/Not Automated:** 10 rules

---

## The 10 Rules NOT Covered by Automated Checkpoints

### 1. **module_1_4: #pragma once in Module.h**
- **Severity:** Suggestion
- **Why not automated:** Simple visual check, low priority
- **Manual check:** Open Module.h, look at line 1-3
- **Expected:** `#pragma once` instead of `#ifndef/#define` guards

---

### 2. **style_2_1: Copyright Headers Present**
- **Severity:** Violation
- **Why not automated:** Needs to verify specific Apache 2.0 text format
- **Manual check:** Check first 20 lines of all .cpp, .h, CMakeLists.txt
- **Expected:** Apache 2.0 license header with copyright year

---

### 3. **style_2_2: Thunder Types Used (Broader Check)**
- **Severity:** Warning
- **Why not automated:** style_2_7 checks `std::string`, but this checks ALL STL types
- **Manual check:** `grep "unsigned int|unsigned long|std::vector|std::map" *.cpp *.h`
- **Expected:** Use Thunder types: `uint32_t`, `uint64_t`, `string`, Thunder containers

---

### 4. **style_2_5: ASSERT Used Correctly**
- **Severity:** Warning
- **Why not automated:** Requires understanding preconditions vs error handling logic
- **Manual check:** Review ASSERT usage - should be preconditions only, not error handling
- **Expected:** ASSERT for debug checks, return error codes for runtime errors

---

### 5. **lifecycle_4_5: Register Before OOP Instantiation**
- **Severity:** Violation
- **Why not automated:** Only applies to OOP plugins, requires understanding call order
- **Manual check:** If plugin calls `service->Root<T>()`, verify notification registration comes BEFORE
- **Expected:**
```cpp
_service->Register(&_notification);  // FIRST
_implementation = service->Root<T>(_connectionId, ...);  // THEN instantiate
```

---

### 6. **lifecycle_4_6: State Cleared in Deinitialize**
- **Severity:** Violation  
- **Why not automated:** Requires knowing which members should be reset, context-dependent
- **Manual check:** Review Deinitialize - all members should return to constructor state
- **Expected:** `_connectionId = 0`, `_service = nullptr`, `_observers.clear()`, etc.

---

### 7. **lifecycle_4_8: Reverse-Order Cleanup**
- **Severity:** Warning
- **Why not automated:** Requires understanding dependency graph of resources
- **Manual check:** Compare Initialize order vs Deinitialize order
- **Expected:** Last acquired resource released first (LIFO)

---

### 8. **implementation_5_1: JSON-RPC Registration in Initialize**
- **Severity:** Violation
- **Why not automated:** Already covered by implementation_5_2 (pairing check)
- **Note:** The checkpoint implementation_5_2 verifies Register/Unregister pairing, which implies they're in Initialize/Deinitialize
- **Manual check:** Verify JSON-RPC Register is in Initialize, not constructor

---

### 9. **implementation_5_6: Observers Accessed Under Lock**
- **Severity:** Violation
- **Why not automated:** Requires analyzing all observer container access points
- **Manual check:** Find all `_observers` container access, verify `_adminLock` held
- **Expected:**
```cpp
_adminLock.Lock();
for (auto& obs : _observers) { /* work */ }
_adminLock.Unlock();
```

---

### 10. **implementation_5_7: AddRef/Release Paired**
- **Severity:** Violation
- **Why not automated:** Requires flow analysis across entire lifecycle
- **Manual check:** For each `interface->AddRef()`, verify matching `Release()` in cleanup
- **Expected:** Every stored interface pointer has Release() in Deinitialize

---

### 11. **config_6_2: Configuration Object Structure**
- **Severity:** Warning
- **Why not automated:** Requires validating JSON structure against framework schema
- **Manual check:** Open .conf.in, verify plugin settings inside `configuration` object
- **Expected:**
```json
{
    "startmode": "Activated",
    "configuration": {
        "storage": "/tmp/plugin",  // Plugin-specific settings HERE
        "timeout": 30
    }
}
```

---

### 12. **cmake_7_2: ${NAMESPACE} Usage**
- **Severity:** Violation
- **Why not automated:** Requires understanding CMake variable substitution
- **Manual check:** `grep "WPEFramework|Thunder[^{]" CMakeLists.txt`
- **Expected:** Use `${NAMESPACE}Plugins` not hardcoded `WPEFrameworkPlugins` or `ThunderPlugins`

---

### 13. **cmake_7_4: write_config() Last**
- **Severity:** Warning
- **Why not automated:** Requires understanding CMake script flow
- **Manual check:** Open CMakeLists.txt, check if `write_config()` is last statement
- **Expected:** `write_config()` after all variable definitions

---

## Quick Detection Commands

```powershell
# 1. pragma once
Get-Content Module.h -TotalCount 3 | Select-String "pragma once"

# 2. Copyright
Get-Content *.cpp,*.h -TotalCount 20 | Select-String "Apache License"

# 3. Thunder types
grep -n "unsigned int|unsigned long|std::vector|std::map" *.cpp *.h

# 4. ASSERT usage (manual review required)
grep -n "ASSERT" *.cpp | more

# 5. Register before Root (OOP only)
grep -B 5 "Root<" *.cpp | grep "Register"

# 6. State cleared (manual review required)
# Review Deinitialize method

# 7. Reverse-order cleanup (manual review required)
# Compare Initialize vs Deinitialize

# 8. JSON-RPC in Initialize (covered by checkpoint 5.2)
grep -n "JPlugin.*::Register" *.cpp

# 9. Observers under lock
grep -B 2 -A 2 "_observers" *.cpp | grep -C 5 "_adminLock"

# 10. AddRef/Release paired (manual review required)
grep -n "AddRef\|Release" *.cpp

# 11. Config structure
cat *.conf.in | grep -A 5 "configuration"

# 12. NAMESPACE usage
grep "WPEFramework[^{]|Thunder[^{]" CMakeLists.txt

# 13. write_config last
tail -5 CMakeLists.txt | grep "write_config"
```

---

## Why These 10 Aren't Automated

| Category | Count | Reason |
|----------|-------|--------|
| **Requires Context Understanding** | 5 | Need to understand dependencies, flow, purpose |
| **Low Priority** | 2 | Suggestions/warnings, not violations |
| **Already Covered Implicitly** | 1 | Covered by other checkpoint |
| **Complex Pattern Matching** | 2 | Need multi-file flow analysis |

---

## Recommendation

For complete 36-rule compliance:
1. ✅ Run automated 26-checkpoint validation (~5 min)
2. 📋 Run quick detection commands for remaining 10 (~5 min)
3. 👁️ Manual review for context-dependent rules (~10 min)

**Total time: ~20 minutes per plugin for full 36-rule audit**

---

## Automation Potential

**Could be automated later (with more effort):**
- cmake_7_2: ${NAMESPACE} usage (regex patterns)
- cmake_7_4: write_config() position (line number check)
- style_2_1: Copyright header (template matching)
- implementation_5_6: Lock usage (flow analysis)

**Difficult to automate (require semantic understanding):**
- lifecycle_4_5: Registration order
- lifecycle_4_6: State clearing completeness  
- lifecycle_4_8: Reverse-order cleanup
- implementation_5_7: AddRef/Release pairing across files
- style_2_5: ASSERT vs error handling logic

---

**Current system focuses on the 26 most important and automatable rules with exact line citations.**
