# Bounded AI Queries for Thunder Plugin Validation

## The Problem with Open-Ended Review

**Traditional Approach (Verbose, Hard to Verify):**
```
Prompt: "Review this entire file for Thunder plugin violations"

Result:
- 50+ lines of general observations
- Vague references like "around line 100"
- Mixed concerns (style + logic + architecture)
- Hard to verify: "Did it really check X?"
- Not reproducible: Different results each run
```

**Example Output:**
> "The Dictionary.cpp file has several issues. The Initialize method doesn't follow best practices. There might be threading concerns. The error handling could be improved. Consider reviewing the lifecycle methods."

❌ **Not actionable. Not verifiable. Not specific.**

---

## The Solution: Bounded Queries

**Bounded Query Approach (Specific, Verifiable):**
```
Prompt: 
1. Extract: Initialize() method body (lines 108-125)
2. Question: "Does the first statement contain ASSERT(service != nullptr)?"
3. Expected: Yes

Result:
- Specific yes/no answer
- Exact line citation from extracted code
- Reproducible: Same extraction = Same answer
- Verifiable: Anyone can check the extracted line
```

**Example Output:**
> **Checkpoint 4.1: Initialize ASSERT**
> 
> Extracted code (Dictionary.cpp:108-111):
> ```cpp
> const string Dictionary::Initialize(PluginHost::IShell* service VARIABLE_IS_NOT_USED) {
>     _config.FromString(service->ConfigLine());
>     ...
> }
> ```
> 
> Question: "Is first statement 'ASSERT(service != nullptr);'?"
> Answer: **No**
> First statement: `_config.FromString(service->ConfigLine());`
> 
> **VIOLATION**: [Dictionary.cpp:108] Initialize missing ASSERT at start
> 
> Fix:
> ```cpp
> const string Dictionary::Initialize(PluginHost::IShell* service) {
>     ASSERT(service != nullptr);  // Add this
>     _config.FromString(service->ConfigLine());
> }
> ```

✅ **Actionable. Verifiable. Specific.**

---

## Bounded Query Framework

### Anatomy of a Checkpoint

Every checkpoint has 5 components:

```yaml
1. EXTRACTION
   What: "Initialize() method"
   How: "From 'Initialize(' to matching '}'"
   Result: Lines 108-125

2. BOUNDED QUERY
   Question: "Does first statement contain ASSERT(service != nullptr)?"
   Type: Yes/No
   Expected: Yes

3. VERIFICATION LOGIC
   Steps:
     - Extract method body
     - Skip opening brace
     - Read first non-comment statement
     - Compare exact text with ASSERT(service != nullptr)
     - If match: PASS, else: FAIL

4. VIOLATION PATTERN
   If: First statement != ASSERT(service != nullptr)
   Then: FAIL
   Cite: Line number of actual first statement

5. FIX TEMPLATE
   Action: "Add ASSERT(service != nullptr); as first line"
   Code: [exact code to add]
```

---

## Real Examples

### Example 1: VARIABLE_IS_NOT_USED Check

**❌ Open-Ended (Vague):**
> "The service parameter in Initialize seems to be marked as unused but it's actually used somewhere in the function."

**✅ Bounded Query (Specific):**

```yaml
Checkpoint: style_2_3

EXTRACT:
  Target: Initialize() method signature + complete body
  Lines: 108-125
  Code: |
    const string Dictionary::Initialize(
        PluginHost::IShell* service VARIABLE_IS_NOT_USED) {
        _config.FromString(service->ConfigLine());  // Line 115
        ...
    }

QUESTION: "Is parameter 'service' marked VARIABLE_IS_NOT_USED actually used in body?"

VERIFICATION:
  1. Extract parameter name: "service"
  2. Search body for "service" (excluding signature)
  3. Found at: Line 115 (service->ConfigLine())
  4. Count: 2 occurrences
  5. Verdict: Parameter IS used → VIOLATION

ANSWER: Yes (parameter IS used)

CITATION: [Dictionary.cpp:108] Parameter 'service' marked unused but used on line 115

FIX:
  // Remove VARIABLE_IS_NOT_USED
  const string Dictionary::Initialize(PluginHost::IShell* service)
```

**Verification:** Anyone can extract lines 108-125, search for "service", confirm it's used, reproduce the finding.

---

### Example 2: Error Code Overwrite Check

