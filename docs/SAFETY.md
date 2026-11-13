# Safety notes, category by category

Every line here describes what CrapClean 2.0 does to a specific folder. Read the row for
anything you plan to tick. If a folder is not on this page, CrapClean does not touch it.

The short version: **it deletes caches, never documents.** The one category that removes
something you chose to keep is the Recycle Bin, and that is what the category is for.

---

## How deletion works in this tool

For every folder category, CrapClean removes what is **inside** the folder and leaves the
folder itself in place. That distinction is the main bug fix over 1.0:

```text
1.0   rd /s/q C:\Windows\Temp      -> the folder is gone; Windows expects it to exist
2.0   delete C:\Windows\Temp\*     -> contents gone, folder still there
```

Files that are open in a program cannot be deleted by anything. CrapClean skips them,
counts them as skipped, and writes the path to the log. It never force-closes a program
to win an argument with a file lock.

---

## Safe categories

### User temp files - `%TEMP%`
Where installers unpack themselves and where many programs put scratch files. Windows
empties it on its own eventually; this just does it now. Apps may hold a file open - those
are skipped. **Nothing of yours lives here.**

### Windows temp files - `C:\Windows\Temp`
The same idea, for Windows components. Needs administrator rights. Occasionally an
installer mid-flight has files here, so avoid cleaning while something is installing.

### Recycle Bin
Emptying it is permanent. This is the only category where data you deliberately kept
disappears, and it is the only one where the confirmation box earns its place. Size shows
as an item count, because Windows does not expose the byte total cheaply.

### Thumbnail and icon cache - `%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db`
Small preview images Explorer caches so folders open faster. Windows rebuilds them on
demand; folders look briefly bare while they regenerate. Some files are locked by Explorer
itself and will be skipped - that is expected, not a failure.

### Error report files - `C:\ProgramData\Microsoft\Windows\WER`
Crash dumps and diagnostic bundles Windows collected. Only useful if you are actively
debugging a crash. Removing them frees real space on a machine that has been crashing.

### Delivery Optimization cache
Copies of update files Windows keeps to share with other PCs on your network. Windows
re-downloads what it needs. Safe on a single PC; on a metered connection, re-downloading
costs data.

---

## Moderate categories

### Browser caches - Chrome, Edge, Firefox
Removes cached pages, images and scripts. **Bookmarks, passwords, autofill, history and
open tabs are not touched** - those live in different files.

Close the browser first. While it runs, its cache files are locked and most of them will
be skipped. Expect sites to load slightly slower for a day while caches refill.

### Windows Update download cache - `C:\Windows\SoftwareDistribution\Download`
Installer files for updates that are already installed. Off by default, because a pending
update interrupted mid-download simply starts again. If Windows Update is misbehaving,
clearing this is a standard first step - but that is troubleshooting, not routine cleaning.

### Recent files list - `%APPDATA%\Microsoft\Windows\Recent`
Shortcuts to files you opened, shown in Explorer's Recent and in jump lists. A privacy
clean, not a space clean - it frees almost nothing. **The files themselves are untouched**;
only the shortcuts disappear.

---

## Advanced categories (off by default, on purpose)

### Windows.old - `%SystemDrive%\Windows.old`
Your previous Windows installation, kept for about ten days after a version upgrade so you
can roll back. It can be 10-30 GB, which makes it tempting.

After deleting it, **rolling back the upgrade is no longer possible.** Windows also
protects parts of this folder with permissions, so removal sometimes fails; when it does,
CrapClean tells you to use Disk Cleanup (*"Clean up system files" -> Previous Windows
installation*), which is Microsoft's supported route. Use that first.

### Prefetch cache - `C:\Windows\Prefetch`
Hints Windows uses to launch frequently used programs faster. **CrapClean 1.0 deleted this
on every run, and that was a mistake** - the next several launches of every app are slower
while the hints rebuild. It frees very little.

It is here because sometimes you genuinely want it: after swapping a drive, after malware
removal, or when chasing a startup problem. Not as routine cleaning.

---

## What CrapClean never touches

| Never | Why it matters |
| --- | --- |
| Documents, Desktop, Downloads, Pictures, Videos | Your files |
| OneDrive, Google Drive, Dropbox folders | Your files, and sync conflicts |
| Installed programs and their settings | Would break apps |
| Browser bookmarks, passwords, history, cookies | Would log you out and lose saved data |
| Windows system files (`C:\Windows\System32`, WinSxS) | Would break Windows |
| Registry | Too easy to break, too little space gained |
| Restore points, backups | Your safety net |
| Anything outside the paths listed above | By design |

---

## How to verify this yourself

You do not have to trust this page. Three ways to check before you run anything:

1. **Read the paths.** The category table is defined once, near the top of
   `CrapClean.ps1`, as `$script:Items`. Every path the tool can delete is listed there.
2. **Preview.** Tick everything, tick *Preview only*, press Clean. It prints each path and
   how much it would free, and deletes nothing.
3. **Read the log afterwards.** Every path touched, every file skipped, in
   `%LOCALAPPDATA%\CrapClean\logs`.
