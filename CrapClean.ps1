<#
.SYNOPSIS
    CrapClean 2.0 - safe, beginner-friendly Windows cleanup with a point-and-click window.

.DESCRIPTION
    Double-click CrapClean.bat. Tick what you want gone, press Clean.
    Nothing is deleted until you press the button. Tick "Preview only" to see
    what would be removed without removing anything.

    Run from the launcher (CrapClean.bat) - it asks for administrator rights,
    which some folders need. Without admin the tool still opens, but Windows
    temp, update cache and Windows.old will be skipped.

.PARAMETER DryRun
    No window. Report what would be deleted, delete nothing.

.PARAMETER Quick
    No window. Clean the recommended set immediately, after a Yes/No prompt.

.NOTES
    CrapClean 2.0 - part of the CrapClean project.
    MIT License with Commons Clause. Copyright (c) 2025 Siddhant Neekhra.
    Logs are written to %LOCALAPPDATA%\CrapClean\logs
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Quick
)

$ErrorActionPreference = 'Continue'
$script:AppName    = 'CrapClean'
$script:AppVersion = '2.0'
$script:LogPath    = $null

# ---------------------------------------------------------------------------
# What we clean, and how risky it is.
#
#   Kind = Contents    -> delete everything INSIDE the folder, keep the folder
#   Kind = RecycleBin  -> empty the recycle bin
#   Kind = FolderWhole -> delete the folder itself (only used for Windows.old)
#
# Recommended = $true means "Select recommended" ticks it.
# Nothing with Risk = Advanced is ever ticked automatically.
# ---------------------------------------------------------------------------
$script:Items = @(
    [pscustomobject]@{
        Id='user-temp'; Name='User temp files'; Risk='Safe'; Recommended=$true
        What='Leftover files that apps wrote and forgot to delete'
        Kind='Contents'; Paths=@('%TEMP%')
        Note='Apps may have a file open here; those are skipped, not forced.'
    }
    [pscustomobject]@{
        Id='win-temp'; Name='Windows temp files'; Risk='Safe'; Recommended=$true
        What='The same thing, but in the Windows folder'
        Kind='Contents'; Paths=@('%SystemRoot%\Temp')
        Note='Needs administrator rights.'
    }
    [pscustomobject]@{
        Id='recycle-bin'; Name='Recycle Bin'; Risk='Safe'; Recommended=$true
        What='Everything you have already thrown away'
        Kind='RecycleBin'; Paths=@()
        Note='This is permanent - there is no undo after it runs.'
    }
    [pscustomobject]@{
        Id='thumbs'; Name='Thumbnail and icon cache'; Risk='Safe'; Recommended=$true
        What='The small preview images Explorer keeps for speed'
        Kind='Files'; Paths=@('%LOCALAPPDATA%\Microsoft\Windows\Explorer'); Patterns=@('thumbcache_*.db','iconcache_*.db')
        Note='Windows rebuilds these. Some are locked while Explorer runs and get skipped.'
    }
    [pscustomobject]@{
        Id='wer'; Name='Error report files'; Risk='Safe'; Recommended=$true
        What='Crash dumps Windows saved for programs that failed'
        Kind='Contents'; Paths=@('C:\ProgramData\Microsoft\Windows\WER\ReportQueue','C:\ProgramData\Microsoft\Windows\WER\ReportArchive','%LOCALAPPDATA%\Microsoft\Windows\WER')
        Note=''
    }
    [pscustomobject]@{
        Id='do-cache'; Name='Delivery Optimization cache'; Risk='Safe'; Recommended=$true
        What='Copies of Windows updates shared between PCs on your network'
        Kind='Contents'; Paths=@('C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache')
        Note='Windows re-downloads if it needs them again.'
    }
    [pscustomobject]@{
        Id='browser-cache'; Name='Browser caches (Chrome, Edge, Firefox)'; Risk='Moderate'; Recommended=$true
        What='Cached web pages and images. Bookmarks, passwords and history are NOT touched'
        Kind='Contents'; Paths=@('%LOCALAPPDATA%\Google\Chrome\User Data\*\Cache','%LOCALAPPDATA%\Microsoft\Edge\User Data\*\Cache','%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\cache2')
        Note='Close your browsers first, or their cache files stay locked and get skipped. Sites load slower once afterwards.'
    }
    [pscustomobject]@{
        Id='wu-cache'; Name='Windows Update download cache'; Risk='Moderate'; Recommended=$false
        What='Installer files for updates that are already installed'
        Kind='Contents'; Paths=@('%SystemRoot%\SoftwareDistribution\Download')
        Note='Safe in normal use. Windows re-downloads anything it still needs.'
    }
    [pscustomobject]@{
        Id='recent'; Name='Recent files list'; Risk='Moderate'; Recommended=$false
        What='Shortcuts to files you opened, shown in Explorer and jump lists'
        Kind='Contents'; Paths=@('%APPDATA%\Microsoft\Windows\Recent')
        Note='A privacy clean, not a space clean. Your actual files are untouched.'
    }
    [pscustomobject]@{
        Id='win-old'; Name='Windows.old (previous Windows install)'; Risk='Advanced'; Recommended=$false
        What='Your old Windows folder, kept after a version upgrade'
        Kind='FolderWhole'; Paths=@('%SystemDrive%\Windows.old')
        Note='Can be many GB. After this you cannot roll back the upgrade. Windows may refuse to delete it - Disk Cleanup is the official route.'
    }
    [pscustomobject]@{
        Id='prefetch'; Name='Prefetch cache'; Risk='Advanced'; Recommended=$false
        What='Hints Windows uses to start programs faster'
        Kind='Contents'; Paths=@('%SystemRoot%\Prefetch')
        Note='Off on purpose. CrapClean 1.0 deleted this and it makes your next few launches slower. Only clear it if you are troubleshooting.'
    }
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
function Initialize-Log {
    $dir = Join-Path $env:LOCALAPPDATA 'CrapClean\logs'
    try {
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $script:LogPath = Join-Path $dir ("crapclean-$stamp.log")
        Add-Content -LiteralPath $script:LogPath -Value ("$($script:AppName) $($script:AppVersion) - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        Add-Content -LiteralPath $script:LogPath -Value ("Computer: $env:COMPUTERNAME   User: $env:USERNAME")
        Add-Content -LiteralPath $script:LogPath -Value ('-' * 70)
    } catch {
        $script:LogPath = $null
    }
}

function Write-Log {
    param([string]$Message, [string]$Color = 'Gray')
    if ($script:LogPath) {
        try { Add-Content -LiteralPath $script:LogPath -Value $Message } catch { }
    }
    if ($script:LogBox -and -not $script:LogBox.IsDisposed) {
        $script:LogBox.SelectionColor = [System.Drawing.Color]::FromName($Color)
        $script:LogBox.AppendText($Message + "`r`n")
        $script:LogBox.SelectionStart = $script:LogBox.TextLength
        $script:LogBox.ScrollToCaret()
    }
    if ($script:StatusLabel -and -not $script:StatusLabel.IsDisposed) {
        $script:StatusLabel.Text = $Message
        $script:StatusLabel.Refresh()
    }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Test-Admin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $pr = [Security.Principal.WindowsPrincipal]::new($id)
        return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Resolve-Target {
    param([string]$RawPath)
    $expanded = [Environment]::ExpandEnvironmentVariables($RawPath)
    if ($expanded -match '[\*\?]') {
        return @(Get-Item -Path $expanded -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }
    if (Test-Path -LiteralPath $expanded) { return @($expanded) }
    return @()
}

function Get-TargetInfo {
    param($Item)
    $bytes = 0; $files = 0
    if ($Item.Kind -eq 'RecycleBin') {
        try {
            $rb = (New-Object -ComObject Shell.Application).NameSpace(10)
            $count = $rb.Items().Count
            return [pscustomobject]@{ Bytes = 0; Files = $count; Found = ($count -gt 0) }
        } catch { return [pscustomobject]@{ Bytes = 0; Files = 0; Found = $false } }
    }
    foreach ($raw in $Item.Paths) {
        foreach ($p in (Resolve-Target -RawPath $raw)) {
            if (-not (Test-Path -LiteralPath $p)) { continue }
            if ($Item.Kind -eq 'Files') {
                foreach ($pat in $Item.Patterns) {
                    $found = @(Get-ChildItem -LiteralPath $p -Filter $pat -Force -File -ErrorAction SilentlyContinue)
                    $files += $found.Count
                    $bytes += ($found | Measure-Object -Property Length -Sum).Sum
                }
            } else {
                $found = @(Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue)
                $files += $found.Count
                $bytes += ($found | Measure-Object -Property Length -Sum).Sum
            }
        }
    }
    if ($null -eq $bytes) { $bytes = 0 }
    return [pscustomobject]@{ Bytes = [int64]$bytes; Files = [int]$files; Found = ($files -gt 0) }
}

function Format-Size {
    param([double]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N0} KB' -f ($Bytes / 1KB)) }
    return ('{0:N0} B' -f $Bytes)
}

# ---------------------------------------------------------------------------
# The cleaning itself
# ---------------------------------------------------------------------------
function Invoke-Clean {
    param([object[]]$Selected, [switch]$Preview)

    $totalBytes = 0; $totalFiles = 0; $skipped = 0
    Write-Log ''
    Write-Log ("Cleaning {0} categor{1}{2}" -f $Selected.Count, $(if ($Selected.Count -eq 1) { 'y' } else { 'ies' }), $(if ($Preview) { ' - PREVIEW ONLY, nothing will be deleted' } else { '' })) 'Cyan'
    Write-Log ('-' * 70)

    foreach ($item in $Selected) {
        Write-Log ''
        Write-Log ("[ ] " + $item.Name) 'White'

        if ($item.Kind -eq 'RecycleBin') {
            if ($Preview) {
                $info = Get-TargetInfo -Item $item
                Write-Log ("    would empty the Recycle Bin ({0} item(s))" -f $info.Files) 'DarkGray'
                $totalFiles += $info.Files
            } else {
                try {
                    Clear-RecycleBin -Force -ErrorAction Stop
                    Write-Log '    Recycle Bin emptied' 'Green'
                } catch {
                    Write-Log ('    could not empty the Recycle Bin: ' + $_.Exception.Message) 'DarkYellow'
                    $skipped++
                }
            }
            continue
        }

        foreach ($raw in $item.Paths) {
            $targets = Resolve-Target -RawPath $raw
            if ($targets.Count -eq 0) {
                Write-Log ('    not present, skipping: ' + [Environment]::ExpandEnvironmentVariables($raw)) 'DarkGray'
                continue
            }
            foreach ($p in $targets) {
                if (-not (Test-Path -LiteralPath $p)) { continue }

                if ($item.Kind -eq 'Files') {
                    foreach ($pat in $item.Patterns) {
                        $found = @(Get-ChildItem -LiteralPath $p -Filter $pat -Force -File -ErrorAction SilentlyContinue)
                        $sum = [int64](($found | Measure-Object -Property Length -Sum).Sum)
                        if ($null -eq $sum) { $sum = 0 }
                        $totalBytes += $sum; $totalFiles += $found.Count
                        if ($Preview) {
                            Write-Log ("    would delete {0} file(s), {1} - {2}" -f $found.Count, (Format-Size $sum), $p) 'DarkGray'
                        } else {
                            $found | Remove-Item -Force -ErrorAction SilentlyContinue
                            Write-Log ("    deleted {0} file(s), {1} - {2}" -f $found.Count, (Format-Size $sum), $p) 'Green'
                        }
                    }
                }
                elseif ($item.Kind -eq 'FolderWhole') {
                    $found = @(Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue)
                    $sum = [int64](($found | Measure-Object -Property Length -Sum).Sum)
                    if ($null -eq $sum) { $sum = 0 }
                    $totalBytes += $sum; $totalFiles += $found.Count
                    if ($Preview) {
                        Write-Log ("    would delete the whole folder, {0} - {1}" -f (Format-Size $sum), $p) 'DarkGray'
                    } else {
                        try {
                            Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
                            Write-Log ("    removed {0} - {1}" -f (Format-Size $sum), $p) 'Green'
                        } catch {
                            Write-Log ('    could not remove ' + $p + ' - try Disk Cleanup instead') 'DarkYellow'
                            $skipped++
                        }
                    }
                }
                else {
                    $children = @(Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue)
                    $found = @(Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue)
                    $sum = [int64](($found | Measure-Object -Property Length -Sum).Sum)
                    if ($null -eq $sum) { $sum = 0 }
                    $totalBytes += $sum; $totalFiles += $found.Count
                    if ($Preview) {
                        Write-Log ("    would delete {0} item(s), {1} - {2}" -f $children.Count, (Format-Size $sum), $p) 'DarkGray'
                    } else {
                        $children | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Log ("    cleared {0} item(s), {1} - {2}" -f $children.Count, (Format-Size $sum), $p) 'Green'
                    }
                }
            }
        }

        if ($item.Note) { Write-Log ('    note: ' + $item.Note) 'DarkGray' }
    }

    Write-Log ''
    Write-Log ('-' * 70)
    if ($Preview) {
        Write-Log ("PREVIEW: would free about {0} across {1} file(s). Nothing was deleted." -f (Format-Size $totalBytes), $totalFiles) 'Cyan'
    } else {
        Write-Log ("Done. Freed about {0} across {1} file(s)." -f (Format-Size $totalBytes), $totalFiles) 'Green'
    }
    if ($skipped -gt 0) {
        Write-Log ("{0} categor(y/ies) could not be fully cleaned - usually a file in use, or missing administrator rights." -f $skipped) 'DarkYellow'
    }
    if ($script:LogPath) { Write-Log ('Log saved to: ' + $script:LogPath) 'DarkGray' }

    return [pscustomobject]@{ Bytes = $totalBytes; Files = $totalFiles; Skipped = $skipped }
}

# ---------------------------------------------------------------------------
# Console modes (no window)
# ---------------------------------------------------------------------------
function Invoke-QuickMode {
    param([switch]$Preview)
    $set = @($script:Items | Where-Object { $_.Recommended })
    Write-Host ''
    Write-Host ("  $($script:AppName) $($script:AppVersion) - quick clean") -ForegroundColor Cyan
    Write-Host '  These will be cleaned:' -ForegroundColor Gray
    foreach ($i in $set) { Write-Host ("    - " + $i.Name) -ForegroundColor Gray }
    Write-Host ''
    if ($Preview) {
        Write-Host '  Preview mode: nothing will be deleted.' -ForegroundColor Yellow
    } else {
        $answer = Read-Host '  Type YES to continue'
        if ($answer -ne 'YES') { Write-Host '  Cancelled. Nothing was deleted.' -ForegroundColor Yellow; return }
    }
    Invoke-Clean -Selected $set -Preview:$Preview | Out-Null
    if (-not $Preview) { Write-Host ''; Read-Host '  Press Enter to close' | Out-Null }
}

# ---------------------------------------------------------------------------
# Window
# ---------------------------------------------------------------------------
function Show-Window {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $script:LogBox      = $null
    $script:StatusLabel = $null

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$($script:AppName) $($script:AppVersion)"
    $form.Size = [System.Drawing.Size]::new(880, 720)
    $form.MinimumSize = [System.Drawing.Size]::new(720, 560)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = [System.Drawing.Color]::FromArgb(246, 248, 245)
    $form.Font = [System.Drawing.Font]::new('Segoe UI', 9)

    # header
    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = 'Top'
    $header.Height = 78
    $header.BackColor = [System.Drawing.Color]::FromArgb(11, 38, 28)
    $form.Controls.Add($header)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $script:AppName
    $title.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 20)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(120, 235, 150)
    $title.AutoSize = $true
    $title.Location = [System.Drawing.Point]::new(20, 12)
    $header.Controls.Add($title)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = "Free up space safely. Tick what to remove, press Clean. Nothing happens until you do."
    $sub.Font = [System.Drawing.Font]::new('Segoe UI', 9)
    $sub.ForeColor = [System.Drawing.Color]::FromArgb(190, 210, 198)
    $sub.AutoSize = $true
    $sub.Location = [System.Drawing.Point]::new(22, 48)
    $header.Controls.Add($sub)

    # item list
    $list = New-Object System.Windows.Forms.ListView
    $list.View = 'Details'
    $list.CheckBoxes = $true
    $list.FullRowSelect = $true
    $list.GridLines = $false
    $list.HideSelection = $false
    $list.Location = [System.Drawing.Point]::new(18, 92)
    $list.Size = [System.Drawing.Size]::new(828, 300)
    $list.Anchor = 'Top,Left,Right'
    $list.BackColor = [System.Drawing.Color]::White
    [void]$list.Columns.Add('Category', 250)
    [void]$list.Columns.Add('What it removes', 400)
    [void]$list.Columns.Add('Risk', 80)
    [void]$list.Columns.Add('Size', 80)
    $form.Controls.Add($list)

    $index = 0
    foreach ($item in $script:Items) {
        $row = [System.Windows.Forms.ListViewItem]::new($item.Name)
        [void]$row.SubItems.Add($item.What)
        [void]$row.SubItems.Add($item.Risk)
        [void]$row.SubItems.Add('-')
        $row.Tag = $item
        $row.Checked = $false
        if ($item.Risk -eq 'Safe')     { $row.ForeColor = [System.Drawing.Color]::FromArgb(20, 70, 45) }
        if ($item.Risk -eq 'Moderate') { $row.ForeColor = [System.Drawing.Color]::FromArgb(120, 80, 10) }
        if ($item.Risk -eq 'Advanced') { $row.ForeColor = [System.Drawing.Color]::FromArgb(130, 30, 30) }
        [void]$list.Items.Add($row)
        $index++
    }

    # buttons
    $btnY = 404
    $btnRecommended = New-Object System.Windows.Forms.Button
    $btnRecommended.Text = 'Select recommended'
    $btnRecommended.Location = [System.Drawing.Point]::new(18, $btnY)
    $btnRecommended.Size = [System.Drawing.Size]::new(150, 30)
    $form.Controls.Add($btnRecommended)

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text = 'Clear all'
    $btnClear.Location = [System.Drawing.Point]::new(176, $btnY)
    $btnClear.Size = [System.Drawing.Size]::new(90, 30)
    $form.Controls.Add($btnClear)

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Text = 'Estimate space'
    $btnScan.Location = [System.Drawing.Point]::new(274, $btnY)
    $btnScan.Size = [System.Drawing.Size]::new(130, 30)
    $form.Controls.Add($btnScan)

    $chkPreview = New-Object System.Windows.Forms.CheckBox
    $chkPreview.Text = 'Preview only (delete nothing)'
    $chkPreview.Location = [System.Drawing.Point]::new(420, $btnY + 5)
    $chkPreview.Size = [System.Drawing.Size]::new(200, 22)
    $form.Controls.Add($chkPreview)

    $chkRestore = New-Object System.Windows.Forms.CheckBox
    $chkRestore.Text = 'Create restore point first'
    $chkRestore.Location = [System.Drawing.Point]::new(624, $btnY + 5)
    $chkRestore.Size = [System.Drawing.Size]::new(200, 22)
    $chkRestore.Checked = $true
    $form.Controls.Add($chkRestore)

    $btnClean = New-Object System.Windows.Forms.Button
    $btnClean.Text = 'Clean selected'
    $btnClean.Location = [System.Drawing.Point]::new(18, $btnY + 40)
    $btnClean.Size = [System.Drawing.Size]::new(180, 38)
    $btnClean.BackColor = [System.Drawing.Color]::FromArgb(11, 38, 28)
    $btnClean.ForeColor = [System.Drawing.Color]::White
    $btnClean.FlatStyle = 'Flat'
    $btnClean.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 10)
    $form.Controls.Add($btnClean)

    $script:StatusLabel = New-Object System.Windows.Forms.Label
    $script:StatusLabel.Text = 'Ready. Tick the categories you want, or press "Select recommended".'
    $script:StatusLabel.Location = [System.Drawing.Point]::new(210, $btnY + 50)
    $script:StatusLabel.Size = [System.Drawing.Size]::new(636, 20)
    $script:StatusLabel.Anchor = 'Top,Left,Right'
    $script:StatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(70, 90, 80)
    $form.Controls.Add($script:StatusLabel)

    # log
    $script:LogBox = New-Object System.Windows.Forms.RichTextBox
    $script:LogBox.Location = [System.Drawing.Point]::new(18, $btnY + 88)
    $script:LogBox.Size = [System.Drawing.Size]::new(828, 220)
    $script:LogBox.Anchor = 'Top,Bottom,Left,Right'
    $script:LogBox.ReadOnly = $true
    $script:LogBox.BackColor = [System.Drawing.Color]::FromArgb(252, 253, 252)
    $script:LogBox.Font = [System.Drawing.Font]::new('Consolas', 9)
    $script:LogBox.BorderStyle = 'FixedSingle'
    $form.Controls.Add($script:LogBox)

    # ---- behaviour ----
    $selectRecommended = {
        foreach ($row in $list.Items) {
            $row.Checked = [bool]$row.Tag.Recommended
        }
    }
    $btnRecommended.Add_Click($selectRecommended)

    $btnClear.Add_Click({ foreach ($row in $list.Items) { $row.Checked = $false } })

    $btnScan.Add_Click({
        $chosen = @($list.CheckedItems | ForEach-Object { $_.Tag })
        if ($chosen.Count -eq 0) { [void][System.Windows.Forms.MessageBox]::Show('Tick at least one category first.', $script:AppName); return }
        $btnScan.Enabled = $false
        Write-Log 'Estimating sizes - this can take up to a minute on a full drive...' 'Cyan'
        $form.Refresh()
        foreach ($row in $list.CheckedItems) {
            $info = Get-TargetInfo -Item $row.Tag
            if ($info.Found) {
                $sizeText = Format-Size $info.Bytes
            } else {
                $sizeText = 'empty'
            }
            $row.SubItems[3].Text = $sizeText
        }
        Write-Log 'Estimate finished.' 'Green'
        $btnScan.Enabled = $true
    })

    $btnClean.Add_Click({
        $chosen = @($list.CheckedItems | ForEach-Object { $_.Tag })
        if ($chosen.Count -eq 0) { [void][System.Windows.Forms.MessageBox]::Show('Tick at least one category first, or press "Select recommended".', $script:AppName); return }
        $preview = $chkPreview.Checked
        $names = ($chosen | ForEach-Object { ' - ' + $_.Name }) -join "`r`n"
        if (-not $preview) {
            $msg = "These categories will be cleaned now:`r`n`r`n$names`r`n`r`nFiles are deleted permanently. Continue?"
            $answer = [System.Windows.Forms.MessageBox]::Show($msg, "$($script:AppName) - confirm", 'YesNo', 'Warning')
            if ($answer -ne 'Yes') { Write-Log 'Cancelled by user. Nothing was deleted.' 'DarkYellow'; return }
        }
        $btnClean.Enabled = $false
        $btnScan.Enabled = $false
        if ($chkRestore.Checked -and -not $preview) {
            Write-Log 'Creating a restore point (can take a minute)...' 'Cyan'
            $form.Refresh()
            try {
                Checkpoint-Computer -Description 'CrapClean before clean' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
                Write-Log 'Restore point created.' 'Green'
            } catch {
                Write-Log 'Could not create a restore point (System Restore may be off, or it was made in the last 24 hours). Continuing anyway.' 'DarkYellow'
            }
        }
        $result = Invoke-Clean -Selected $chosen -Preview:$preview
        $btnClean.Enabled = $true
        $btnScan.Enabled = $true
        if ($preview) {
            $headline = "Preview finished. About $(Format-Size $result.Bytes) would be freed."
        } else {
            $headline = "Done. About $(Format-Size $result.Bytes) freed."
        }
        [void][System.Windows.Forms.MessageBox]::Show($headline, $script:AppName)
    })

    Initialize-Log
    Write-Log ("$($script:AppName) $($script:AppVersion)") 'Cyan'
    if (Test-Admin) {
        Write-Log 'Running as administrator - all categories available.' 'Green'
    } else {
        Write-Log 'Running WITHOUT administrator rights. Windows temp, update cache and Windows.old will be skipped. Close this and run CrapClean.bat instead.' 'DarkYellow'
    }
    if ($script:LogPath) { Write-Log ('Log file: ' + $script:LogPath) 'DarkGray' }
    Write-Log 'Nothing is deleted until you press "Clean selected".' 'DarkGray'

    [void]$form.ShowDialog()
    $form.Dispose()
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
try {
    if ($DryRun) {
        Initialize-Log
        Invoke-Clean -Selected @($script:Items) -Preview | Out-Null
        exit 0
    }
    if ($Quick) {
        Initialize-Log
        Invoke-QuickMode
        exit 0
    }

    if (-not (Test-Admin)) {
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Path }
        if ($scriptPath) {
            try {
                Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
                    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $scriptPath + '"')
                ) -ErrorAction Stop
                exit 0
            } catch {
                # user declined the prompt - carry on unelevated rather than dying
            }
        }
    }
    Show-Window
} catch {
    Write-Host ''
    Write-Host ('CrapClean hit an unexpected error: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Nothing was deleted. Please report this with the log from %LOCALAPPDATA%\CrapClean\logs' -ForegroundColor Yellow
    Write-Host ''
    Read-Host 'Press Enter to close' | Out-Null
}
