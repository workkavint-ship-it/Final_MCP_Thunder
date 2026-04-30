# Thunder Plugin QA Tool - Quick Start

Get started with the Thunder Plugin Quality Assurance Tool in 3 minutes!

## Step 1: Run Setup (1 minute)

### Windows
Open PowerShell in the workspace root and run:
```powershell
cd ThunderTools\PluginQA
python setup.py
```

### Linux/Mac
Open terminal in the workspace root and run:
```bash
cd ThunderTools/PluginQA
chmod +x setup.sh
./setup.sh
```

## Step 2: Restart VS Code (30 seconds)

Close and reopen VS Code to load the new commands.

## Step 3: Try Your First Command (1 minute)

Open Copilot Chat (Ctrl+Alt+I or Cmd+Option+I) and type:

```
/thunder-review
```

You should see the Thunder plugin review command activate!

## Available Commands

- **`/thunder-review`** - Review a plugin file for rule violations
- **`/thunder-generate`** - Generate a new plugin skeleton
- **`/thunder-pattern`** - Get Thunder code patterns
- **`/thunder-interface`** - Validate COM interfaces

## Next Steps

1. Open a plugin file from ThunderNanoServices
2. Run `/thunder-review` on it
3. See the AI analyze it against Thunder rules
4. Read [USAGE.md](USAGE.md) for detailed documentation

## Troubleshooting

**Commands not showing?**
- Make sure you restarted VS Code
- Check if GitHub Copilot is enabled
- Verify the setup completed successfully

**Need help?**
- Read the full [USAGE.md](USAGE.md) guide
- Check the [rules documentation](rules/)
- See [README.md](README.md) for overview

---

**That's it! You're ready to use Thunder Plugin QA Tool.** 🚀
