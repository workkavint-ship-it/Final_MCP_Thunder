# Checkpoint ID Mapping Guide
## Understanding IDs Across thunder-plugin-rules.yaml vs thunder-plugin-rules-checkpoints.yaml

**Last Updated:** May 5, 2026  
**Purpose:** Clarify ID assignments to prevent confusion between comprehensive rules and automated checkpoints

---

## The Two Files Explained

### **1. thunder-plugin-rules.yaml** (36 Comprehensive Rules)
- **Purpose:** Complete reference of ALL Thunder plugin rules
- **Audience:** Documentation, manual review, education
- **Coverage:** Includes rules that are difficult or impossible to automate
- **IDs:** Sequential within each phase (e.g., lifecycle_4_1 through lifecycle_4_8)

### **2. thunder-plugin-rules-checkpoints.yaml** (29 Automated Checkpoints)
- **Purpose:** Automated bounded-query validation
- **Audience:** AI validation system, CI/CD integration
- **Coverage:** Only rules that can be reliably automated
- **IDs:** Non-sequential within phases (skips IDs reserved for manual checks)

---

## ID Collision History (RESOLVED May 5, 2026)

### **Problem Identified:**
Three checkpoint IDs conflicted with rules.yaml, causing confusion:

| ID | In rules.yaml | In checkpoints.yaml (BEFORE fix) |
|---|---|---|
| lifecycle_4_5 | Register sinks before Root<T>() | Constructor only initializes members ❌ |
| lifecycle_4_6 | State cleared in Deinitialize | Destructor is default or empty ❌ |
| lifecycle_4_8 | Reverse-order cleanup | Initialize returns string() ❌ |

### **Solution Applied:**
Renamed automated checkpoints to avoid conflicts:

| Old ID (Conflict) | New ID (Fixed) | Check Description |
|---|---|---|
| lifecycle_4_5 | **lifecycle_4_9** | Constructor only initializes members ✅ |
| lifecycle_4_6 | **lifecycle_4_10** | Destructor is default or empty ✅ |
| lifecycle_4_8 | **lifecycle_4_11** | Initialize returns empty string on success ✅ |

---

## Complete ID Mapping

### **Phase 4: Lifecycle Management**

| ID | Type | Description | File |
|---|---|---|---|
| lifecycle_4_1 | ✅ Automated | Initialize starts with ASSERT | checkpoints.yaml |
| lifecycle_4_2 | ✅ Automated | IShell stored with AddRef | checkpoints.yaml |
| lifecycle_4_3 | ✅ Automated | Deinitialize verifies service parameter | checkpoints.yaml |
| lifecycle_4_4 | ✅ Automated | Information() method implemented | checkpoints.yaml |
| **lifecycle_4_5** | ⚠️ **Manual** | **Register before OOP instantiation** | **rules.yaml** |
| **lifecycle_4_6** | ⚠️ **Manual** | **State cleared in Deinitialize** | **rules.yaml** |
| lifecycle_4_7 | ✅ Automated | Deinitialize releases observers | checkpoints.yaml |
| **lifecycle_4_8** | ⚠️ **Manual** | **Reverse-order cleanup** | **rules.yaml** |
| lifecycle_4_9 | ✅ Automated | Constructor only initializes members | checkpoints.yaml |
| lifecycle_4_10 | ✅ Automated | Destructor is default or empty | checkpoints.yaml |
| lifecycle_4_11 | ✅ Automated | Initialize returns empty string | checkpoints.yaml |

### **Other Phases (No Conflicts)**

All other phases have consistent IDs between both files:

- **Phase 1 (Module Structure):** module_1_1, 1_2, 1_3 - all automated
- **Phase 2 (Code Style):** style_2_3, 2_4, 2_6, 2_7, 2_8, 2_9 - all automated
- **Phase 3 (Registration):** registration_3_2, 3_3, 3_4 - all automated
- **Phase 5 (Implementation):** implementation_5_2, 5_3, 5_4, 5_9, 5_11 - all automated
- **Phase 6 (Configuration):** config_6_1 - automated
- **Phase 7 (CMake):** cmake_7_1, 7_3 - automated
- **Phase 8 (COM Interfaces):** com_8_1 - automated
- **Phase 9 (OOP-Specific):** oop_9_1 - automated

---

## Why Some IDs Are Manual-Only

