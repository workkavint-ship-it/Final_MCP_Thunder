# Thunder Plugin Rules Coverage Analysis
## 12 Critical Rules vs 26 Automated + 10 Manual Checkpoints

**Analysis Date:** May 4, 2026  
**Purpose:** Verify all critical Thunder plugin rules are covered by validation system

---

## Coverage Matrix

| # | Rule | Coverage Status | Checkpoint(s) | Gap Analysis |
|---|------|-----------------|---------------|--------------|
| 1 | IPlugin contract (Initialize/Deinitialize symmetry, AddRef/Release) | ✅ 80% Covered | lifecycle_4_1, 4_2, 4_3 | Missing: Deinitialize must complete |
| 2 | COM interface rules (hresult, virtual IUnknown, EXTERNAL, immutability) | ❌ 20% Covered | (none) | **MISSING: Need new checkpoints** |
| 3 | Interface map completeness (all implemented interfaces) | ⚠️ 50% Covered | registration_3_2 | Only checks IPlugin, not ALL interfaces |
| 4 | Sink pattern (SinkType vs heap, Unavailable()) | ✅ 70% Covered | implementation_5_4 | Missing: Unavailable() check |
| 5 | JSONRPC symmetry (Register/Unregister pairing) | ✅ 100% Covered | implementation_5_2 | **COMPLETE** ✓ |
| 6 | Config class pattern (JSON::Container, ctor defaults) | ⚠️ 60% Covered | implementation_5_3 | Missing: JSON::Container base, ctor defaults |
| 7 | No exceptions, no STL, no delete on COM | ⚠️ 70% Covered | style_2_8, style_2_7 | Missing: delete on COM objects |
| 8 | Module.h first include | ✅ 100% Covered | module_1_1 | **COMPLETE** ✓ |
| 9 | Path tokens (no hardcoded paths) | ❌ 0% Covered | (none) | **MISSING: Need new checkpoint** |
| 10 | Plugin registration (Metadata<T>) | ✅ 100% Covered | registration_3_4 | **COMPLETE** ✓ |
| 11 | Error handling (hresult, Deinitialize completion) | ⚠️ 50% Covered | style_2_8 | Missing: Deinitialize error handling |
| 12 | OOP-specific (EXTERNAL, connection->Terminate()) | ❌ 0% Covered | (none) | **MISSING: Need new checkpoints** |

---

## Detailed Analysis

### ✅ FULLY COVERED (3 rules - 100%)

#### **Rule 5: JSONRPC Symmetry**
**Checkpoint:** implementation_5_2  
**Coverage:** Every Register has matching Unregister  
**Status:** Complete ✓

#### **Rule 8: Module.h First Include**
**Checkpoint:** module_1_1  
**Coverage:** Verifies Module.h is first #include  
**Status:** Complete ✓

#### **Rule 10: Plugin Registration**
**Checkpoint:** registration_3_4  
**Coverage:** Metadata<T> or SERVICE_REGISTRATION present  
**Status:** Complete ✓

---

### ⚠️ PARTIALLY COVERED (5 rules - 50-80%)

#### **Rule 1: IPlugin Contract (80% covered)**
**Existing Checkpoints:**
- ✅ lifecycle_4_1: Initialize starts with ASSERT(service != nullptr)
- ✅ lifecycle_4_2: IShell AddRef if stored
- ✅ lifecycle_4_3: Deinitialize ASSERT(_service == service)
- ✅ lifecycle_4_7: Deinitialize releases observers

**Missing:**
- ❌ Deinitialize must complete successfully (no early returns on error)
- ❌ Initialize/Deinitialize resource pairing verification

**Recommendation:** Add lifecycle_4_9 - Deinitialize completion guarantee

---

#### **Rule 3: Interface Map Completeness (50% covered)**
**Existing Checkpoints:**
- ✅ registration_3_2: IPlugin in interface map

**Missing:**
- ❌ All implemented interfaces in map (not just IPlugin)
- ❌ No missing INTERFACE_ENTRY for inherited interfaces

**Recommendation:** Enhance registration_3_2 or add registration_3_5 - Complete interface map

---

#### **Rule 4: Sink Pattern (70% covered)**
**Existing Checkpoints:**
- ✅ implementation_5_4: SinkType usage (extended checkpoints)

**Missing:**
- ❌ Sink classes implement Unavailable() method
- ❌ Sink reference vs pointer pattern

