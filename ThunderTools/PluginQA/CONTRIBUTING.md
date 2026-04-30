# Contributing to Thunder Plugin QA Tool

Thank you for your interest in improving the Thunder Plugin QA Tool!

## Ways to Contribute

### 1. Add New Rules

If you identify new patterns or best practices for Thunder plugins:

1. Create a new markdown file in `rules/`
2. Follow this template:

```markdown
---
applyTo: '**/*.cpp'  # Glob pattern for when this rule applies
---

# Rule Title

> Brief description of what this rule covers

## Summary

- [Section 1](#section-1)
- [Section 2](#section-2)

## Section 1

### Requirement

Describe what must be done.

### Example

```cpp
// Good code example
```

### Common Mistakes

```cpp
// Bad code example
```
```

3. Reference the new rule in related prompt files

### 2. Improve Prompts

The AI behavior is controlled by `.prompt.md` files in `prompts/`:

- `thunder-review.prompt.md` - Plugin review logic
- `thunder-generate.prompt.md` - Plugin generation workflow
- `thunder-pattern.prompt.md` - Pattern responses
- `thunder-interface.prompt.md` - Interface validation

**To improve prompts:**

1. Edit the relevant `.prompt.md` file
2. Test with actual plugins in VS Code Copilot Chat
3. Iterate until the AI behavior matches your expectations
4. Document any significant changes

**Prompt structure:**
```markdown
---
title: Command Title
description: Brief description
---

# Detailed Instructions

Your instructions to the AI about how to behave...

## Context
Background information...

## Your Task
Step-by-step instructions...

## Output Format
How results should be structured...

## Example
Sample interaction...
```

### 3. Enhance Setup Scripts

The setup scripts can always be improved:

- **`setup.py`** - Python setup script (cross-platform)
- **`setup.sh`** - Bash setup script (Linux/Mac)
- **`setup.bat`** - Batch setup script (Windows)

**Areas for improvement:**
- Better error handling
- More OS detection
- Configuration validation
- Interactive mode improvements

### 4. Add Examples

Help others by adding real-world examples:

1. Create an `examples/` directory
2. Add example plugin files with comments showing violations
3. Include expected output from review commands
4. Document in USAGE.md

### 5. Improve Documentation

- Fix typos or unclear instructions
- Add screenshots or diagrams
- Expand troubleshooting section
- Add more usage examples

## Testing Your Changes

### Testing Rules

1. Create or find a plugin that violates/follows the rule
2. Run `/thunder-review` in Copilot Chat
3. Verify the AI correctly identifies the issue
4. Check that the explanation is clear

### Testing Prompts

1. Make your changes to the `.prompt.md` file
2. Restart VS Code (or reload window)
3. Open Copilot Chat
4. Test the command with various inputs
5. Verify output quality and consistency

### Testing Setup Scripts

#### Python script:
```bash
# Create a test environment
mkdir test_setup
cd test_setup
cp ../setup.py .

# Run setup
python setup.py

# Verify settings.json was created/updated
cat .vscode/settings.json
```

#### Shell script:
```bash
# Test on Linux/Mac
chmod +x setup.sh
./setup.sh

# Verify settings
cat .vscode/settings.json
```

## Code Style

### Python Code

Follow PEP 8:
```python
# Good
def find_vscode_settings_file():
    """Find the VS Code settings.json file."""
    workspace_settings = Path('.vscode/settings.json')
    return workspace_settings

# Use type hints where helpful
def update_settings(settings_file: Path, settings: dict) -> bool:
    pass
```

### Shell Scripts

Follow Google Shell Style Guide:
```bash
# Good
find_vscode_settings() {
    local workspace_settings=".vscode/settings.json"
    echo "$workspace_settings"
}

# Always check exit codes
if [ $? -ne 0 ]; then
    print_error "Setup failed"
    exit 1
fi
```

### Markdown

- Use proper heading levels
- Include code blocks with language tags
- Add blank lines between sections
- Use lists for readability

## Submitting Changes

1. **Fork the repository** (if external contributor)

2. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/improve-lifecycle-rules
   ```

3. **Make your changes** following the guidelines above

4. **Test thoroughly** using the testing steps above

5. **Commit with clear messages**:
   ```bash
   git commit -m "Add rule for JSON-RPC lifecycle management
   
   - Added 10.8-jsonrpc-lifecycle.md
   - Updated thunder-review.prompt.md to reference new rule
   - Added example in USAGE.md"
   ```

6. **Push and create pull request**:
   ```bash
   git push origin feature/improve-lifecycle-rules
   ```

7. **Describe your changes** in the PR:
   - What problem does this solve?
   - What changes did you make?
   - How did you test it?
   - Any breaking changes?

## Questions?

- Check existing issues in the Thunder repository
- Ask in Thunder community channels
- Review Thunder documentation

## License

By contributing, you agree that your contributions will be licensed under the same license as the Thunder project (Apache 2.0).

---

Thank you for helping make Thunder plugin development better! 🙏