**❌ Open-Ended (Vague):**
> "There might be an issue with error handling in the Get method. The error codes don't look right."

**✅ Bounded Query (Specific):**

```yaml
Checkpoint: style_2_4

EXTRACT:
  Target: Get() method body
  Lines: 158-187
  Code: |
    Core::hresult Get(string& value) {
        Core::hresult result = Core::ERROR_UNKNOWN_KEY;  // Line 159
        
        _adminLock.Lock();
        if (found) {
            result = Core::ERROR_NONE;  // Line 167
        }
        _adminLock.Unlock();
        
        result = Core::ERROR_NONE;  // Line 183 ⚠️
        return result;
    }

QUESTION: "Does this function set error conditionally but then unconditionally overwrite?"

VERIFICATION:
  1. Find result init: ERROR_UNKNOWN_KEY (line 159)
  2. Find conditional set: ERROR_NONE if found (line 167)
  3. Search for unconditional set after conditional: Found line 183
  4. Check: Line 183 always sets ERROR_NONE
  5. Verdict: Overwrites proper error → VIOLATION

ANSWER: Yes (unconditional overwrite found)

CITATION: [Dictionary.cpp:183] Unconditional ERROR_NONE overwrites proper error

FIX:
  _adminLock.Unlock();
  // Remove this line:
  // result = Core::ERROR_NONE;
  return result;  // Keep previously computed result
```

**Verification:** Extract lines 158-187, trace result variable, confirm line 183 always overwrites, reproduce finding.

---

### Example 3: Callbacks Under Lock Check

**❌ Open-Ended (Vague):**
> "There could be threading issues. The locking doesn't look safe."

**✅ Bounded Query (Specific):**

```yaml
Checkpoint: implementation_5_5

EXTRACT:
  Target: Lock/Unlock block in Set() method
  Lines: 338-355
  Code: |
    _adminLock.Lock();
    
    // Internal work
    _dictionary[namespace][key] = value;
    
    // External callback
    NotifyForUpdate(path, key, value);  // Line 345 ⚠️
    
    _adminLock.Unlock();

QUESTION: "Between Lock and Unlock, are there external callback invocations?"

VERIFICATION:
  1. Find Lock() call: Line 338
  2. Find matching Unlock(): Line 355
  3. Extract code between: Lines 338-355
  4. Search for external call patterns:
     - NotifyForUpdate() → Found line 345
     - observer->Method() → Not found
     - J*::Event:: → Not found
  5. Verdict: External callback under lock → VIOLATION

ANSWER: Yes (NotifyForUpdate called under lock)

CITATION: [Dictionary.cpp:345] External callback invoked while holding _adminLock

FIX:
  bool shouldNotify = false;
  string savedPath, savedKey, savedValue;
  
  _adminLock.Lock();
  _dictionary[namespace][key] = value;
  if (changed) {
      shouldNotify = true;
      savedPath = path;
      savedKey = key;
      savedValue = value;
  }
  _adminLock.Unlock();
  
  if (shouldNotify) {
      NotifyForUpdate(savedPath, savedKey, savedValue);
  }
```

**Verification:** Extract lines 338-355, find NotifyForUpdate between Lock/Unlock, confirm violation.

---

## Comparison Table

| Aspect | Open-Ended Review | Bounded Query |
|--------|------------------|---------------|
| **Input** | "Review this file" | "Extract Initialize(), check ASSERT" |
| **Scope** | Entire file | Single code block |
| **Question** | Implicit "find problems" | Explicit yes/no question |
| **Output** | Narrative description | Structured checkpoint result |
| **Line Reference** | "Around line 100" | "Line 108" (exact) |
| **Verification** | Hard to reproduce | Easy to reproduce |
| **Actionability** | "Consider improving" | "Add this exact line" |
| **Consistency** | Varies per run | Same extraction = same result |
| **False Positives** | Moderate | Low (explicit logic) |
| **Time** | Slow (full analysis) | Fast (focused extraction) |

---

## Benefits for Thunder Plugin Review

### 1. Verifiable Findings
Every violation can be independently verified:
```
1. Extract lines 108-125
2. Check first statement
3. Confirm it's not ASSERT
4. Reproduce violation
```

### 2. Logical Reasoning
Each checkpoint shows its reasoning:
```
Reasoning:
  - Extracted Initialize body (lines 108-125)
  - First statement is: _config.FromString(...)
  - Expected: ASSERT(service != nullptr)
  - Mismatch confirmed → VIOLATION
```