**Recommendation:** Add implementation_5_9 - Sink Unavailable() method

---

#### **Rule 6: Config Class Pattern (60% covered)**
**Existing Checkpoints:**
- ✅ implementation_5_3: Config not stored as member

**Missing:**
- ❌ Config class inherits from Core::JSON::Container
- ❌ Config members initialized with defaults in constructor
- ❌ Config::FromString() called only in Initialize

**Recommendation:** Add implementation_5_10 - Config class structure

---

#### **Rule 7: No Exceptions/STL/Delete (70% covered)**
**Existing Checkpoints:**
- ✅ style_2_8: No exceptions (throw/try/catch)
- ✅ style_2_7: No std::string

**Missing:**
- ❌ No `delete` or `delete[]` on COM interface pointers
- ❌ Must use ->Release() instead

**Recommendation:** Add style_2_9 - No delete on COM objects

---

#### **Rule 11: Error Handling (50% covered)**
**Existing Checkpoints:**
- ✅ style_2_8: No exceptions

**Missing:**
- ❌ Deinitialize must not fail (void return, complete cleanup)
- ❌ Initialize returns error string on failure
- ❌ All hresult error codes checked

**Recommendation:** Add lifecycle_4_10 - Deinitialize error-free completion

---

### ❌ NOT COVERED (4 rules - 0-20%)

#### **Rule 2: COM Interface Rules (20% covered)**
**Coverage:** None for most aspects

**Missing Checks:**
- ❌ Interface methods return Core::hresult
- ❌ Interface inherits from Core::IUnknown or Exchange::*
- ❌ Interface uses EXTERNAL macro for out-of-process
- ❌ Interface methods are const (no mutation of COM state)
- ❌ No raw pointers in interface signatures (use ComPtr or ref)

**Recommendation:** Add new checkpoint category "Phase 8: COM Interfaces"
- com_8_1: Interface inherits IUnknown
- com_8_2: Methods return hresult
- com_8_3: EXTERNAL macro for OOP interfaces
- com_8_4: Methods are const where appropriate
- com_8_5: No raw pointers in signatures

---

#### **Rule 9: Path Tokens (0% covered)**
**Coverage:** None

**Missing Checks:**
- ❌ No hardcoded absolute paths like "/tmp", "C:\\"
- ❌ Use path tokens: %datapath%, %persistentpath%, %volatilepath%
- ❌ service->DataPath(), service->PersistentPath(), service->VolatilePath()

**Example Violation:**
```cpp
// ❌ Wrong:
_storagePath = "/tmp/plugin";

// ✅ Correct:
_storagePath = service->PersistentPath() + "plugin/";
```

**Recommendation:** Add implementation_5_11 - Path token usage
- Search for hardcoded "/" or "\\" paths
- Verify service->*Path() usage
- Check .conf.in for path tokens

---

#### **Rule 12: OOP-Specific Patterns (0% covered)**
**Coverage:** None

**Missing Checks:**
- ❌ OOP interfaces use EXTERNAL macro
- ❌ OOP plugins call connection->Terminate() in Deinitialize
- ❌ RPC::IRemoteConnection pointer managed correctly
- ❌ OOP plugin registration before Root<T>() call

**Example Pattern:**
```cpp
// Interface definition (in .h):
struct EXTERNAL IMyInterface : virtual public Core::IUnknown {
    virtual uint32_t DoWork() = 0;
};

// Plugin Deinitialize:
RPC::IRemoteConnection* connection = _service->RemoteConnection(_connectionId);
if (connection != nullptr) {
    connection->Terminate();
    connection->Release();
}
```

**Recommendation:** Add new checkpoint category "Phase 9: Out-of-Process"
- oop_9_1: EXTERNAL macro on OOP interfaces
- oop_9_2: connection->Terminate() in Deinitialize
- oop_9_3: RPC::IRemoteConnection AddRef/Release
- oop_9_4: Root<T>() after notification registration (already lifecycle_4_5 manual)

---

## Summary Statistics

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Fully Covered (90-100%) | 3 | 25% |
| ⚠️ Partially Covered (50-89%) | 5 | 42% |
| ❌ Not Covered (0-49%) | 4 | 33% |

**Total Coverage:** ~60% of critical rules automated

---

## Recommended New Checkpoints

