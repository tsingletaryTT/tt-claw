# Homebrew Access Enabled for ttclaw

**Date:** 2026-03-07
**Status:** ✅ Configured and Tested

---

## Summary

OpenClaw (running as ttclaw user) now has full access to Homebrew at `/home/linuxbrew/.linuxbrew`.

---

## What Was Done

### 1. Changed Ownership
```bash
sudo chown -R ttclaw:ttclaw /home/linuxbrew/.linuxbrew
```

**Before:** Owned by ttuser (read-only for ttclaw)
**After:** Owned by ttclaw (full read/write access)

### 2. Added to PATH
Added to `/home/ttclaw/.bashrc`:
```bash
# === Homebrew Setup ===
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

This automatically sets:
- `PATH` to include homebrew bin and sbin
- `MANPATH` for homebrew man pages
- `INFOPATH` for homebrew info docs
- Other homebrew environment variables

### 3. Updated Welcome Message
ttclaw users now see on login:
```
Homebrew: Available (brew command)
```

---

## Testing Results

```bash
$ sudo -u ttclaw bash -c 'brew --version'
Homebrew 5.0.16

$ sudo -u ttclaw bash -c 'test -w /home/linuxbrew/.linuxbrew && echo "Can write"'
Can write
```

✅ **Working perfectly!**

---

## What ttclaw Can Now Do

### Install Packages
```bash
brew install <package>
```

### Search for Packages
```bash
brew search <query>
```

### List Installed Packages
```bash
brew list
```

### Update Homebrew
```bash
brew update
```

### Get Package Info
```bash
brew info <package>
```

---

## Why This Matters for OpenClaw

OpenClaw may need to install:
- **Development tools** - git, node, python tools
- **CLI utilities** - jq, curl, wget, etc.
- **Language runtimes** - Additional Node.js versions, Python packages
- **System tools** - tmux, screen, etc.
- **OpenClaw dependencies** - Tools the agent wants to use

With homebrew access, OpenClaw can:
- Install dependencies automatically
- Use standard package manager (familiar to agents/LLMs)
- Install without needing sudo/root
- Keep installations isolated from system packages

---

## Security Considerations

### ✅ Safe
- Homebrew installs to user-space (`/home/linuxbrew`)
- No system-wide changes
- ttclaw has no sudo access
- Cannot modify system packages
- Isolated from ttuser's environment

### ⚠️ Note
- ttclaw now owns the homebrew installation
- ttuser can still use homebrew (it's world-readable)
- If ttuser needs to install packages, they should either:
  - Use `sudo -u ttclaw brew install <package>`
  - Or ask ttclaw to install it

---

## Example Usage (as ttclaw)

```bash
# Login as ttclaw
sudo -u ttclaw -i

# Homebrew is automatically in PATH
brew --version

# Install a tool
brew install jq

# Use the installed tool
jq --version

# Search for packages
brew search node

# Get info about a package
brew info python@3.12
```

---

## Homebrew Location

- **Installation**: `/home/linuxbrew/.linuxbrew/`
- **Binary**: `/home/linuxbrew/.linuxbrew/bin/brew`
- **Cellar**: `/home/linuxbrew/.linuxbrew/Cellar/` (installed packages)
- **Casks**: `/home/linuxbrew/.linuxbrew/Caskroom/` (GUI apps, if any)

---

## If ttuser Needs to Use Homebrew

Since ownership changed to ttclaw, if ttuser wants to install packages:

### Option 1: Run as ttclaw
```bash
sudo -u ttclaw brew install <package>
```

### Option 2: Change ownership back temporarily
```bash
# Make it writable by both
sudo chmod -R g+w /home/linuxbrew/.linuxbrew
sudo chgrp -R ttshare /home/linuxbrew/.linuxbrew  # If ttshare group exists
```

### Option 3: Ask ttclaw to install
- Send message to ttclaw
- Or leave a note in shared directory

---

## Troubleshooting

### Permission Denied
```bash
# Check ownership
ls -ld /home/linuxbrew/.linuxbrew
# Should show: drwxr-xr-x ttclaw ttclaw

# Fix if needed
sudo chown -R ttclaw:ttclaw /home/linuxbrew/.linuxbrew
```

### Brew Command Not Found
```bash
# Make sure PATH is set
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Or check .bashrc
grep brew ~/.bashrc
```

### Brew Update Issues
```bash
# Update homebrew itself
brew update

# If git issues, may need to set git config
git config --global --add safe.directory /home/linuxbrew/.linuxbrew/Homebrew
```

---

## Integration with OpenClaw

OpenClaw can now use homebrew in skills and tools:

### Example: Installing a dependency
```javascript
// In an OpenClaw skill
async function installTool(toolName) {
  const result = await exec(`brew install ${toolName}`);
  return result;
}
```

### Example: Checking if tool exists
```bash
# In shell script
if brew list jq &>/dev/null; then
  echo "jq is installed"
else
  brew install jq
fi
```

---

## Summary

✅ **Homebrew is now fully accessible to ttclaw**
✅ **Added to PATH automatically on login**
✅ **Full read/write permissions**
✅ **Tested and working**
✅ **Safe and isolated from system packages**

**OpenClaw can now install and use any homebrew packages it needs!** 🍺

---

**Updated**: 2026-03-07
**Owner**: ttclaw
**Location**: /home/linuxbrew/.linuxbrew
**Version**: Homebrew 5.0.16
**Status**: Production-ready ✅
