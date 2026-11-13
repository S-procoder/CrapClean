# Changelog

All notable changes to CrapClean. Versions follow the release tags on GitHub.

---

## [2.0] - 2026-11-13

The first release with a window. 1.0 is preserved unchanged at tag `v1.0`.

### Added
- **A point-and-click window** (`CrapClean.ps1` + `CrapClean.bat` launcher). Tick
  categories, press Clean. No terminal, no editing, no install.
- **Risk labels** per category - Safe / Moderate / Advanced - colour-coded in the list,
  with the reasoning printed in the log for every run.
- **"Select recommended"** button: picks the safe set, leaves everything risky unticked.
- **Preview only** checkbox: reports what would be deleted, deletes nothing.
- **"Estimate space"** button: fills in the size of each ticked category before you commit.
- **Log file** per run in `%LOCALAPPDATA%\CrapClean\logs`, plus a live log pane in the window.
- **Confirmation dialog** naming every category before anything is deleted.
- **Optional restore point** before cleaning, and a clear message when Windows refuses
  to make one.
- **Administrator detection** - the launcher requests elevation; if it is refused the tool
  still runs, skips protected categories, and says which ones.
- **Command-line modes**: `-DryRun` (report only), `-Quick` (recommended set, one prompt).
- **Browser cache cleaning** for Chrome, Edge and Firefox, with a note about closing them.
- **Windows.old** and **Delivery Optimization cache** as new categories.

### Fixed
- **Temp folders are no longer deleted, only emptied.** 1.0 ran `rd /s/q %TEMP%` and
  `rd /s/q C:\Windows\Temp`, removing folders Windows expects to exist. Version 2 removes
  the contents and leaves the folder in place.
- **Prefetch is no longer deleted by default.** 1.0 wiped it, which slows program launches
  for days afterwards. It is now Advanced, off by default, with that explanation attached.
- **`deltree` lines removed.** `deltree` has not shipped since Windows XP, so those six
  lines in 1.0 did nothing on any supported Windows.
- **Duplicate blocks removed.** 1.0 deleted the same temp paths three times in a row.
- **`cleanmgr /sagerun:1` removed.** It only works after `/sageset` has been configured,
  so on a fresh machine it silently did nothing.
- **No more silent failure.** Every skipped path and locked file is written to the log.

### Known limits
- Recycle Bin size is reported as an item count, not bytes - the shell does not expose it
  cheaply.
- Thumbnail and icon caches are held by Explorer while it runs; some files will always be
  skipped unless Explorer is restarted.
- `Windows.old` is sometimes protected by ACLs and needs Disk Cleanup instead; the tool
  says so rather than failing quietly.
- Not code-signed, so SmartScreen warns on first run. Documented in the README.

---

## [1.0] - 2025

- Original single-file batch script: user temp, Windows temp, Prefetch, Recent items,
  `cleanmgr`, then `pause`.
- Preserved byte-for-byte at tag `v1.0` and in `legacy/CrapClean-v1.bat`. Not maintained.

---

## [2.1] - planned

- Signed release so SmartScreen stops warning.
- Per-category "what this means" panel in the window instead of only the log.
- Scheduled weekly clean as an opt-in Task Scheduler entry.
- Storage Sense hand-off for people who would rather Windows did it.