Certain lifecycle rules cannot be reliably automated:

### **lifecycle_4_5: Register before OOP instantiation**
- **Why manual:** Requires understanding of plugin architecture (OOP vs in-process)
- **Detection:** Must trace execution order across multiple method calls
- **Complexity:** High - needs semantic understanding of Root<T>() purpose

### **lifecycle_4_6: State cleared in Deinitialize**
- **Why manual:** Requires comparing constructor init list with Deinitialize body
- **Detection:** Must verify ALL members are reset (not just some)
- **Complexity:** High - needs complete member inventory and comparison

### **lifecycle_4_8: Reverse-order cleanup**
- **Why manual:** Requires dependency graph analysis
- **Detection:** Must understand resource acquisition order in Initialize
- **Complexity:** Very high - needs LIFO stack tracking across methods

---

## Usage Guidelines

### **When Using rules.yaml:**
✅ Reference for comprehensive rule documentation  
✅ Educational material for plugin developers  
✅ Manual review checklists  
✅ Source of truth for all 36 rules

### **When Using checkpoints.yaml:**
✅ Automated validation in CI/CD  
✅ Bounded AI query validation  
✅ Quick automated quality checks  
✅ 29 automated rules only

### **In @thunder-checkpoint-review Command:**
1. **Phase 1:** Automated checkpoints run (29 checks from checkpoints.yaml)
2. **Phase 2:** Manual review presented (7 rules from rules.yaml, including lifecycle_4_5, 4_6, 4_8)

---

## Verification Commands

### **Check for ID Conflicts:**
```powershell
# Find all checkpoint IDs
Select-String -Path "thunder-plugin-rules-checkpoints.yaml" -Pattern "checkpoint_id:" | ForEach-Object { $_.Line }

# Find all rule IDs
Select-String -Path "thunder-plugin-rules.yaml" -Pattern '^\s+- id:' | ForEach-Object { $_.Line }
```

### **Verify No Collisions:**
```powershell
# Extract IDs from both files and compare
$checkpointIds = Select-String -Path "thunder-plugin-rules-checkpoints.yaml" -Pattern 'checkpoint_id: "([^"]+)"' | 
    ForEach-Object { $_.Matches.Groups[1].Value }
    
$ruleIds = Select-String -Path "thunder-plugin-rules.yaml" -Pattern 'id: "([^"]+)"' | 
    ForEach-Object { $_.Matches.Groups[1].Value } | 
    Where-Object { $_ -match '^(module|style|registration|lifecycle|implementation|config|cmake|com|oop)_' }

# Find any duplicates
Compare-Object $checkpointIds $ruleIds -IncludeEqual -ExcludeDifferent
# Should return EMPTY (no conflicts)
```

---

## Impact of ID Changes

### **Files Updated (May 5, 2026):**
✅ thunder-plugin-rules-checkpoints.yaml - Renamed 3 checkpoint IDs  
✅ CHECKPOINT_ID_MAPPING.md - Created (this file)

### **Files NOT Changed (Still Correct):**
✅ thunder-plugin-rules.yaml - IDs remain unchanged  
✅ thunder-checkpoint-review.prompt.md - Manual checks still reference lifecycle_4_5, 4_6, 4_8  
✅ 12_CRITICAL_RULES_COVERAGE.md - Manual check references correct

---

## Summary

| File | Total IDs | Automated | Manual | Notes |
|---|---|---|---|---|
| **rules.yaml** | 36 | 29 | 7 | Complete reference |
| **checkpoints.yaml** | 29 | 29 | 0 | Automated only |
| **Conflicts** | 0 | - | - | ✅ Resolved May 5, 2026 |

**Key Principle:** Manual-only rule IDs (lifecycle_4_5, 4_6, 4_8) are RESERVED and should NOT be reused in automated checkpoints.

---

## Future Guidelines

When adding new rules:

1. ✅ **Add to rules.yaml first** with sequential ID
2. ✅ **Determine if automatable** (can bounded query validate it?)
3. ✅ **If automatable:** Add to checkpoints.yaml with SAME ID
4. ✅ **If manual-only:** Skip that ID in checkpoints.yaml, use next available number
5. ✅ **Run verification script** to check for conflicts
6. ✅ **Update this mapping document** with any new manual-only IDs

**Never reuse IDs that exist in rules.yaml for different checks in checkpoints.yaml!**
