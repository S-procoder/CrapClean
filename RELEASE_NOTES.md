# Release notes - ready to paste into GitHub Releases

Two releases. `v1.0` is the original batch file, kept exactly as it was.
`v2.0` is the rewrite with a window. Create them in that order so 2.0 shows as "Latest".

---

## Release 1.0 - tag `v1.0` - target commit `cb1c42f` (repo state before the 2.0 rewrite)

**Title:** CrapClean 1.0 - the original batch script

**Body:**

```markdown
The original CrapClean: one `.bat` file that clears temp folders, Prefetch, Recent items
and runs Disk Cleanup.

This release exists so the first version stays available and unchanged. It is **not
maintained** - use [2.0](https://github.com/S-procoder/CrapClean/releases/tag/v2.0) instead.

### Download
- `CrapClean.bat` - the original file, exactly as first published

### Known issues in this version
- Deletes the temp **folders**, not just their contents (`rd /s/q %TEMP%`)
- Wipes `C:\Windows\Prefetch`, which slows program launches for days afterwards
- Six lines call `deltree`, a command that has not existed since Windows XP, so they do
  nothing
- No preview, no log, no confirmation, no administrator check

All of the above are fixed in 2.0. See [CHANGELOG.md](CHANGELOG.md).
```

---

## Release 2.0 - tag `v2.0` - target commit: the new `main` HEAD

**Title:** CrapClean 2.0 - a window, safe paths, preview and logs

**Body:**

```markdown
CrapClean now opens a window. Tick the categories you want cleaned, press Clean, and it
tells you what it did. Nothing is deleted until you press the button.

Built for people who do not want to touch a command line: download the zip, extract,
double-click. No install, no settings, no account.

### Download
- **`CrapClean-2.0.zip`** - recommended. Extract it, then run `CrapClean.bat`
- `CrapClean.bat` + `CrapClean.ps1` - the same two files, individually

> Windows SmartScreen may warn on first run because the script is not code-signed.
> Click *More info -> Run anyway*. The source is in this repo if you want to read it first.

### What is new
- Point-and-click window with risk labels (Safe / Moderate / Advanced) on every category
- **Select recommended** - the safe set only, risky items stay unticked
- **Preview only** - shows what would be deleted and deletes nothing
- **Estimate space** - size of each ticked category before you commit
- Confirmation dialog that names every category
- Optional restore point, and a clear message if Windows refuses to make one
- Log file per run in `%LOCALAPPDATA%\CrapClean\logs`
- Administrator detection: the launcher asks for rights, and tells you which categories
  were skipped if you decline
- Browser cache cleaning for Chrome, Edge and Firefox
- New categories: Windows.old, Delivery Optimization cache, error reports
- Command-line modes: `-DryRun` and `-Quick`

### What is fixed
- **Temp folders are emptied, not deleted** - 1.0 removed folders Windows expects to exist
- **Prefetch is no longer wiped by default** - it is now Advanced, off, and says why
- **`deltree` lines gone** - they did nothing on any modern Windows
- **Duplicate blocks removed** - 1.0 deleted the same temp paths three times
- **`cleanmgr /sagerun:1` removed** - it silently did nothing without `/sageset` first
- **Nothing fails silently** - locked files and skipped paths are logged

### Requires
Windows 10 or 11 (uses `Clear-RecycleBin`). Administrator rights recommended, not required.

### Safety
Full per-category explanation: [docs/SAFETY.md](docs/SAFETY.md).
It never touches documents, Desktop, Downloads, OneDrive, installed programs, bookmarks,
passwords, history, the registry or Windows system files.

**Full detail:** [CHANGELOG.md](CHANGELOG.md)
```

---

## Commands, if you want them

Run from a clone of the repo, after the files are committed:

```bash
# 1.0 points at the ORIGINAL commit, before the rewrite
git tag -a v1.0 cb1c42f -m "CrapClean 1.0 - original batch script"
git push origin v1.0

# 2.0 points at the new commit on main
git tag -a v2.0 -m "CrapClean 2.0 - window, safe paths, preview, logs"
git push origin v2.0

# releases (body from the blocks above)
gh release create v1.0 legacy/CrapClean-v1.bat \
  --title "CrapClean 1.0 - the original batch script" \
  --notes "Original batch script, kept unchanged. Not maintained - use 2.0."

gh release create v2.0 dist/CrapClean-2.0.zip \
  --title "CrapClean 2.0 - a window, safe paths, preview and logs" \
  --notes "A window, safe paths, preview and logs. See CHANGELOG.md."
```

The long bodies above are for pasting into the web UI; the commands use a one-line note.

Check the tag order: if 2.0 is created first, GitHub marks it "Latest" and keeps it, which
is what you want anyway. The order above just keeps the history readable.