### **High Priority (Missing Critical Rules)**

1. **com_8_1-8_5**: COM Interface Rules (Rule 2)
   - Type: Automated bounded query
   - Extract interface definitions, check patterns
   - Effort: Medium

2. **implementation_5_11**: Path Token Usage (Rule 9)
   - Type: Automated bounded query
   - Search for hardcoded paths
   - Effort: Low

3. **oop_9_1-9_4**: Out-of-Process Patterns (Rule 12)
   - Type: Conditional automated + manual
   - Only applies to OOP plugins
   - Effort: Medium

### **Medium Priority (Enhance Existing Coverage)**

4. **style_2_9**: No Delete on COM Objects (Rule 7 enhancement)
   - Type: Automated bounded query
   - Search for delete with interface pointers
   - Effort: Low

5. **lifecycle_4_9**: Deinitialize Completion Guarantee (Rule 1 enhancement)
   - Type: Manual review
   - Check for early returns in Deinitialize
   - Effort: Low

6. **implementation_5_9**: Sink Unavailable() Method (Rule 4 enhancement)
   - Type: Automated bounded query
   - Check SinkType classes implement Unavailable
   - Effort: Medium

7. **implementation_5_10**: Config Class Structure (Rule 6 enhancement)
   - Type: Automated bounded query
   - Verify JSON::Container inheritance, ctor defaults
   - Effort: Low

8. **registration_3_5**: Complete Interface Map (Rule 3 enhancement)
   - Type: Manual review (complex)
   - Verify all interfaces in map
   - Effort: High

---

## Implementation Priority

### **Phase 1: Add 3 High-Priority Automated Checkpoints** (1-2 weeks)
1. implementation_5_11 - Path tokens
2. style_2_9 - No delete on COM
3. com_8_2 - COM methods return hresult

### **Phase 2: Add 4 Medium-Priority Enhancements** (2-3 weeks)
4. implementation_5_9 - Sink Unavailable()
5. implementation_5_10 - Config structure
6. lifecycle_4_9 - Deinitialize completion (manual)
7. oop_9_2 - connection->Terminate() (conditional)

### **Phase 3: Add 4 Complex Checkpoints** (3-4 weeks)
8. com_8_1 - IUnknown inheritance
9. com_8_3 - EXTERNAL macro
10. oop_9_1 - OOP EXTERNAL usage
11. registration_3_5 - Complete interface map (manual)

---

## Updated Checkpoint Count After Implementation

**Current:** 26 automated + 10 manual = 36 total  
**After Phase 1:** 29 automated + 10 manual = 39 total  
**After Phase 2:** 32 automated + 11 manual = 43 total  
**After Phase 3:** 35 automated + 12 manual = 47 total  

**Target Coverage:** ~85% of critical rules automated

---

## Next Steps

1. ✅ Review this analysis with team
2. ⬜ Prioritize which checkpoints to implement first
3. ⬜ Create YAML definitions for new checkpoints
4. ⬜ Test new checkpoints on Dictionary and BluetoothControl
5. ⬜ Update documentation and prompts
6. ⬜ Roll out to full plugin suite

---

## Appendix: Detection Methods for Missing Rules

### **Path Token Detection (Rule 9)**
```powershell
# Search for hardcoded paths
grep -rn '"/tmp\|/var\|C:\\' *.cpp *.h

# Look for missing path token usage
grep -L 'PersistentPath\|DataPath\|VolatilePath' *.cpp
```

### **COM Delete Detection (Rule 7)**
```powershell
# Find delete on interface pointers
grep -n 'delete.*I[A-Z][a-z]*;' *.cpp

# Look for proper Release pattern
grep -A 2 'delete' *.cpp | grep -v 'Release'
```

### **OOP Pattern Detection (Rule 12)**
```powershell
# Find EXTERNAL macro usage
grep -n 'struct.*EXTERNAL' *.h

# Find connection->Terminate
grep -n 'connection->Terminate\|RemoteConnection' *.cpp
```

### **Deinitialize Completion (Rule 11)**
```cpp
// Manual check: Look for early returns
void Deinitialize(...) {
    if (error) {
        return;  // ❌ Violation - incomplete cleanup
    }
    // Must complete all cleanup
}
```

---

**Conclusion:** Current system covers 60% of critical rules. Adding 11 new checkpoints (Phases 1-3) will bring coverage to 85%.