### 3. Conditional Checks with Logic
```yaml
Checkpoint: lifecycle_4_2 (IShell AddRef)

Logic:
  1. Search class for IShell* member
  2. IF NOT found → SKIP (not applicable)
  3. IF found → Extract Initialize
  4. Search for AddRef after assignment
  5. IF missing → VIOLATION

Result: SKIP
Reasoning: "Searched Dictionary.h for IShell* member, not found, 
            AddRef check not applicable to this plugin architecture"
```

### 4. Interface Implementation Checks
```yaml
Checkpoint: registration_3_2 (IPlugin in interface map)

EXTRACT:
  Target: BEGIN_INTERFACE_MAP...END_INTERFACE_MAP
  Lines: 276-282
  Code: |
    BEGIN_INTERFACE_MAP(Dictionary)
        INTERFACE_ENTRY(PluginHost::IPlugin)      // ✓
        INTERFACE_ENTRY(Exchange::IDictionary)     // ✓
        INTERFACE_ENTRY(PluginHost::IDispatcher)   // ✓
    END_INTERFACE_MAP

QUESTION: "Does interface map include INTERFACE_ENTRY(PluginHost::IPlugin)?"

VERIFICATION:
  1. Extract interface map block
  2. Search for exact text: "INTERFACE_ENTRY(PluginHost::IPlugin)"
  3. Found: Line 277
  4. Verdict: PASS

ANSWER: Yes

STATUS: ✅ PASS
```

### 5. Reduced False Positives
Explicit logic prevents incorrect flagging:
```yaml
Checkpoint: IShell Storage (Conditional)

Wrong approach:
  "Plugin doesn't store IShell* → FLAG VIOLATION"

Bounded approach:
  1. Check if IShell* member exists
  2. IF NOT → SKIP (storage not needed for this architecture)
  3. IF YES → Check AddRef
  Result: SKIP - No false positive
```

---

## Implementation in Thunder QA Tool

### File Structure
```
rules/
├── thunder-plugin-rules-checkpoints.yaml  # 17 focused checkpoints
└── thunder-plugin-rules.yaml               # 36+ comprehensive checks
```

### Checkpoint YAML Structure
```yaml
checkpoints:
  - checkpoint_id: "lifecycle_4_1"
    name: "Initialize starts with ASSERT"
    severity: "violation"
    
    extraction:
      target: "Initialize() method"
      method: "Extract from 'Initialize(IShell* service)' to matching '}'"
      code_block: "Complete Initialize() body"
    
    bounded_query:
      question: "Is first statement 'ASSERT(service != nullptr);'?"
      expected_answer: "Yes"
    
    verification_logic:
      - "Extract Initialize() body"
      - "Skip opening brace"
      - "Get first non-comment, non-blank statement"
      - "Compare exactly: ASSERT(service != nullptr);"
      - "If mismatch: VIOLATION, cite line"
    
    violation_pattern:
      condition: "First statement is not ASSERT"
      example: "_config.FromString(...)  // Wrong first statement"
    
    fix_template:
      action: "Add ASSERT as first statement"
      code: "ASSERT(service != nullptr);"
```

### Usage
```bash
# In VS Code Copilot Chat:
/thunder-checkpoint-review

# Output:
Checkpoint 4.1: Initialize ASSERT
  Status: FAIL
  Question: "Is first statement ASSERT(service != nullptr)?"
  Answer: No
  Citation: [Dictionary.cpp:108]
  Fix: Add ASSERT(service != nullptr); as first line
```

---

## Summary

**Bounded Queries Provide:**
- ✅ Specific, verifiable findings
- ✅ Exact line citations
- ✅ Reproducible results
- ✅ Actionable fixes
- ✅ Logical reasoning shown
- ✅ Low false positive rate
- ✅ Consistent across runs

**Compared to Open-Ended Review:**
- ❌ Vague observations
- ❌ Approximate line references
- ❌ Inconsistent results
- ❌ Hard to verify
- ❌ Reasoning implicit
- ❌ Higher false positive risk

**Use Bounded Queries When:**
- Need precise, verifiable validation
- Debugging specific violations
- Teaching/learning Thunder rules
- Building CI/CD validation
- Requiring reproducible results

**Use Comprehensive Review When:**
- Need full plugin assessment
- Learning plugin architecture
- Pre-commit compliance check
- First-time plugin review
