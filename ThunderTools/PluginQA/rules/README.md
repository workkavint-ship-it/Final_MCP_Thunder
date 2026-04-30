# Thunder Plugin Rules

This directory contains the Thunder plugin development rules in both **Markdown** and **YAML** formats.

## Files

### YAML Format (Recommended for Tools)
- **thunder-plugin-rules.yaml** - Comprehensive, machine-readable rule set (36+ checks)
- **thunder-plugin-rules-checkpoints.yaml** - Bounded-query checkpoint validation (17 focused checks)

### Markdown Format (Human Reference)
- **10-plugin-development.md** - Overview and checklist
- **10.1-plugin-module.md** - Module structure
- **10.2-plugin-codestyle.md** - Code style and conventions
- **10.3-plugin-class-registration.md** - Class and registration
- **10.4-plugin-lifecycle.md** - Lifecycle management
- **10.5-plugin-implementation.md** - Implementation patterns
- **10.6-plugin-config.md** - Configuration files
- **10.7-plugin-cmake.md** - CMake build system

---

## YAML Formats Explained

### thunder-plugin-rules.yaml - Comprehensive Review

Full systematic validation with 36+ checks organized into 7 phases:

```yaml
phases:
  - id: "phase_1"
    name: "Module Structure"
    checks:
      - id: "module_1_1"
        name: "Module.h first include"
        severity: "violation"
        verification: [steps...]
```

**Best for:**
- Complete plugin validation
- Compliance checking
- Pre-commit reviews
- Learning all Thunder rules

---

### thunder-plugin-rules-checkpoints.yaml - Bounded Query Validation

Focused validation using **bounded AI queries** - each checkpoint extracts ONE code block and asks ONE specific yes/no question:

```yaml
checkpoints:
  - checkpoint_id: "lifecycle_4_1"
    name: "Initialize starts with ASSERT"
    
    extraction:
      target: "Initialize() method"
      code_block: "Complete Initialize() body"
      
    bounded_query:
      question: "Is first statement 'ASSERT(service != nullptr);'?"
      expected_answer: "Yes"
      
    verification_logic:
      - "Extract Initialize() body"
      - "Skip opening brace"
      - "Get first non-comment statement"
      - "Compare with ASSERT(service != nullptr)"
      - "If mismatch → violation, cite line"
      
    violation_pattern:
      example_wrong: |
        const string Initialize(IShell* service) {
            _config.FromString(...);  // ❌ Missing ASSERT
        }
        
    fix_template:
      code: |
        const string Initialize(IShell* service) {
            ASSERT(service != nullptr);  // Add this
            ...
        }
```

**Key Differences:**

| Aspect | Comprehensive | Checkpoint |
|--------|---------------|------------|
| Checks | 36+ | 17 focused |
| Methodology | Whole-file analysis | Bounded extraction |
| Query type | Open-ended "find issues" | Specific "yes/no" questions |
| Output | Full report | Per-checkpoint results |
| Verification | Context-aware | Explicit logic steps |
| Best for | Complete validation | Precise verification |

**Bounded Query Example:**
```
Extract: Dictionary.cpp lines 108-125 (Initialize method)
Question: "Does first statement contain ASSERT(service != nullptr)?"
Answer: No
Code: _config.FromString(service->ConfigLine());  // Line 108
Citation: [Dictionary.cpp:108] Initialize missing ASSERT at start
Fix: Add ASSERT(service != nullptr); as first line
Reasoning: Extracted Initialize, first stmt is FromString not ASSERT, confirmed violation
```

**Best for:**
- Debugging specific violations
- Verifiable, reproducible findings
- Teaching/learning Thunder rules
- Fast targeted validation
- CI/CD integration (clear pass/fail)

## YAML Structure

The `thunder-plugin-rules.yaml` file consolidates all rules into a single, structured format:

```yaml
metadata:
  version: "1.0.0"
  description: "Thunder plugin development standards"
  
phases:
  - id: "phase_1"
    name: "Module Structure"
    checks:
      - id: "module_1_1"
        name: "Module.h first include"
        severity: "violation"
        verification: [steps...]
```

### Key Sections

#### 1. **phases** 
7 review phases with 36+ specific checks:
- Phase 1: Module Structure (4 checks)
- Phase 2: Code Style & Basics (7 checks)
- Phase 3: Class Registration (3 checks)
- Phase 4: Lifecycle Management (8 checks)
- Phase 5: Implementation Patterns (8 checks)
- Phase 6: Configuration Files (2 checks, conditional)
- Phase 7: Build System (4 checks)

Each check includes:
- `id`: Unique identifier
- `name`: Short description
- `severity`: violation | warning | suggestion
- `description`: What to check
- `rationale`: Why it matters
- `verification`: Steps to verify (if complex)
- `correct_example`: Code showing correct pattern
- `incorrect_example`: Code showing wrong pattern
- `conditional`: true if check only applies in certain cases

#### 2. **common_mistakes**
Table of 10 frequent errors with:
- Description of mistake
- Consequence
- Fix
- Phase and check_id mapping

#### 3. **architecture_patterns**
Detection patterns for:
- In-process vs Out-of-process plugins
- JSON-RPC enabled plugins
- Plugins with configuration
- Plugins storing IShell*

Each pattern includes `indicators` and `implications` for review.

#### 4. **verification_templates**
Logic templates for complex checks:
- `variable_is_not_used`: How to verify parameter usage
- `error_code_overwrite`: How to detect improper error handling
- `callback_under_lock`: How to identify deadlock risks
- `ishell_storage`: How to verify AddRef/Release patterns

Each template includes:
- Step-by-step verification process
- Confidence level
- False positive risk guidance

#### 5. **rule_citation_map**
Maps topics to correct rule file citations:
```yaml
"Error handling": "10.2-plugin-codestyle.md"
"Thread safety": "10.5-plugin-implementation.md"
"cmake_minimum_required ordering": "10.7-plugin-cmake.md"
```

Prevents citing wrong rule files in review output.

#### 6. **checklist_summary**
Statistics:
- Total phases: 7
- Total checks: 36
- Mandatory: 28
- Conditional: 8
- Severity breakdown

## Using the YAML File

### For AI Review Tools
The `/thunder-review` command reads this YAML file to:
1. Load all rules systematically
2. Apply the mandatory checklist
3. Verify each check using templates
4. Cite correct rules using the map
5. Avoid false positives using verification logic

### For Manual Review
Read the YAML alongside the Markdown files:
- YAML provides structure and checklist
- Markdown provides detailed explanations and context

### For Custom Tools
Parse the YAML to build:
- Static analysis tools
- IDE plugins
- CI/CD validation scripts
- Custom review workflows

## Updating Rules

When updating rules:

1. **Update both formats**:
   - Edit Markdown files for human readers
   - Update YAML file for tool consistency

2. **Increment version**:
   - Update `metadata.version` in YAML
   - Update last_updated timestamp

3. **Test changes**:
   - Run `/thunder-review` on test plugins
   - Verify all checks still work
   - Check for false positives

## Version History

- **1.0.0** (2026-04-30) - Initial YAML conversion from 8 Markdown files
  - 7 phases, 36 checks
  - Architecture patterns
  - Verification templates
  - Common mistakes table
  - Rule citation map
