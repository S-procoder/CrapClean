# CrapClean

**A one-window Windows cleanup tool. Tick boxes, press Clean, get space back.**

No installing, no command line, no settings to learn. It opens a window, shows you
exactly what each option deletes, and deletes nothing until you press the button.

Made for beginners on purpose. If a choice could hurt your PC, it is either off by
default or labelled so you can see why.

---

## Download and run (3 steps)

1. Go to **[Releases](https://github.com/S-procoder/CrapClean/releases)** and download
   `CrapClean-2.0.zip` from the latest release.
2. Right-click the downloaded zip -> **Extract All** -> Extract.
   Do not run it from inside the zip; Windows won't find the second file.
3. Open the extracted folder and double-click **`CrapClean.bat`**.
   Windows asks *"Do you want to allow this app to make changes?"* -> **Yes**.
   The window opens.

Tick what you want gone, or press **Select recommended**, then **Clean selected**.

> **Windows may warn you** with *"Windows protected your PC"* (SmartScreen). That is
> what it says about any small tool from a developer it has never seen. Click
> **More info -> Run anyway**. The full source is in this repo - read it before you run
> it, which is the honest reason to keep it visible.

---

## What the window shows you

| Category | What it removes | Risk |
| --- | --- | --- |
| User temp files | Leftover files apps wrote and forgot | Safe |
| Windows temp files | The same, in the Windows folder | Safe |
| Recycle Bin | Everything you already threw away | Safe |
| Thumbnail and icon cache | Explorer's preview images; Windows rebuilds them | Safe |
| Error report files | Crash dumps Windows saved | Safe |
| Delivery Optimization cache | Copies of updates shared between PCs | Safe |
| Browser caches | Cached pages and images from Chrome / Edge / Firefox | Moderate |
| Windows Update download cache | Installer files for updates already installed | Moderate |
| Recent files list | Shortcuts to files you opened (privacy, not space) | Moderate |
| Windows.old | Your previous Windows install after an upgrade | Advanced |
| Prefetch cache | Hints Windows uses to launch programs faster | Advanced |

"Safe" means Windows recreates it automatically and nothing of yours is lost.
"Moderate" means you lose a convenience, not a file. "Advanced" is off by default and
says why in the log.

### It never touches

Your documents, photos, downloads, Desktop, OneDrive, installed programs, browser
bookmarks, saved passwords, history, or Windows itself. Every category is a cache or a
throwaway folder, and each one is named in the table above.

---

## Is it actually safe? What changed from 1.0

CrapClean 1.0 was a batch file I wrote early on. It worked, but it had three real bugs,
and this version exists to fix them:

1. **It deleted the temp folders themselves** (`rd /s/q %TEMP%`), not just their
   contents. Windows and some installers expect `C:\Windows\Temp` to exist. Version 2
   deletes what is *inside* and leaves the folder standing.
2. **It wiped the Prefetch folder.** Prefetch is what makes programs open faster. Deleting
   it makes your next several launches slower, not faster. It is still available here,
   labelled Advanced and off by default, with that sentence in the log.
3. **It used `deltree`**, a DOS command that has not existed since Windows XP. Those
   lines silently did nothing on any modern PC.

Version 2 also adds what 1.0 had none of: a preview mode, a log file, a confirmation
before deleting, an optional restore point, and administrator detection so you know
when a category was skipped for lack of rights.

Full detail, category by category: **[docs/SAFETY.md](docs/SAFETY.md)**.

---

## Versions

| Release | What it is | Where |
| --- | --- | --- |
| **1.0** | The original batch file. Kept exactly as it was, for anyone who wants it. | [tag `v1.0`](https://github.com/S-procoder/CrapClean/tree/v1.0) / `legacy/CrapClean-v1.bat` |
| **2.0** | The window, the safe paths, preview, logging, restore point. | Latest release |

---

## For people who like the command line

```powershell
# see what would be deleted, delete nothing
.\CrapClean.ps1 -DryRun

# clean the recommended set with one Yes/No prompt
.\CrapClean.ps1 -Quick

# the normal window
.\CrapClean.ps1
```

Logs land in `%LOCALAPPDATA%\CrapClean\logs`.

---

## Questions people actually ask

**Do I need to install anything?**
No. Two files, one folder, double-click. PowerShell is already part of Windows.

**Which Windows?**
Windows 10 and 11. It uses `Clear-RecycleBin`, which 8.1 and older do not have.

**Will it delete my files?**
Only the caches listed in the table. The Recycle Bin is the one exception, and it is
the whole point of that row - the confirmation box warns you.

**Why does it ask for administrator rights?**
`C:\Windows\Temp`, the update cache and `Windows.old` sit in protected folders. Without
rights the tool still opens and does everything else; those rows get skipped and the log
says so.

**It said some files were skipped. Is that bad?**
No. A file in use (a browser cache while the browser is open, a thumbnail Explorer is
holding) cannot be deleted. Close the program and run it again.

**Can I undo it?**
Not the deletions - that is why **Preview only** and **Create restore point first** exist.
A restore point helps with settings, not with deleted cache files, so preview first if
you are unsure.

---

## License

MIT License with Commons Clause - use it, change it, share it, don't sell it.
See [LICENSE.md](LICENSE.md).

Copyright (c) 2025 Siddhant Neekhra.
