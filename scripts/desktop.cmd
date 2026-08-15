<# : hybrid batch/powershell bootstrap
@echo off
setlocal
title RedSkia.dev Desktop Emulator
chcp 65001 >nul 2>&1
cls
color 0C

echo.
echo   =============================================================================
echo      ____           _ ____  _    _             ____             
echo     ^|  _ \ ___   __^| / ___^|^| ^| _(_) __ _      ^|  _ \  _____   __
echo     ^| ^|_) / _ \ / _` \___ \^| ^|/ / ^|/ _` ^|     ^| ^| ^| ^|/ _ \ \ / /
echo     ^|  _ ^<  __/^| (_^| ^|___) ^|   ^<^| ^| (_^| ^|  _  ^| ^|_^| ^|  __/\ V / 
echo     ^|_^| \_\___^| \__,_^|____/^|_^|\_\_^|\__,_^| (_) ^|____/ \___^| \_/  
echo.
echo                 [  R E D S K I A . D E V   E M U L A T O R  ]
echo   =============================================================================
echo.
echo   [*] Starting Desktop Engine, please wait...
echo.

set "DESKTOP_SCRIPT_DIR=%~dp0"
set "DESKTOP_CMD_PATH=%~f0"

powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -Command "$env:DESKTOP_SCRIPT_DIR='%~dp0'; $env:DESKTOP_CMD_PATH='%~f0'; Invoke-Expression ([System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8))"
exit /b
#>

# ============================================================
# 002 - DIAGNOSTIC LOGGING ENGINE & CRASH HANDLERS
# ============================================================

$script:scriptDir = if ($env:DESKTOP_SCRIPT_DIR -and (Test-Path -LiteralPath $env:DESKTOP_SCRIPT_DIR)) {
    $env:DESKTOP_SCRIPT_DIR.TrimEnd('\')
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
} else {
    [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
}

$script:logFile = Join-Path $script:scriptDir "desktop.log"
$script:logLock = New-Object object

function Write-DesktopLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [System.Exception]$Exception = $null
    )
    try {
        $timestamp = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss.fff")
        $logLine = "[$timestamp] [$Level] $Message"
        if ($null -ne $Exception) {
            $logLine += "`r`n  [EXCEPTION TYPE] " + $Exception.GetType().FullName
            $logLine += "`r`n  [EXCEPTION MSG]  " + $Exception.Message
            $logLine += "`r`n  [STACK TRACE]   " + $Exception.StackTrace
            if ($null -ne $Exception.InnerException) {
                $logLine += "`r`n  [INNER TYPE]    " + $Exception.InnerException.GetType().FullName
                $logLine += "`r`n  [INNER MSG]     " + $Exception.InnerException.Message
                $logLine += "`r`n  [INNER STACK]   " + $Exception.InnerException.StackTrace
            }
        }
        [System.Threading.Monitor]::Enter($script:logLock)
        try {
            [System.IO.File]::AppendAllText($script:logFile, "$logLine`r`n", [System.Text.Encoding]::UTF8)
        } finally {
            [System.Threading.Monitor]::Exit($script:logLock)
        }
    } catch { }
}

function Write-ConsoleStatus([string]$Text, [string]$Color = "White") {
    try {
        if ([System.Console]::CursorLeft -ge 0) {
            $prevColor = [System.Console]::ForegroundColor
            try {
                if ($Color -eq "Yellow") { [System.Console]::ForegroundColor = [System.ConsoleColor]::Yellow }
                elseif ($Color -eq "Green") { [System.Console]::ForegroundColor = [System.ConsoleColor]::Green }
                elseif ($Color -eq "Cyan") { [System.Console]::ForegroundColor = [System.ConsoleColor]::Cyan }
                elseif ($Color -eq "Red") { [System.Console]::ForegroundColor = [System.ConsoleColor]::Red }
                elseif ($Color -eq "DarkRed") { [System.Console]::ForegroundColor = [System.ConsoleColor]::DarkRed }
                elseif ($Color -eq "DarkGreen") { [System.Console]::ForegroundColor = [System.ConsoleColor]::DarkGreen }
                elseif ($Color -eq "Gray") { [System.Console]::ForegroundColor = [System.ConsoleColor]::Gray }
                elseif ($Color -eq "DarkGray") { [System.Console]::ForegroundColor = [System.ConsoleColor]::DarkGray }
                [System.Console]::WriteLine($Text)
            } finally {
                [System.Console]::ForegroundColor = $prevColor
            }
            return
        }
    } catch { }
    try { [System.Console]::WriteLine($Text) } catch { }
}

# Fresh log initialization on every startup (resets previous log file)
try {
    $logHeader = "============================================================`r`n" +
                 " RedSkia.Dev Desktop Emulator - Complete Debug Log`r`n" +
                 " Started: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss.fff'))`r`n" +
                 " Process ID: $([System.Diagnostics.Process]::GetCurrentProcess().Id)`r`n" +
                 " OS Version: $([Environment]::OSVersion.VersionString)`r`n" +
                 " CLR Version: $([Environment]::Version)`r`n" +
                 " Script Directory: $script:scriptDir`r`n" +
                 " Log File: $script:logFile`r`n" +
                 "============================================================`r`n"
    [System.IO.File]::WriteAllText($script:logFile, $logHeader, [System.Text.Encoding]::UTF8)
    Write-DesktopLog "Logging engine initialized successfully."
} catch { }

# Global Crash / Unhandled Exception Handlers
try {
    [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
    
    [System.Windows.Forms.Application]::add_ThreadException({
        param($sender, $e)
        try {
            Write-DesktopLog "UNHANDLED THREAD EXCEPTION CAUGHT" -Level "CRASH" -Exception $e.Exception
        } catch { }
    })

    [System.AppDomain]::CurrentDomain.add_UnhandledException({
        param($sender, $e)
        try {
            $ex = $e.ExceptionObject -as [System.Exception]
            Write-DesktopLog "APPDOMAIN UNHANDLED EXCEPTION (IsTerminating: $($e.IsTerminating))" -Level "CRASH" -Exception $ex
        } catch { }
    })
} catch { }

# ============================================================
# 003 - ASSEMBLIES & VISUAL STYLES
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName WindowsFormsIntegration

[System.Windows.Forms.Application]::EnableVisualStyles()
Write-DesktopLog "Visual styles and core WinForms assemblies loaded."

# ============================================================
# 004 - SETTINGS DIRECTORY & PERSISTENCE
# ============================================================

$settingsDirectory = Join-Path $env:LOCALAPPDATA "EmulatedDesktop"
$settingsFile = Join-Path $settingsDirectory "settings.json"

if (-not (Test-Path -LiteralPath $settingsDirectory)) {
    New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
}

function Get-DefaultSettings {
    return [ordered]@{
        BackgroundType   = "Brand"
        BackgroundColor  = "#040306"
        ImagePath        = ""
        ImageMode        = "Fill"
        WallpaperDimming = 0
        IconScale        = 72
        UiScale          = 1.0
        SortBy           = "Name"
        AutoArrange      = $false
        AlignToGrid      = $false
        ShowDesktopIcons = $true
        ShowRecycleBin   = $true
        DesktopPath      = Join-Path $env:USERPROFILE "Desktop"
        BossKeyEnabled   = $true
        BossKeyName             = "F12"
        BossKeyVk               = 123 # VK_F12
        BossKeyCtrl             = $false
        BossKeyAlt              = $false
        BossKeyShift            = $false
        BossKeyWin              = $false
        BossHideTaskbar         = $true
        BossMuteAudio           = $true
        BossDecoyMode           = "WindowsUpdate"
        BossDecoyEnabled        = $true
        BossDecoyPreset         = "Windows 11 Update Screen (Fake Stealth Screen)"
        BossDecoyPath           = "FakeWindowsUpdate"
        BossDecoyPrewarm        = $true
        BossDecoyCloseOnRestore = $true
        ConfirmExit             = $true
        ShowWidgets             = $true
        WidgetPosition          = "TopRight"
        ShowWidgetClock         = $true
        ShowWidgetSystem        = $true
        ShowWidgetStorage       = $true
        Positions               = @{}
    }
}

$settings = Get-DefaultSettings

# ============================================================
# 004 - LOAD SETTINGS
# ============================================================

if (Test-Path -LiteralPath $settingsFile) {
    try {
        $loaded = Get-Content -LiteralPath $settingsFile -Raw -ErrorAction Stop | ConvertFrom-Json
        if ($null -ne $loaded) {
            if ($null -ne $loaded.BackgroundType) { $settings.BackgroundType = [string]$loaded.BackgroundType }
            if ($null -ne $loaded.BackgroundColor) { $settings.BackgroundColor = [string]$loaded.BackgroundColor }
            if ($null -ne $loaded.ImagePath) { $settings.ImagePath = [string]$loaded.ImagePath }
            if ($null -ne $loaded.ImageMode) { $settings.ImageMode = [string]$loaded.ImageMode }
            if ($null -ne $loaded.WallpaperDimming) {
                try { $settings.WallpaperDimming = [int]$loaded.WallpaperDimming } catch { $settings.WallpaperDimming = 0 }
            }
            if ($null -ne $loaded.IconScale) {
                try { $settings.IconScale = [int]$loaded.IconScale } catch { $settings.IconScale = 72 }
            }
            if ($null -ne $loaded.UiScale) {
                try { $settings.UiScale = [double]$loaded.UiScale } catch { $settings.UiScale = 1.0 }
            }
            if ($null -ne $loaded.SortBy) { $settings.SortBy = [string]$loaded.SortBy }
            if ($null -ne $loaded.AutoArrange) { $settings.AutoArrange = [bool]$loaded.AutoArrange }
            if ($null -ne $loaded.AlignToGrid) { $settings.AlignToGrid = [bool]$loaded.AlignToGrid }
            if ($null -ne $loaded.ShowDesktopIcons) { $settings.ShowDesktopIcons = [bool]$loaded.ShowDesktopIcons }
            if ($null -ne $loaded.ShowRecycleBin) { $settings.ShowRecycleBin = [bool]$loaded.ShowRecycleBin }
            if ($null -ne $loaded.DesktopPath) { $settings.DesktopPath = [string]$loaded.DesktopPath }
            if ($null -ne $loaded.BossKeyEnabled) { $settings.BossKeyEnabled = [bool]$loaded.BossKeyEnabled }
            if ($null -ne $loaded.BossKeyName) { $settings.BossKeyName = [string]$loaded.BossKeyName }
            elseif ($null -ne $loaded.BossKey) { $settings.BossKeyName = [string]$loaded.BossKey }
            if ($null -ne $loaded.BossKeyVk) { $settings.BossKeyVk = [int]$loaded.BossKeyVk }
            if ($null -ne $loaded.BossKeyCtrl) { $settings.BossKeyCtrl = [bool]$loaded.BossKeyCtrl }
            if ($null -ne $loaded.BossKeyAlt) { $settings.BossKeyAlt = [bool]$loaded.BossKeyAlt }
            if ($null -ne $loaded.BossKeyShift) { $settings.BossKeyShift = [bool]$loaded.BossKeyShift }
            if ($null -ne $loaded.BossKeyWin) { $settings.BossKeyWin = [bool]$loaded.BossKeyWin }
            if ($null -ne $loaded.BossHideTaskbar) { $settings.BossHideTaskbar = [bool]$loaded.BossHideTaskbar }
            if ($null -ne $loaded.BossMuteAudio) { $settings.BossMuteAudio = [bool]$loaded.BossMuteAudio }
            if ($null -ne $loaded.BossDecoyEnabled) { $settings.BossDecoyEnabled = [bool]$loaded.BossDecoyEnabled }
            if ($null -ne $loaded.BossDecoyPreset) { $settings.BossDecoyPreset = [string]$loaded.BossDecoyPreset }
            if ($null -ne $loaded.BossDecoyPath) { $settings.BossDecoyPath = [string]$loaded.BossDecoyPath }
            if ($null -ne $loaded.BossDecoyPrewarm) { $settings.BossDecoyPrewarm = [bool]$loaded.BossDecoyPrewarm }
            if ($null -ne $loaded.BossDecoyCloseOnRestore) { $settings.BossDecoyCloseOnRestore = [bool]$loaded.BossDecoyCloseOnRestore }
            if ($null -ne $loaded.ConfirmExit) { $settings.ConfirmExit = [bool]$loaded.ConfirmExit }
            if ($null -ne $loaded.ShowWidgets) { $settings.ShowWidgets = [bool]$loaded.ShowWidgets }
            if ($null -ne $loaded.WidgetPosition) { $settings.WidgetPosition = [string]$loaded.WidgetPosition }
            if ($null -ne $loaded.ShowWidgetClock) { $settings.ShowWidgetClock = [bool]$loaded.ShowWidgetClock }
            if ($null -ne $loaded.ShowWidgetSystem) { $settings.ShowWidgetSystem = [bool]$loaded.ShowWidgetSystem }
            if ($null -ne $loaded.ShowWidgetStorage) { $settings.ShowWidgetStorage = [bool]$loaded.ShowWidgetStorage }
            if ($null -ne $loaded.Positions) {
                foreach ($p in $loaded.Positions.PSObject.Properties) {
                    try { $settings.Positions[$p.Name] = @{ X = [int]$p.Value.X; Y = [int]$p.Value.Y } } catch { }
                }
            }
        }
    } catch { $settings.Positions = @{} }
}

$settings.IconScale = [Math]::Max(32, [Math]::Min(256, [int]$settings.IconScale))
if ($null -eq $settings.UiScale -or [double]$settings.UiScale -le 0.4) { $settings.UiScale = 1.0 }
if ([string]::IsNullOrWhiteSpace($settings.SortBy)) { $settings.SortBy = "Name" }
if ([string]::IsNullOrWhiteSpace($settings.BossKeyName)) { $settings.BossKeyName = "F12" }
if ($settings.BossKeyVk -le 0) { $settings.BossKeyVk = 123 }
if ([string]::IsNullOrWhiteSpace($settings.BackgroundColor)) { $settings.BackgroundColor = "#0b0f19" }
if ([string]::IsNullOrWhiteSpace($settings.BackgroundType)) { $settings.BackgroundType = "Brand" }
if ([string]::IsNullOrWhiteSpace($settings.ImageMode)) { $settings.ImageMode = "Fill" }
if ([string]::IsNullOrWhiteSpace($settings.DesktopPath)) { $settings.DesktopPath = Join-Path $env:USERPROFILE "Desktop" }
try { $settings.DesktopPath = [Environment]::ExpandEnvironmentVariables($settings.DesktopPath) } catch { }

$script:desktopPath = [string]$settings.DesktopPath
if ([string]::IsNullOrWhiteSpace($script:desktopPath) -or -not (Test-Path -LiteralPath $script:desktopPath)) {
    try { $script:desktopPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop) } catch { }
    if ([string]::IsNullOrWhiteSpace($script:desktopPath) -or -not (Test-Path -LiteralPath $script:desktopPath)) {
        $script:desktopPath = Join-Path $env:USERPROFILE "Desktop"
    }
    $settings.DesktopPath = $script:desktopPath
}
if (-not (Test-Path -LiteralPath $script:desktopPath)) {
    try { New-Item -ItemType Directory -Path $script:desktopPath -Force | Out-Null } catch { }
}

# ============================================================
# 005 - GLOBAL STATE & THEME ENGINE
# ============================================================

$script:appContext = New-Object System.Windows.Forms.ApplicationContext
$script:forms = @()
$script:primaryForm = $null
$script:settingsForm = $null
$script:backgroundImage = $null
$script:contextMenu = $null
$script:itemContextMenu = $null
$script:recycleBinContextMenu = $null

$script:desktopItems = @()
$script:hoverItem = $null
$script:desktopFont = $null
$script:iconCache = @{}
$script:cutFiles = @()

$script:dragPanel = $null
$script:dragStartScreen = [System.Drawing.Point]::Empty
$script:dragDeltaX = 0
$script:dragDeltaY = 0
$script:isDragging = $false
$script:dragOriginalPositions = @{}

$script:selectedItems = @()
$script:refreshing = $false
$script:isPasting = $false
$script:lastPasteTime = 0

$script:lassoStart = [System.Drawing.Point]::Empty
$script:lassoEnd = [System.Drawing.Point]::Empty
$script:lassoRect = [System.Drawing.Rectangle]::Empty
$script:isLassoing = $false
$script:lassoInitialSelection = @()

$script:lastClickTime = 0
$script:lastClickPanel = $null

$script:cellWidth = 115
$script:cellHeight = 125

$script:fsw = $null
$script:refreshPending = $false
$script:refreshTimer = New-Object System.Windows.Forms.Timer
$script:refreshTimer.Interval = 1000

$script:Colors = @{
    Background   = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    PanelHover   = [System.Drawing.Color]::FromArgb(25, 255, 255, 255)
    Selected     = [System.Drawing.Color]::FromArgb(50, 59, 130, 246)
    Button       = [System.Drawing.ColorTranslator]::FromHtml("#1f2937")
    Text         = [System.Drawing.Color]::White
    TextMuted    = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    Accent       = [System.Drawing.ColorTranslator]::FromHtml("#3b82f6")
    AccentHover  = [System.Drawing.ColorTranslator]::FromHtml("#2563eb")
    Card         = [System.Drawing.ColorTranslator]::FromHtml("#111827")
    CardBorder   = [System.Drawing.ColorTranslator]::FromHtml("#1f2937")
    InputBg      = [System.Drawing.ColorTranslator]::FromHtml("#1f2937")
}

# ============================================================
# 006 - HELPER FUNCTIONS & SCREEN CLAMPING
# ============================================================

function Save-DesktopSettings {
    try {
        $object = [ordered]@{
            BackgroundType          = [string]$settings.BackgroundType
            BackgroundColor         = [string]$settings.BackgroundColor
            ImagePath               = [string]$settings.ImagePath
            ImageMode               = [string]$settings.ImageMode
            WallpaperDimming        = [int]$settings.WallpaperDimming
            IconScale               = [int]$settings.IconScale
            UiScale                 = [double]$settings.UiScale
            SortBy                  = [string]$settings.SortBy
            AutoArrange             = [bool]$settings.AutoArrange
            AlignToGrid             = [bool]$settings.AlignToGrid
            ShowDesktopIcons        = [bool]$settings.ShowDesktopIcons
            ShowRecycleBin          = [bool]$settings.ShowRecycleBin
            DesktopPath             = [string]$settings.DesktopPath
            BossKeyEnabled          = [bool]$settings.BossKeyEnabled
            BossKeyName             = [string]$settings.BossKeyName
            BossKeyVk               = [int]$settings.BossKeyVk
            BossKeyCtrl             = [bool]$settings.BossKeyCtrl
            BossKeyAlt              = [bool]$settings.BossKeyAlt
            BossKeyShift            = [bool]$settings.BossKeyShift
            BossKeyWin              = [bool]$settings.BossKeyWin
            BossHideTaskbar         = [bool]$settings.BossHideTaskbar
            BossMuteAudio           = [bool]$settings.BossMuteAudio
            BossDecoyEnabled        = [bool]$settings.BossDecoyEnabled
            BossDecoyPreset         = [string]$settings.BossDecoyPreset
            BossDecoyPath           = [string]$settings.BossDecoyPath
            BossDecoyPrewarm        = [bool]$settings.BossDecoyPrewarm
            BossDecoyCloseOnRestore = [bool]$settings.BossDecoyCloseOnRestore
            ConfirmExit             = [bool]$settings.ConfirmExit
            ShowWidgets             = [bool]$settings.ShowWidgets
            WidgetPosition          = [string]$settings.WidgetPosition
            ShowWidgetClock         = [bool]$settings.ShowWidgetClock
            ShowWidgetSystem        = [bool]$settings.ShowWidgetSystem
            ShowWidgetStorage       = [bool]$settings.ShowWidgetStorage
            Positions               = $settings.Positions
        }
        $json = $object | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($settingsFile, $json, [System.Text.UTF8Encoding]::new($false))
        Apply-BossKeySettings
    } catch { }
}

function Apply-BossKeySettings {
    try {
        [WinDInterceptor]::BossKeyEnabled = [bool]$settings.BossKeyEnabled
        [WinDInterceptor]::BossHideTaskbar = [bool]$settings.BossHideTaskbar
        [WinDInterceptor]::BossMuteAudio = [bool]$settings.BossMuteAudio
        [WinDInterceptor]::BossDecoyEnabled = [bool]$settings.BossDecoyEnabled
        [WinDInterceptor]::BossDecoyPath = [string]$settings.BossDecoyPath
        [WinDInterceptor]::BossDecoyPrewarm = [bool]$settings.BossDecoyPrewarm
        [WinDInterceptor]::BossDecoyCloseOnRestore = [bool]$settings.BossDecoyCloseOnRestore
        
        $vk = if ($settings.BossKeyVk -gt 0) { [uint32]$settings.BossKeyVk } else { 0x7B }
        $reqCtrl = [bool]$settings.BossKeyCtrl
        $reqAlt = [bool]$settings.BossKeyAlt
        $reqShift = [bool]$settings.BossKeyShift
        $reqWin = [bool]$settings.BossKeyWin

        [WinDInterceptor]::BossKeyVk = $vk
        [WinDInterceptor]::BossKeyRequireCtrl = $reqCtrl
        [WinDInterceptor]::BossKeyRequireAlt = $reqAlt
        [WinDInterceptor]::BossKeyRequireShift = $reqShift
        [WinDInterceptor]::BossKeyRequireWin = $reqWin

        [WinDInterceptor]::OnOpenSettingsRequested = {
            try {
                if ($null -ne $script:primaryForm -and -not $script:primaryForm.IsDisposed) {
                    $script:primaryForm.BeginInvoke([Action]{ Show-Settings })
                } else {
                    Show-Settings
                }
            } catch { }
        }

        [WinDInterceptor]::EnsureHookActive()
        if ($settings.BossDecoyEnabled -and $settings.BossDecoyPrewarm) {
            [WinDInterceptor]::PrewarmDecoyApp()
        }
        Write-DesktopLog "Boss Key bound: '$($settings.BossKeyName)' (VK: 0x$($vk.ToString('X2')), Ctrl: $reqCtrl, Alt: $reqAlt, Shift: $reqShift, Win: $reqWin, Decoy: $($settings.BossDecoyEnabled), Prewarm: $($settings.BossDecoyPrewarm))"
    } catch { }
}

function Get-InstalledSoftwareList {
    if ($null -ne $script:cachedInstalledSoftware -and $script:cachedInstalledSoftware.Count -gt 0) {
        return $script:cachedInstalledSoftware
    }
    $apps = [System.Collections.Generic.List[PSObject]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # 1. Start Menu Shortcuts (.lnk)
    $startDirs = @(
        [System.IO.Path]::Combine([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonStartMenu), "Programs"),
        [System.IO.Path]::Combine([Environment]::GetFolderPath([Environment+SpecialFolder]::StartMenu), "Programs")
    )
    
    try {
        $wscript = New-Object -ComObject WScript.Shell
        foreach ($dir in $startDirs) {
            if (Test-Path -LiteralPath $dir) {
                Get-ChildItem -LiteralPath $dir -Filter "*.lnk" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $name = $_.BaseName
                        if ($name -match "(?i)uninstall|help|readme|documentation|license|website") { return }
                        if ($seen.Contains($name)) { return }
                        
                        $shortcut = $wscript.CreateShortcut($_.FullName)
                        $target = $shortcut.TargetPath
                        if (![string]::IsNullOrWhiteSpace($target) -and ($target.EndsWith(".exe") -or $target.EndsWith(".cmd") -or $target.EndsWith(".bat"))) {
                            if (Test-Path -LiteralPath $target) {
                                $seen.Add($name) | Out-Null
                                $apps.Add([PSCustomObject]@{
                                    Name = $name
                                    Path = $target
                                })
                            }
                        }
                    } catch { }
                }
            }
        }
    } catch { }

    # 2. Registry App Paths
    $appPathKeys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths"
    )
    foreach ($keyPath in $appPathKeys) {
        if (Test-Path -LiteralPath $keyPath) {
            Get-ChildItem -LiteralPath $keyPath -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $exeName = $_.PSChildName
                    $defaultVal = (Get-ItemProperty -LiteralPath $_.PSPath -Name "(default)" -ErrorAction SilentlyContinue)."(default)"
                    if (![string]::IsNullOrWhiteSpace($defaultVal) -and (Test-Path -LiteralPath $defaultVal)) {
                        $cleanName = [System.IO.Path]::GetFileNameWithoutExtension($exeName)
                        if (!$seen.Contains($cleanName) -and $cleanName -notmatch "(?i)uninstall|setup|installer") {
                            $seen.Add($cleanName) | Out-Null
                            $apps.Add([PSCustomObject]@{
                                Name = $cleanName
                                Path = $defaultVal
                            })
                        }
                    }
                } catch { }
            }
        }
    }

    # 3. Built-in Windows Accessories
    $builtins = @(
        @{ Name = "Notepad"; Path = "notepad.exe" },
        @{ Name = "Calculator"; Path = "calc.exe" },
        @{ Name = "Task Manager"; Path = "taskmgr.exe" },
        @{ Name = "PowerShell"; Path = "powershell.exe" },
        @{ Name = "Command Prompt"; Path = "cmd.exe" },
        @{ Name = "Paint"; Path = "mspaint.exe" },
        @{ Name = "WordPad"; Path = "wordpad.exe" },
        @{ Name = "File Explorer"; Path = "explorer.exe" }
    )
    foreach ($b in $builtins) {
        if (!$seen.Contains($b.Name)) {
            $seen.Add($b.Name) | Out-Null
            $apps.Add([PSCustomObject]@{
                Name = $b.Name
                Path = $b.Path
            })
        }
    }

    $script:cachedInstalledSoftware = @($apps | Sort-Object Name)
    return $script:cachedInstalledSoftware
}

function Enable-DoubleBuffer {
    param([System.Windows.Forms.Control]$Control)
    if ($null -eq $Control) { return }
    try {
        $prop = $Control.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($null -ne $prop) { $prop.SetValue($Control, $true, $null) }
    } catch { }
}

function Invalidate-AllDesktopForms {
    foreach ($f in $script:forms) {
        if ($null -ne $f -and -not $f.IsDisposed) {
            try { $f.Invalidate() } catch {}
        }
    }
}

function Clear-Selection {
    foreach ($i in $script:selectedItems) { if ($null -ne $i) { $i.Selected = $false } }
    $script:selectedItems = @()
    Invalidate-AllDesktopForms
}

function Set-Selection {
    param($Item)
    if ($null -eq $Item) { return }
    if ($script:selectedItems -notcontains $Item) {
        $Item.Selected = $true
        $script:selectedItems += $Item
        Invalidate-AllDesktopForms
    }
}

function Remove-Selection {
    param($Item)
    if ($null -eq $Item) { return }
    if ($script:selectedItems -contains $Item) {
        $Item.Selected = $false
        $script:selectedItems = @($script:selectedItems | Where-Object { $_ -ne $Item })
        Invalidate-AllDesktopForms
    }
}

function Get-ColorFromHex {
    param([string]$Hex)
    try {
        if ([string]::IsNullOrWhiteSpace($Hex)) { return $script:Colors.Background }
        return [System.Drawing.ColorTranslator]::FromHtml($Hex)
    } catch { return $script:Colors.Background }
}

function Enable-FormDragging($Form, $Controls = @()) {
    if ($null -eq $Form) { return }
    $dragHandler = {
        param($s, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            [NativeWindowDrag]::DragWindow($Form.Handle)
        }
    }
    $Form.Add_MouseDown($dragHandler)
    foreach ($c in $Controls) {
        if ($null -ne $c) {
            $c.Add_MouseDown($dragHandler)
        }
    }
}

function Get-VisibleDesktopCoordinate([int]$TargetX, [int]$TargetY, [int]$ItemWidth, [int]$ItemHeight) {
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $targetRect = New-Object System.Drawing.Rectangle($TargetX, $TargetY, $ItemWidth, $ItemHeight)
    
    foreach ($s in $screens) {
        if ($s.WorkingArea.IntersectsWith($targetRect) -or $s.WorkingArea.Contains($TargetX, $TargetY)) {
            return @{ X = $TargetX; Y = $TargetY; IsClamped = $false }
        }
    }

    $primary = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $clampedX = [Math]::Max($primary.Left + 14, [Math]::Min($primary.Right - $ItemWidth - 14, $TargetX))
    $clampedY = [Math]::Max($primary.Top + 14, [Math]::Min($primary.Bottom - $ItemHeight - 14, $TargetY))
    return @{ X = $clampedX; Y = $clampedY; IsClamped = $true }
}

# ============================================================
# 007 - MULTI-MONITOR SCREEN-ADAPTIVE GRID ENGINE
# ============================================================

function Get-ScreenForPoint([int]$X, [int]$Y) {
    $screens = [System.Windows.Forms.Screen]::AllScreens
    foreach ($s in $screens) {
        if ($s.WorkingArea.Contains($X, $Y)) { return $s }
    }
    return [System.Windows.Forms.Screen]::PrimaryScreen
}

function Get-ScreenGridBounds($Screen) {
    $uiScale = 1.0; if ($null -ne $settings.UiScale -and [double]$settings.UiScale -gt 0) { $uiScale = [double]$settings.UiScale }
    $cW = [Math]::Max(1, [int]$script:cellWidth)
    $cH = [Math]::Max(1, [int]$script:cellHeight)
    $margin = [int](14 * $uiScale)
    
    $availW = [Math]::Max($cW, $Screen.WorkingArea.Width - ($margin * 2))
    $availH = [Math]::Max($cH, $Screen.WorkingArea.Height - ($margin * 2))
    
    $cols = [Math]::Max(1, [int][Math]::Floor($availW / [double]$cW))
    $rows = [Math]::Max(1, [int][Math]::Floor($availH / [double]$cH))
    
    return @{
        Screen = $Screen
        Margin = $margin
        Cols   = $cols
        Rows   = $rows
        Left   = $Screen.WorkingArea.Left
        Top    = $Screen.WorkingArea.Top
    }
}

function Get-OccupiedGridMap($excludeItems = @()) {
    $map = @{}
    $cW = [Math]::Max(1, [int]$script:cellWidth)
    $cH = [Math]::Max(1, [int]$script:cellHeight)
    
    foreach ($item in $script:desktopItems) {
        if ($null -eq $item -or $excludeItems -contains $item -or $excludeItems -contains $item.Path) { continue }
        if ($item.Bounds.Width -gt 0 -and $item.Bounds.Height -gt 0) {
            $screen = Get-ScreenForPoint $item.Bounds.X $item.Bounds.Y
            $info = Get-ScreenGridBounds $screen
            $relX = $item.Bounds.X - $info.Left - $info.Margin
            $relY = $item.Bounds.Y - $info.Top - $info.Margin
            $col = [int][Math]::Max(0, [Math]::Min($info.Cols - 1, [Math]::Round($relX / [double]$cW)))
            $row = [int][Math]::Max(0, [Math]::Min($info.Rows - 1, [Math]::Round($relY / [double]$cH)))
            $map["$($screen.DeviceName)_$col,$row"] = $true
        }
    }
    return $map
}

function Find-NearestFreeGridSlot([int]$TargetX, [int]$TargetY, [hashtable]$OccupiedMap) {
    $screen = Get-ScreenForPoint $TargetX $TargetY
    $info = Get-ScreenGridBounds $screen
    $cW = [int]$script:cellWidth; $cH = [int]$script:cellHeight
    
    $relX = $TargetX - $info.Left - $info.Margin
    $relY = $TargetY - $info.Top - $info.Margin
    $targetCol = [int][Math]::Max(0, [Math]::Min($info.Cols - 1, [Math]::Round($relX / [double]$cW)))
    $targetRow = [int][Math]::Max(0, [Math]::Min($info.Rows - 1, [Math]::Round($relY / [double]$cH)))

    # 1. Check exact requested grid slot on this screen
    $slotKey = "$($screen.DeviceName)_$targetCol,$targetRow"
    if (-not $OccupiedMap.ContainsKey($slotKey)) {
        $OccupiedMap[$slotKey] = $true
        $x = $info.Left + $info.Margin + ($targetCol * $cW)
        $y = $info.Top + $info.Margin + ($targetRow * $cH)
        return @{ X = $x; Y = $y; Screen = $screen }
    }

    # 2. Spiral 2D search on this specific screen
    $maxDist = [Math]::Max($info.Cols, $info.Rows) + 5
    for ($dist = 1; $dist -le $maxDist; $dist++) {
        for ($dr = -$dist; $dr -le $dist; $dr++) {
            for ($dc = -$dist; $dc -le $dist; $dc++) {
                if ([Math]::Abs($dr) -ne $dist -and [Math]::Abs($dc) -ne $dist) { continue }
                $nc = $targetCol + $dc
                $nr = $targetRow + $dr
                if ($nc -ge 0 -and $nc -lt $info.Cols -and $nr -ge 0 -and $nr -lt $info.Rows) {
                    $key = "$($screen.DeviceName)_$nc,$nr"
                    if (-not $OccupiedMap.ContainsKey($key)) {
                        $OccupiedMap[$key] = $true
                        $x = $info.Left + $info.Margin + ($nc * $cW)
                        $y = $info.Top + $info.Margin + ($nr * $cH)
                        return @{ X = $x; Y = $y; Screen = $screen }
                    }
                }
            }
        }
    }

    # 3. Fallback scan across all screens (column by column, top to bottom)
    foreach ($s in [System.Windows.Forms.Screen]::AllScreens) {
        $sInfo = Get-ScreenGridBounds $s
        for ($c = 0; $c -lt $sInfo.Cols; $c++) {
            for ($r = 0; $r -lt $sInfo.Rows; $r++) {
                $k = "$($s.DeviceName)_$c,$r"
                if (-not $OccupiedMap.ContainsKey($k)) {
                    $OccupiedMap[$k] = $true
                    $x = $sInfo.Left + $sInfo.Margin + ($c * $cW)
                    $y = $sInfo.Top + $sInfo.Margin + ($r * $cH)
                    return @{ X = $x; Y = $y; Screen = $s }
                }
            }
        }
    }

    return @{ X = $info.Left + $info.Margin; Y = $info.Top + $info.Margin; Screen = $screen }
}

# ============================================================
# 008 - NATIVE C# SUITE: RECYCLE BIN, HOOKS, OLE, ICONS & MODERN SCROLLBAR
# ============================================================

Write-ConsoleStatus "  [*] Compiling Win32 & OLE hardware subsystems (please wait)..." "Yellow"
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Windows.Forms;

public static class NativeWindowDrag {
    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    public const int WM_NCLBUTTONDOWN = 0xA1;
    public const int HTCAPTION = 0x2;

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;

    public static void DragWindow(IntPtr hWnd) {
        try {
            ReleaseCapture();
            SendMessage(hWnd, WM_NCLBUTTONDOWN, (IntPtr)HTCAPTION, IntPtr.Zero);
        } catch { }
    }

    public static void HideConsole() {
        try {
            IntPtr hConsole = GetConsoleWindow();
            if (hConsole != IntPtr.Zero) {
                ShowWindowAsync(hConsole, SW_HIDE);
                ShowWindow(hConsole, SW_HIDE);
            }
        } catch { }
    }
}

public class ModernScrollBar : Control {
    private int _minimum = 0;
    private int _maximum = 100;
    private int _value = 0;
    private int _largeChange = 20;
    private bool _isDragging = false;
    private int _dragStartMouseY = 0;
    private int _dragStartValue = 0;
    private bool _isHovered = false;

    public event EventHandler ValueChanged;

    public int Minimum { get { return _minimum; } set { _minimum = value; Invalidate(); } }
    public int Maximum { get { return _maximum; } set { _maximum = value; Invalidate(); } }
    public int LargeChange { get { return _largeChange; } set { _largeChange = value; Invalidate(); } }
    public int Value {
        get { return _value; }
        set {
            int clamped = Math.Max(_minimum, Math.Min(_maximum, value));
            if (_value != clamped) {
                _value = clamped;
                Invalidate();
                if (ValueChanged != null) ValueChanged(this, EventArgs.Empty);
            }
        }
    }

    public ModernScrollBar() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        Width = 8;
        BackColor = Color.FromArgb(15, 23, 42);
        Cursor = Cursors.Default;
    }

    protected override void OnMouseEnter(EventArgs e) { _isHovered = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { if (!_isDragging) { _isHovered = false; Invalidate(); } base.OnMouseLeave(e); }

    private Rectangle GetThumbRectangle() {
        int trackHeight = Height;
        if (trackHeight <= 0 || _maximum <= _minimum) return Rectangle.Empty;

        int totalRange = (_maximum - _minimum) + _largeChange;
        int thumbHeight = Math.Max(24, (int)((float)_largeChange / totalRange * trackHeight));
        int availableTrack = trackHeight - thumbHeight;

        int thumbY = (int)((float)(_value - _minimum) / (_maximum - _minimum) * availableTrack);
        return new Rectangle(1, thumbY, Width - 2, thumbHeight);
    }

    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.Clear(BackColor);

        Rectangle thumb = GetThumbRectangle();
        if (!thumb.IsEmpty) {
            Color thumbColor = _isDragging ? ColorTranslator.FromHtml("#3b82f6") : (_isHovered ? ColorTranslator.FromHtml("#64748b") : ColorTranslator.FromHtml("#334155"));
            using (SolidBrush sb = new SolidBrush(thumbColor)) {
                using (GraphicsPath gp = GetRoundedRectangle(thumb, (Width - 2) / 2)) {
                    g.FillPath(sb, gp);
                }
            }
        }
    }

    private GraphicsPath GetRoundedRectangle(Rectangle rc, int r) {
        GraphicsPath gp = new GraphicsPath();
        if (r <= 0) { gp.AddRectangle(rc); return gp; }
        int d = r * 2;
        gp.AddArc(rc.X, rc.Y, d, d, 180, 90);
        gp.AddArc(rc.Right - d, rc.Y, d, d, 270, 90);
        gp.AddArc(rc.Right - d, rc.Bottom - d, d, d, 0, 90);
        gp.AddArc(rc.X, rc.Bottom - d, d, d, 90, 90);
        gp.CloseFigure();
        return gp;
    }

    protected override void OnMouseDown(MouseEventArgs e) {
        if (e.Button == MouseButtons.Left) {
            Rectangle thumb = GetThumbRectangle();
            if (thumb.Contains(e.Location)) {
                _isDragging = true;
                _dragStartMouseY = e.Y;
                _dragStartValue = _value;
                Capture = true;
            } else {
                int availableTrack = Height - thumb.Height;
                if (availableTrack > 0) {
                    float ratio = (float)Math.Max(0, Math.Min(availableTrack, e.Y - (thumb.Height / 2))) / availableTrack;
                    Value = _minimum + (int)(ratio * (_maximum - _minimum));
                }
            }
        }
        base.OnMouseDown(e);
    }

    protected override void OnMouseMove(MouseEventArgs e) {
        if (_isDragging) {
            Rectangle thumb = GetThumbRectangle();
            int availableTrack = Height - thumb.Height;
            if (availableTrack > 0) {
                int deltaY = e.Y - _dragStartMouseY;
                float deltaVal = ((float)deltaY / availableTrack) * (_maximum - _minimum);
                Value = _dragStartValue + (int)deltaVal;
            }
        }
        base.OnMouseMove(e);
    }

    protected override void OnMouseUp(MouseEventArgs e) {
        if (_isDragging) {
            _isDragging = false;
            Capture = false;
            _isHovered = ClientRectangle.Contains(e.Location);
            Invalidate();
        }
        base.OnMouseUp(e);
    }
}

public class NoScrollTrackBar : TrackBar {
    private const int WM_MOUSEWHEEL = 0x020A;
    public Action<int> OnForwardMouseWheel = null;

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_MOUSEWHEEL) {
            int delta = (short)((m.WParam.ToInt64() >> 16) & 0xFFFF);
            if (OnForwardMouseWheel != null) {
                OnForwardMouseWheel(delta);
            } else if (this.Parent != null) {
                SendMessage(this.Parent.Handle, (uint)m.Msg, m.WParam, m.LParam);
            }
            return;
        }
        base.WndProc(ref m);
    }

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
}

public class ModernCheckBox : CheckBox {
    public Color AccentColor { get; set; }
    private bool _isHovered = false;

    public ModernCheckBox() {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        this.AccentColor = ColorTranslator.FromHtml("#38bdf8");
        this.BackColor = ColorTranslator.FromHtml("#111827");
        this.ForeColor = ColorTranslator.FromHtml("#e2e8f0");
        this.Cursor = Cursors.Hand;
        this.AutoSize = true;
    }

    public override Size GetPreferredSize(Size proposedSize) {
        Size textSize = TextRenderer.MeasureText(this.Text, this.Font);
        return new Size(18 + 10 + textSize.Width + 6, Math.Max(24, textSize.Height + 4));
    }

    protected override void OnParentBackColorChanged(EventArgs e) {
        if (this.Parent != null) this.BackColor = this.Parent.BackColor;
        base.OnParentBackColorChanged(e);
    }

    protected override void OnParentChanged(EventArgs e) {
        if (this.Parent != null) this.BackColor = this.Parent.BackColor;
        base.OnParentChanged(e);
    }

    protected override void OnMouseEnter(EventArgs e) { _isHovered = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { _isHovered = false; Invalidate(); base.OnMouseLeave(e); }

    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics;
        Color parentBg = (this.Parent != null) ? this.Parent.BackColor : this.BackColor;
        using (SolidBrush bgBrush = new SolidBrush(parentBg)) {
            g.FillRectangle(bgBrush, this.ClientRectangle);
        }

        g.SmoothingMode = SmoothingMode.AntiAlias;

        int boxSize = 18;
        int boxY = (this.Height - boxSize) / 2;
        Rectangle boxRect = new Rectangle(0, boxY, boxSize, boxSize);

        if (this.Checked) {
            using (SolidBrush fillBrush = new SolidBrush(this.AccentColor)) {
                using (GraphicsPath path = GetRoundedRect(boxRect, 4)) {
                    g.FillPath(fillBrush, path);
                }
            }
            using (Pen checkPen = new Pen(Color.White, 2.0f)) {
                checkPen.StartCap = LineCap.Round;
                checkPen.EndCap = LineCap.Round;
                PointF p1 = new PointF(boxRect.X + 4.5f, boxRect.Y + 9.0f);
                PointF p2 = new PointF(boxRect.X + 7.5f, boxRect.Y + 12.5f);
                PointF p3 = new PointF(boxRect.X + 13.5f, boxRect.Y + 5.5f);
                g.DrawLines(checkPen, new PointF[] { p1, p2, p3 });
            }
        } else {
            using (SolidBrush fillBrush = new SolidBrush(ColorTranslator.FromHtml("#0f172a")))
            using (Pen borderPen = new Pen(_isHovered ? ColorTranslator.FromHtml("#64748b") : ColorTranslator.FromHtml("#334155"), 1.5f)) {
                using (GraphicsPath path = GetRoundedRect(boxRect, 4)) {
                    g.FillPath(fillBrush, path);
                    g.DrawPath(borderPen, path);
                }
            }
        }

        int textX = boxSize + 10;
        Rectangle textRect = new Rectangle(textX, 0, this.Width - textX, this.Height);
        TextRenderer.DrawText(g, this.Text, this.Font, textRect, this.ForeColor, TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine);
    }

    private static GraphicsPath GetRoundedRect(Rectangle rc, int r) {
        GraphicsPath gp = new GraphicsPath();
        if (r <= 0) { gp.AddRectangle(rc); return gp; }
        int d = r * 2;
        gp.AddArc(rc.X, rc.Y, d, d, 180, 90);
        gp.AddArc(rc.Right - d, rc.Y, d, d, 270, 90);
        gp.AddArc(rc.Right - d, rc.Bottom - d, d, d, 0, 90);
        gp.AddArc(rc.X, rc.Bottom - d, d, d, 90, 90);
        gp.CloseFigure();
        return gp;
    }
}

public class ModernRadioButton : RadioButton {
    public Color AccentColor { get; set; }
    private bool _isHovered = false;

    public ModernRadioButton() {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        this.AccentColor = ColorTranslator.FromHtml("#38bdf8");
        this.BackColor = ColorTranslator.FromHtml("#111827");
        this.ForeColor = ColorTranslator.FromHtml("#e2e8f0");
        this.Cursor = Cursors.Hand;
        this.AutoSize = true;
    }

    public override Size GetPreferredSize(Size proposedSize) {
        Size textSize = TextRenderer.MeasureText(this.Text, this.Font);
        return new Size(18 + 10 + textSize.Width + 6, Math.Max(24, textSize.Height + 4));
    }

    protected override void OnParentBackColorChanged(EventArgs e) {
        if (this.Parent != null) this.BackColor = this.Parent.BackColor;
        base.OnParentBackColorChanged(e);
    }

    protected override void OnParentChanged(EventArgs e) {
        if (this.Parent != null) this.BackColor = this.Parent.BackColor;
        base.OnParentChanged(e);
    }

    protected override void OnMouseEnter(EventArgs e) { _isHovered = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { _isHovered = false; Invalidate(); base.OnMouseLeave(e); }

    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics;
        Color parentBg = (this.Parent != null) ? this.Parent.BackColor : this.BackColor;
        using (SolidBrush bgBrush = new SolidBrush(parentBg)) {
            g.FillRectangle(bgBrush, this.ClientRectangle);
        }

        g.SmoothingMode = SmoothingMode.AntiAlias;

        int circleSize = 18;
        int circleY = (this.Height - circleSize) / 2;
        Rectangle circleRect = new Rectangle(0, circleY, circleSize, circleSize);

        if (this.Checked) {
            using (SolidBrush fillBrush = new SolidBrush(ColorTranslator.FromHtml("#0f172a")))
            using (Pen borderPen = new Pen(this.AccentColor, 2.0f)) {
                g.FillEllipse(fillBrush, circleRect);
                g.DrawEllipse(borderPen, circleRect.X + 1, circleRect.Y + 1, circleSize - 2, circleSize - 2);
            }
            int dotSize = 8;
            int dotX = circleRect.X + (circleSize - dotSize) / 2;
            int dotY = circleRect.Y + (circleSize - dotSize) / 2;
            using (SolidBrush dotBrush = new SolidBrush(this.AccentColor)) {
                g.FillEllipse(dotBrush, dotX, dotY, dotSize, dotSize);
            }
        } else {
            using (SolidBrush fillBrush = new SolidBrush(ColorTranslator.FromHtml("#0f172a")))
            using (Pen borderPen = new Pen(_isHovered ? ColorTranslator.FromHtml("#64748b") : ColorTranslator.FromHtml("#334155"), 1.5f)) {
                g.FillEllipse(fillBrush, circleRect);
                g.DrawEllipse(borderPen, circleRect.X + 1, circleRect.Y + 1, circleSize - 2, circleSize - 2);
            }
        }

        int textX = circleSize + 10;
        Rectangle textRect = new Rectangle(textX, 0, this.Width - textX, this.Height);
        TextRenderer.DrawText(g, this.Text, this.Font, textRect, this.ForeColor, TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine);
    }
}

public class ModernComboBox : ComboBox {
    private const int WM_PAINT = 0xF;
    private const int WM_MOUSEWHEEL = 0x020A;
    private bool _isHovered = false;

    public ModernComboBox() {
        this.DrawMode = DrawMode.OwnerDrawFixed;
        this.DropDownStyle = ComboBoxStyle.DropDownList;
        this.BackColor = ColorTranslator.FromHtml("#0f172a");
        this.ForeColor = ColorTranslator.FromHtml("#f8fafc");
        this.ItemHeight = 26;
        this.FlatStyle = FlatStyle.Flat;
        this.Cursor = Cursors.Hand;
        this.DoubleBuffered = true;
    }

    protected override void OnMouseEnter(EventArgs e) { _isHovered = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { _isHovered = false; Invalidate(); base.OnMouseLeave(e); }

    protected override void OnDrawItem(DrawItemEventArgs e) {
        if (e.Index < 0 || e.Index >= this.Items.Count) return;
        Graphics g = e.Graphics;
        string itemText = this.Items[e.Index].ToString();
        Rectangle rect = e.Bounds;

        bool isHeader = itemText.StartsWith("───");
        bool isSelected = ((e.State & DrawItemState.Selected) == DrawItemState.Selected) && !isHeader;

        Color bgColor = isSelected ? ColorTranslator.FromHtml("#1e293b") : ColorTranslator.FromHtml("#0f172a");
        using (SolidBrush bgBrush = new SolidBrush(bgColor)) {
            g.FillRectangle(bgBrush, rect);
        }

        if (isSelected) {
            using (SolidBrush accentBrush = new SolidBrush(ColorTranslator.FromHtml("#38bdf8"))) {
                g.FillRectangle(accentBrush, rect.X, rect.Y, 3, rect.Height);
            }
        }

        Color textColor = isHeader ? ColorTranslator.FromHtml("#64748b") : (isSelected ? ColorTranslator.FromHtml("#38bdf8") : ColorTranslator.FromHtml("#f8fafc"));
        using (Font font = isHeader ? new Font("Segoe UI", 8.25f, FontStyle.Italic) : (isSelected ? new Font("Segoe UI", 9.0f, FontStyle.Bold) : new Font("Segoe UI", 9.0f, FontStyle.Regular))) {
            Rectangle textRect = new Rectangle(rect.X + 8, rect.Y, rect.Width - 12, rect.Height);
            TextRenderer.DrawText(g, itemText, font, textRect, textColor, TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine);
        }
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_MOUSEWHEEL) {
            if (!this.DroppedDown) {
                if (this.Parent != null) {
                    SendMessage(this.Parent.Handle, (uint)m.Msg, m.WParam, m.LParam);
                }
                return;
            }
        }

        base.WndProc(ref m);

        if (m.Msg == WM_PAINT) {
            using (Graphics g = Graphics.FromHwnd(this.Handle)) {
                g.SmoothingMode = SmoothingMode.AntiAlias;

                Color borderColor = (this.Focused || _isHovered) ? ColorTranslator.FromHtml("#38bdf8") : ColorTranslator.FromHtml("#334155");
                using (Pen borderPen = new Pen(borderColor, 1f)) {
                    g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                }

                int arrowBoxWidth = 24;
                Rectangle arrowBox = new Rectangle(this.Width - arrowBoxWidth, 1, arrowBoxWidth - 1, this.Height - 2);
                using (SolidBrush abBg = new SolidBrush(ColorTranslator.FromHtml("#0f172a"))) {
                    g.FillRectangle(abBg, arrowBox);
                }

                int arrowX = this.Width - 14;
                int arrowY = (this.Height / 2) - 2;
                using (Pen arrowPen = new Pen((this.Focused || _isHovered) ? ColorTranslator.FromHtml("#38bdf8") : ColorTranslator.FromHtml("#94a3b8"), 1.8f)) {
                    arrowPen.StartCap = LineCap.Round;
                    arrowPen.EndCap = LineCap.Round;
                    g.DrawLine(arrowPen, arrowX - 4, arrowY, arrowX, arrowY + 4);
                    g.DrawLine(arrowPen, arrowX, arrowY + 4, arrowX + 4, arrowY);
                }
            }
        }
    }

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
}

public class CustomDesktopForm : Form {
    private const int WM_SYSCOMMAND = 0x0112;
    private const int SC_MINIMIZE = 0xF020;
    private const int WM_WINDOWPOSCHANGING = 0x0046;
    private const int WM_SHOWWINDOW = 0x0018;
    private const uint SWP_HIDEWINDOW = 0x0080;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    private const uint WM_DROPFILES = 0x0233;
    private const uint WM_COPYDATA = 0x004A;
    private const uint WM_COPYGLOBALDATA = 0x0049;
    private const uint MSGFLT_ALLOW = 1;

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    private const int SW_HIDE = 0;

    [DllImport("shell32.dll")]
    public static extern int SHEmptyRecycleBin(IntPtr hwnd, string pszRootPath, uint dwFlags);

    public static void EmptyRecycleBin(IntPtr hwnd) {
        try {
            SHEmptyRecycleBin(hwnd, null, 0);
        } catch { }
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool ChangeWindowMessageFilterEx(IntPtr hWnd, uint msg, uint action, IntPtr pChangeFilterStruct);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool ChangeWindowMessageFilter(uint msg, uint flags);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    private static readonly IntPtr HWND_TOP = new IntPtr(0);
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_SHOWWINDOW = 0x0040;

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    public static HashSet<IntPtr> DesktopHwnds = new HashSet<IntPtr>();

    public static void HideConsole() {
        try {
            IntPtr hWnd = GetConsoleWindow();
            if (hWnd != IntPtr.Zero) {
                ShowWindowAsync(hWnd, SW_HIDE);
                ShowWindow(hWnd, SW_HIDE);
            }
        } catch { }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WINDOWPOS {
        public IntPtr hwnd;
        public IntPtr hwndInsertAfter;
        public int x;
        public int y;
        public int cx;
        public int cy;
        public uint flags;
    }

    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= WS_EX_TOOLWINDOW;
            return cp;
        }
    }

    protected override void OnHandleCreated(EventArgs e) {
        base.OnHandleCreated(e);
        try {
            ChangeWindowMessageFilterEx(this.Handle, WM_DROPFILES, MSGFLT_ALLOW, IntPtr.Zero);
            ChangeWindowMessageFilterEx(this.Handle, WM_COPYDATA, MSGFLT_ALLOW, IntPtr.Zero);
            ChangeWindowMessageFilterEx(this.Handle, WM_COPYGLOBALDATA, MSGFLT_ALLOW, IntPtr.Zero);
            ChangeWindowMessageFilter(WM_DROPFILES, MSGFLT_ALLOW);
            ChangeWindowMessageFilter(WM_COPYDATA, MSGFLT_ALLOW);
            ChangeWindowMessageFilter(WM_COPYGLOBALDATA, MSGFLT_ALLOW);
        } catch { }
    }

    public static void ActivateDesktop() {
        try {
            foreach (IntPtr h in DesktopHwnds) {
                if (h != IntPtr.Zero) {
                    SetWindowPos(h, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                    SetForegroundWindow(h);
                }
            }
        } catch { }
    }

    private const int WM_NCHITTEST = 0x0084;
    private const int HTCLIENT = 1;
    private const int HTTRANSPARENT = -1;
    private const int WM_RBUTTONUP = 0x0205;
    private const int WM_CONTEXTMENU = 0x007B;

    public static Action<int, int, IntPtr> OnDesktopRightClick = null;

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_CONTEXTMENU || m.Msg == WM_RBUTTONUP) {
            if (OnDesktopRightClick != null) {
                Point p = Cursor.Position;
                OnDesktopRightClick(p.X, p.Y, this.Handle);
                m.Result = IntPtr.Zero;
                return;
            }
        }
        if (m.Msg == WM_NCHITTEST) {
            m.Result = (IntPtr)HTCLIENT;
            return;
        }
        if (m.Msg == WM_SYSCOMMAND) {
            int cmd = m.WParam.ToInt32() & 0xFFF0;
            if (cmd == SC_MINIMIZE) {
                return;
            }
        }
        if (m.Msg == WM_SHOWWINDOW && m.WParam == IntPtr.Zero) {
            if (m.LParam.ToInt32() != 0) {
                return;
            }
        }
        if (m.Msg == WM_WINDOWPOSCHANGING) {
            WINDOWPOS pos = (WINDOWPOS)Marshal.PtrToStructure(m.LParam, typeof(WINDOWPOS));
            if ((pos.flags & SWP_HIDEWINDOW) != 0) {
                pos.flags &= ~SWP_HIDEWINDOW;
                Marshal.StructureToPtr(pos, m.LParam, true);
            }
        }
        base.WndProc(ref m);
    }
}

public static class DesktopLogger {
    private static string _logPath = "";
    private static readonly object _lock = new object();

    public static void Initialize(string path) {
        _logPath = path;
    }

    public static void Log(string message, string level = "INFO") {
        if (string.IsNullOrEmpty(_logPath)) return;
        try {
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            string line = string.Format("[{0}] [{1}] {2}\r\n", timestamp, level, message);
            lock (_lock) {
                File.AppendAllText(_logPath, line, Encoding.UTF8);
            }
        } catch { }
    }

    public static void LogException(Exception ex, string message = "Exception encountered", string level = "ERROR") {
        if (string.IsNullOrEmpty(_logPath) || ex == null) return;
        try {
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("[{0}] [{1}] {2}\r\n", timestamp, level, message);
            sb.AppendFormat("  [EXCEPTION TYPE] {0}\r\n", ex.GetType().FullName);
            sb.AppendFormat("  [EXCEPTION MSG]  {0}\r\n", ex.Message);
            sb.AppendFormat("  [STACK TRACE]   {0}\r\n", ex.StackTrace);
            if (ex.InnerException != null) {
                sb.AppendFormat("  [INNER TYPE]    {0}\r\n", ex.InnerException.GetType().FullName);
                sb.AppendFormat("  [INNER MSG]     {0}\r\n", ex.InnerException.Message);
                sb.AppendFormat("  [INNER STACK]   {0}\r\n", ex.InnerException.StackTrace);
            }
            lock (_lock) {
                File.AppendAllText(_logPath, sb.ToString(), Encoding.UTF8);
            }
        } catch { }
    }
}

public class WpfVideoWallpaperHost : System.Windows.Forms.Integration.ElementHost {
    private System.Windows.Controls.MediaElement _media;
    private System.Windows.Controls.Grid _grid;
    private IntPtr _targetHwnd = IntPtr.Zero;

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    public WpfVideoWallpaperHost(string videoPath, bool isMuted, IntPtr targetHwnd) {
        _targetHwnd = targetHwnd;
        this.Dock = DockStyle.Fill;
        this.BackColor = Color.Black;
        
        _grid = new System.Windows.Controls.Grid();
        _grid.Background = System.Windows.Media.Brushes.Black;
        _grid.IsHitTestVisible = true;

        _media = new System.Windows.Controls.MediaElement();
        _media.LoadedBehavior = System.Windows.Controls.MediaState.Manual;
        _media.UnloadedBehavior = System.Windows.Controls.MediaState.Manual;
        _media.IsMuted = isMuted;
        _media.Stretch = System.Windows.Media.Stretch.UniformToFill;
        _media.IsHitTestVisible = false;
        _media.MediaEnded += (s, e) => {
            _media.Position = TimeSpan.Zero;
            _media.Play();
        };

        _grid.MouseLeftButtonDown += (s, e) => {
            if (_targetHwnd != IntPtr.Zero) {
                var p = e.GetPosition(_grid);
                int lParam = ((int)p.Y << 16) | ((int)p.X & 0xFFFF);
                if (e.ClickCount == 2) {
                    PostMessage(_targetHwnd, 0x0203, IntPtr.Zero, (IntPtr)lParam); // WM_LBUTTONDBLCLK
                } else {
                    PostMessage(_targetHwnd, 0x0201, IntPtr.Zero, (IntPtr)lParam); // WM_LBUTTONDOWN
                }
            }
        };
        _grid.MouseLeftButtonUp += (s, e) => {
            if (_targetHwnd != IntPtr.Zero) {
                var p = e.GetPosition(_grid);
                int lParam = ((int)p.Y << 16) | ((int)p.X & 0xFFFF);
                PostMessage(_targetHwnd, 0x0202, IntPtr.Zero, (IntPtr)lParam); // WM_LBUTTONUP
            }
        };
        _grid.MouseRightButtonUp += (s, e) => {
            if (_targetHwnd != IntPtr.Zero) {
                var p = e.GetPosition(_grid);
                int lParam = ((int)p.Y << 16) | ((int)p.X & 0xFFFF);
                PostMessage(_targetHwnd, 0x0205, IntPtr.Zero, (IntPtr)lParam); // WM_RBUTTONUP
            }
        };
        _grid.MouseMove += (s, e) => {
            if (_targetHwnd != IntPtr.Zero) {
                var p = e.GetPosition(_grid);
                int lParam = ((int)p.Y << 16) | ((int)p.X & 0xFFFF);
                PostMessage(_targetHwnd, 0x0200, IntPtr.Zero, (IntPtr)lParam); // WM_MOUSEMOVE
            }
        };

        if (!string.IsNullOrEmpty(videoPath) && File.Exists(videoPath)) {
            _media.Source = new Uri(videoPath, UriKind.Absolute);
        }
        _grid.Children.Add(_media);
        this.Child = _grid;
        _media.Play();
    }

    protected override void OnResize(EventArgs e) {
        base.OnResize(e);
        if (_grid != null) {
            _grid.Width = this.ClientSize.Width;
            _grid.Height = this.ClientSize.Height;
        }
    }

    public void StopPlayback() {
        if (_media != null) {
            try {
                _media.Stop();
                _media.Close();
            } catch { }
        }
    }
}

public class VideoWallpaperForm : Form {
    private WpfVideoWallpaperHost _host;
    private const int WS_EX_NOACTIVATE = 0x08000000;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    private const int WM_MOUSEACTIVATE = 0x0021;
    private const int MA_NOACTIVATE = 3;
    private IntPtr _targetHwnd = IntPtr.Zero;

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW;
            return cp;
        }
    }

    protected override bool ShowWithoutActivation {
        get { return true; }
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_MOUSEACTIVATE) {
            m.Result = (IntPtr)MA_NOACTIVATE;
            return;
        }
        // Forward all mouse events (0x0200 = WM_MOUSEMOVE, to 0x020A = WM_MOUSEWHEEL) to the primary CustomDesktopForm
        if (m.Msg >= 0x0200 && m.Msg <= 0x020A) {
            if (_targetHwnd != IntPtr.Zero) {
                PostMessage(_targetHwnd, (uint)m.Msg, m.WParam, m.LParam);
                m.Result = IntPtr.Zero;
                return;
            }
        }
        base.WndProc(ref m);
    }

    public VideoWallpaperForm(string videoPath, Point location, Size size, bool isMuted, IntPtr targetHwnd) {
        _targetHwnd = targetHwnd;
        this.FormBorderStyle = FormBorderStyle.None;
        this.StartPosition = FormStartPosition.Manual;
        this.Location = location;
        this.Size = size;
        this.Bounds = new Rectangle(location, size);
        this.BackColor = Color.Black;
        this.ShowInTaskbar = false;
        this.Text = "RedSkia Video Wallpaper Engine";
        
        _host = new WpfVideoWallpaperHost(videoPath, isMuted, targetHwnd);
        _host.Dock = DockStyle.Fill;
        this.Controls.Add(_host);
    }

    public void StopAndClose() {
        if (_host != null) {
            _host.StopPlayback();
            try { this.Controls.Remove(_host); } catch { }
            _host.Dispose();
            _host = null;
        }
        try { this.Close(); this.Dispose(); } catch { }
    }
}

public static class LiveWallpaperEngine {
    private static Image _gifImage = null;
    private static bool _isGifAnimating = false;
    private static List<Form> _targetForms = new List<Form>();
    private static List<VideoWallpaperForm> _videoForms = new List<VideoWallpaperForm>();
    private static bool _isVideoActive = false;

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    public static bool IsGif(string path) {
        if (string.IsNullOrEmpty(path)) return false;
        string ext = Path.GetExtension(path).ToLowerInvariant();
        return ext == ".gif" || ext == ".webp";
    }

    public static bool IsVideo(string path) {
        if (string.IsNullOrEmpty(path)) return false;
        string ext = Path.GetExtension(path).ToLowerInvariant();
        return ext == ".mp4" || ext == ".wmv" || ext == ".avi" || ext == ".mov" || ext == ".mkv" || ext == ".webm" || ext == ".flv" || ext == ".m4v" || ext == ".mpg" || ext == ".mpeg" || ext == ".3gp" || ext == ".ts";
    }

    public static bool IsMediaFile(string path) {
        return IsGif(path) || IsVideo(path);
    }

    public static bool IsGifActive {
        get { return _isGifAnimating && _gifImage != null; }
    }

    public static bool IsVideoActive {
        get { return _isVideoActive && _videoForms.Count > 0; }
    }

    public static Image CurrentGifImage {
        get { return _gifImage; }
    }

    public static void StartGifAnimation(Image img, List<Form> forms) {
        StopGifAnimation();
        if (img == null || forms == null || forms.Count == 0) return;
        
        try {
            if (ImageAnimator.CanAnimate(img)) {
                _gifImage = img;
                _targetForms.Clear();
                _targetForms.AddRange(forms);
                _isGifAnimating = true;
                ImageAnimator.Animate(_gifImage, new EventHandler(OnFrameChanged));
            }
        } catch { }
    }

    private static void OnFrameChanged(object sender, EventArgs e) {
        if (_isGifAnimating && _gifImage != null) {
            try {
                ImageAnimator.UpdateFrames(_gifImage);
                foreach (Form f in _targetForms) {
                    if (f != null && !f.IsDisposed) {
                        if (f.InvokeRequired) {
                            f.BeginInvoke(new Action(() => { f.Invalidate(); }));
                        } else {
                            f.Invalidate();
                        }
                    }
                }
            } catch { }
        }
    }

    public static void StopGifAnimation() {
        if (_isGifAnimating && _gifImage != null) {
            try {
                ImageAnimator.StopAnimate(_gifImage, new EventHandler(OnFrameChanged));
            } catch { }
        }
        _isGifAnimating = false;
        _gifImage = null;
        _targetForms.Clear();
    }

    public static void StartVideoWallpaper(string videoPath, List<Form> desktopForms, bool mute) {
        StopAllVideos();
        if (string.IsNullOrEmpty(videoPath) || !File.Exists(videoPath) || desktopForms == null) return;
        try {
            _isVideoActive = true;
            foreach (Form df in desktopForms) {
                if (df != null && !df.IsDisposed) {
                    VideoWallpaperForm vf = new VideoWallpaperForm(videoPath, df.Location, df.Size, mute, df.Handle);
                    vf.Show();
                    // Place video form at the very bottom (HWND_BOTTOM = 1, SWP_NOACTIVATE = 0x0010)
                    SetWindowPos(vf.Handle, new IntPtr(1), 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0040 | 0x0010);
                    _videoForms.Add(vf);

                    // Ensure desktop form is on top and focused
                    SetWindowPos(df.Handle, new IntPtr(0), 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0040);
                    df.BringToFront();
                }
            }
        } catch { }
    }

    public static void StopAllVideos() {
        _isVideoActive = false;
        try {
            foreach (VideoWallpaperForm vf in _videoForms) {
                if (vf != null && !vf.IsDisposed) {
                    vf.StopAndClose();
                }
            }
            _videoForms.Clear();
        } catch { }
    }
}

public class FakeWindowsUpdateForm : Form {
    private Timer _animTimer;
    private int _frame = 0;
    private int _percent = 27;
    private int _pctTick = 0;
    private bool _isPrimary = true;
    private static List<FakeWindowsUpdateForm> _activeScreens = new List<FakeWindowsUpdateForm>();
    public static bool IsActive = false;

    public static void ShowUpdateScreens() {
        CloseUpdateScreens();
        try {
            IsActive = true;
            Cursor.Hide();
            foreach (Screen s in Screen.AllScreens) {
                FakeWindowsUpdateForm f = new FakeWindowsUpdateForm(s.Bounds, s.Primary);
                _activeScreens.Add(f);
                f.Show();
                f.BringToFront();
                SetForegroundWindow(f.Handle);
            }
        } catch { }
    }

    public static void CloseUpdateScreens() {
        try {
            IsActive = false;
            Cursor.Show();
            foreach (FakeWindowsUpdateForm f in _activeScreens) {
                if (f != null && !f.IsDisposed) {
                    try { f.Close(); f.Dispose(); } catch { }
                }
            }
            _activeScreens.Clear();
        } catch { }
    }

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    public FakeWindowsUpdateForm(Rectangle bounds, bool isPrimary) {
        this.FormBorderStyle = FormBorderStyle.None;
        this.StartPosition = FormStartPosition.Manual;
        this.Bounds = bounds;
        this.BackColor = Color.Black;
        this.DoubleBuffered = true;
        this.TopMost = true;
        this.KeyPreview = true;
        this.ShowInTaskbar = false;
        this._isPrimary = isPrimary;

        if (_isPrimary) {
            _animTimer = new Timer();
            _animTimer.Interval = 20;
            _animTimer.Tick += (s, e) => {
                _frame++;
                _pctTick++;
                if (_pctTick > 120) {
                    _pctTick = 0;
                    if (_percent < 99) {
                        _percent += new Random().Next(1, 4);
                    }
                }
                this.Invalidate();
            };
            _animTimer.Start();
        }
    }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        if (!_isPrimary) return;

        Graphics g = e.Graphics;
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        int cx = this.ClientSize.Width / 2;
        int cy = (this.ClientSize.Height / 2) - 50;

        // Authentic Microsoft Windows 11 Fluent ProgressRing Spline
        int numDots = 5;
        double radius = 28.0;
        double cyclePeriod = 190.0;
        float dotSize = 5.2f;

        using (SolidBrush dotBrush = new SolidBrush(Color.White)) {
            for (int i = 0; i < numDots; i++) {
                double rawTime = ((_frame - (i * 9)) % cyclePeriod) / cyclePeriod;
                if (rawTime < 0) rawTime += 1.0;

                double angleDeg;
                if (rawTime < 0.22) {
                    double local = rawTime / 0.22;
                    angleDeg = 180.0 * (local * local * local);
                } else if (rawTime < 0.58) {
                    double local = (rawTime - 0.22) / 0.36;
                    angleDeg = 180.0 + 180.0 * Math.Sin(local * (Math.PI / 2.0));
                } else if (rawTime < 0.82) {
                    double local = (rawTime - 0.58) / 0.24;
                    angleDeg = 360.0 + 180.0 * (local * local);
                } else {
                    double local = (rawTime - 0.82) / 0.18;
                    angleDeg = 540.0 + 180.0 * (1.0 - Math.Cos(local * (Math.PI / 2.0)));
                }

                double angleRad = (angleDeg - 90.0) * (Math.PI / 180.0);
                float dotX = (float)(cx + radius * Math.Cos(angleRad));
                float dotY = (float)(cy + radius * Math.Sin(angleRad));

                g.FillEllipse(dotBrush, dotX - (dotSize / 2f), dotY - (dotSize / 2f), dotSize, dotSize);
            }
        }

        // Authentic Windows System Font Selection
        string fontName = "Segoe UI Variable Display";
        bool hasVarFont = false;
        foreach (FontFamily ff in FontFamily.Families) {
            if (ff.Name.Equals("Segoe UI Variable Display", StringComparison.OrdinalIgnoreCase)) {
                hasVarFont = true;
                break;
            }
        }
        if (!hasVarFont) fontName = "Segoe UI";

        using (Font titleFont = new Font(fontName, 22f, FontStyle.Regular))
        using (Font pctFont = new Font("Segoe UI", 14f, FontStyle.Regular))
        using (Font subFont = new Font("Segoe UI", 10.5f, FontStyle.Regular))
        using (Font sub2Font = new Font("Segoe UI", 9.5f, FontStyle.Regular))
        using (SolidBrush textBrush = new SolidBrush(Color.White))
        using (SolidBrush grayBrush = new SolidBrush(Color.FromArgb(215, 215, 215)))
        using (SolidBrush dimBrush = new SolidBrush(Color.FromArgb(160, 160, 160)))
        using (StringFormat sf = new StringFormat()) {
            sf.Alignment = StringAlignment.Center;
            sf.LineAlignment = StringAlignment.Center;

            g.DrawString("Working on updates", titleFont, textBrush, cx, cy + 65, sf);
            g.DrawString(_percent + "% complete", pctFont, textBrush, cx, cy + 105, sf);
            g.DrawString("Please keep your computer on and plugged in.", subFont, grayBrush, cx, cy + 145, sf);
            g.DrawString("Your device might restart several times.", sub2Font, dimBrush, cx, cy + 175, sf);
        }
    }

    protected override void Dispose(bool disposing) {
        if (disposing && _animTimer != null) {
            _animTimer.Stop();
            _animTimer.Dispose();
            _animTimer = null;
        }
        base.Dispose(disposing);
    }
}

public class DesktopWidgetRenderer {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private class MEMORYSTATUSEX {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
        public MEMORYSTATUSEX() { this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)); }
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

    private static float _cachedFreeGB = 0;
    private static float _cachedTotalGB = 0;
    private static int _cachedDiskPct = 0;
    private static int _lastDiskQueryTick = 0;

    public static void DrawWidget(Graphics g, Rectangle bounds, float uiScale, bool showClock, bool showSys, bool showDisk) {
        g.SmoothingMode = SmoothingMode.AntiAlias;

        using (GraphicsPath path = GetRoundedRect(bounds, (int)(12 * uiScale))) {
            using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(170, 11, 15, 25))) {
                g.FillPath(bgBrush, path);
            }
            using (Pen borderPen = new Pen(Color.FromArgb(45, 255, 255, 255), 1.5f)) {
                g.DrawPath(borderPen, path);
            }
        }

        int currY = bounds.Y + (int)(14 * uiScale);
        int padX = bounds.X + (int)(16 * uiScale);
        int innerWidth = bounds.Width - (int)(32 * uiScale);

        if (showClock) {
            DateTime now = DateTime.Now;
            string timeStr = now.ToString("HH:mm");
            string secStr = ":" + now.ToString("ss");
            string dateStr = now.ToString("dddd, MMMM d, yyyy");

            using (Font timeFont = new Font("Segoe UI", 20f * uiScale, FontStyle.Bold))
            using (Font secFont = new Font("Segoe UI", 11f * uiScale, FontStyle.Regular))
            using (Font dateFont = new Font("Segoe UI", 9f * uiScale, FontStyle.Regular))
            using (SolidBrush whiteBrush = new SolidBrush(Color.White))
            using (SolidBrush mutedBrush = new SolidBrush(Color.FromArgb(200, 203, 213, 225))) {
                SizeF timeSize = g.MeasureString(timeStr, timeFont);
                g.DrawString(timeStr, timeFont, whiteBrush, padX, currY);
                g.DrawString(secStr, secFont, mutedBrush, padX + timeSize.Width - 5, currY + (int)(9 * uiScale));
                currY += (int)(timeSize.Height * 0.85f);
                g.DrawString(dateStr, dateFont, mutedBrush, padX, currY);
                currY += (int)(22 * uiScale);
            }
        }

        if ((showClock && showSys) || (showClock && showDisk)) {
            using (Pen divPen = new Pen(Color.FromArgb(30, 255, 255, 255), 1f)) {
                g.DrawLine(divPen, padX, currY, padX + innerWidth, currY);
            }
            currY += (int)(10 * uiScale);
        }

        if (showSys) {
            MEMORYSTATUSEX mem = new MEMORYSTATUSEX();
            if (GlobalMemoryStatusEx(mem)) {
                ulong totalMB = mem.ullTotalPhys / (1024 * 1024);
                ulong availMB = mem.ullAvailPhys / (1024 * 1024);
                ulong usedMB = totalMB - availMB;
                int ramPct = (int)mem.dwMemoryLoad;

                float usedGB = (float)Math.Round((double)usedMB / 1024.0, 1);
                float totalGB = (float)Math.Round((double)totalMB / 1024.0, 1);

                using (Font lblFont = new Font("Segoe UI", 8.5f * uiScale, FontStyle.Bold))
                using (Font valFont = new Font("Segoe UI", 8f * uiScale, FontStyle.Regular))
                using (SolidBrush lblBrush = new SolidBrush(Color.White))
                using (SolidBrush valBrush = new SolidBrush(Color.FromArgb(160, 255, 255, 255))) {
                    g.DrawString("RAM MEMORY", lblFont, lblBrush, padX, currY);
                    string ramText = string.Format("{0} GB / {1} GB ({2}%)", usedGB, totalGB, ramPct);
                    SizeF valSize = g.MeasureString(ramText, valFont);
                    g.DrawString(ramText, valFont, valBrush, padX + innerWidth - valSize.Width, currY + 1);
                    currY += (int)(18 * uiScale);

                    int barH = (int)(6 * uiScale);
                    using (GraphicsPath barTrack = GetRoundedRect(new Rectangle(padX, currY, innerWidth, barH), 3))
                    using (SolidBrush trackBrush = new SolidBrush(Color.FromArgb(40, 255, 255, 255))) {
                        g.FillPath(trackBrush, barTrack);
                    }
                    int fillW = Math.Max(4, (int)(innerWidth * (ramPct / 100.0f)));
                    using (GraphicsPath barFill = GetRoundedRect(new Rectangle(padX, currY, fillW, barH), 3))
                    using (LinearGradientBrush fillBrush = new LinearGradientBrush(new Rectangle(padX, currY, innerWidth, barH), Color.FromArgb(59, 130, 246), Color.FromArgb(147, 51, 234), LinearGradientMode.Horizontal)) {
                        g.FillPath(fillBrush, barFill);
                    }
                    currY += (int)(14 * uiScale);
                }
            }
        }

        if (showDisk) {
            try {
                int nowTick = Environment.TickCount;
                if (_lastDiskQueryTick == 0 || Math.Abs(nowTick - _lastDiskQueryTick) > 10000) {
                    _lastDiskQueryTick = nowTick;
                    DriveInfo drive = new DriveInfo("C");
                    if (drive.IsReady) {
                        _cachedFreeGB = (float)Math.Round(drive.AvailableFreeSpace / (1024.0 * 1024.0 * 1024.0), 0);
                        _cachedTotalGB = (float)Math.Round(drive.TotalSize / (1024.0 * 1024.0 * 1024.0), 0);
                        float usedGB = _cachedTotalGB - _cachedFreeGB;
                        _cachedDiskPct = (int)((usedGB / _cachedTotalGB) * 100.0f);
                    }
                }

                if (_cachedTotalGB > 0) {
                    using (Font lblFont = new Font("Segoe UI", 8.5f * uiScale, FontStyle.Bold))
                    using (Font valFont = new Font("Segoe UI", 8f * uiScale, FontStyle.Regular))
                    using (SolidBrush lblBrush = new SolidBrush(Color.White))
                    using (SolidBrush valBrush = new SolidBrush(Color.FromArgb(160, 255, 255, 255))) {
                        g.DrawString("LOCAL DISK (C:)", lblFont, lblBrush, padX, currY);
                        string diskText = string.Format("{0} GB free / {1} GB", _cachedFreeGB, _cachedTotalGB);
                        SizeF valSize = g.MeasureString(diskText, valFont);
                        g.DrawString(diskText, valFont, valBrush, padX + innerWidth - valSize.Width, currY + 1);
                        currY += (int)(18 * uiScale);

                        int barH = (int)(6 * uiScale);
                        using (GraphicsPath barTrack = GetRoundedRect(new Rectangle(padX, currY, innerWidth, barH), 3))
                        using (SolidBrush trackBrush = new SolidBrush(Color.FromArgb(40, 255, 255, 255))) {
                            g.FillPath(trackBrush, barTrack);
                        }
                        int fillW = Math.Max(4, (int)(innerWidth * (_cachedDiskPct / 100.0f)));
                        using (GraphicsPath barFill = GetRoundedRect(new Rectangle(padX, currY, fillW, barH), 3))
                        using (LinearGradientBrush fillBrush = new LinearGradientBrush(new Rectangle(padX, currY, innerWidth, barH), Color.FromArgb(16, 185, 129), Color.FromArgb(59, 130, 246), LinearGradientMode.Horizontal)) {
                            g.FillPath(fillBrush, barFill);
                        }
                    }
                }
            } catch { }
        }
    }

    private static GraphicsPath GetRoundedRect(Rectangle r, int radius) {
        GraphicsPath path = new GraphicsPath();
        if (radius <= 0) { path.AddRectangle(r); return path; }
        int d = radius * 2;
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}

public class WinDInterceptor : IDisposable {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int WM_SYSKEYUP = 0x0105;
    private const int VK_D = 0x44;
    private const int VK_M = 0x4D;
    private const int VK_LWIN = 0x5B;
    private const int VK_RWIN = 0x5C;
    private const int VK_SHIFT = 0x10;
    private const int VK_CONTROL = 0x11;
    private const int VK_MENU = 0x12;
    private const int VK_VOLUME_MUTE = 0xAD;
    private const uint KEYEVENTF_KEYUP = 0x0002;
    private const int SW_HIDE = 0;
    private const int SW_SHOWMAXIMIZED = 3;
    private const int SW_SHOW = 5;
    private const int SW_MINIMIZE = 6;
    private const int SW_RESTORE = 9;

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    public delegate void KeyRecordedHandler(uint vk, bool ctrl, bool alt, bool shift, bool win, string name);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);

    [DllImport("user32.dll")]
    private static extern IntPtr GetShellWindow();

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    private static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
    private static readonly IntPtr HWND_BOTTOM = new IntPtr(1);
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_SHOWWINDOW = 0x0040;

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern void SwitchToThisWindow(IntPtr hWnd, bool fUnknown);

    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    // Boss Key Config & State
    public static bool BossKeyEnabled = true;
    public static uint BossKeyVk = 0x7B; // VK_F12
    public static bool BossKeyRequireCtrl = false;
    public static bool BossKeyRequireAlt = false;
    public static bool BossKeyRequireShift = false;
    public static bool BossKeyRequireWin = false;
    public static bool BossHideTaskbar = true;
    public static bool BossMuteAudio = true;
    public static bool BossDecoyEnabled = false;
    public static string BossDecoyPreset = "Windows 11 Update Screen (Fake Stealth Screen)";
    public static string BossDecoyPath = "notepad.exe";
    public static bool BossDecoyPrewarm = true;
    public static bool BossDecoyCloseOnRestore = true;
    public static bool IsBossModeActive = false;

    // Interactive Key Recorder Supremacy
    public static bool IsRecordingKey = false;
    public static KeyRecordedHandler OnKeyRecorded = null;
    public static Action OnOpenSettingsRequested = null;

    private static List<IntPtr> _hiddenBossWindows = new List<IntPtr>();
    private static List<IntPtr> _hiddenTaskbars = new List<IntPtr>();
    private static List<IntPtr> _minimizedByWinD = new List<IntPtr>();
    private static List<Process> _spawnedDecoys = new List<Process>();

    private static Process _prewarmedProcess = null;
    private static IntPtr _prewarmedHwnd = IntPtr.Zero;
    private static string _prewarmedPath = "";

    private static IntPtr _hookId = IntPtr.Zero;
    private static LowLevelKeyboardProc _proc;
    private static GCHandle _procHandle;

    public WinDInterceptor() {
        EnsureHookActive();
    }

    public static string FormatKeyName(uint vk, bool ctrl, bool alt, bool shift, bool win) {
        string baseName = "";
        if (vk == 0x5B || vk == 0x5C) baseName = "Windows Key";
        else if (vk >= 0x70 && vk <= 0x87) baseName = "F" + (vk - 0x6F);
        else if (vk == 0x13) baseName = "Pause";
        else if (vk == 0x2C) baseName = "PrintScreen";
        else if (vk == 0x91) baseName = "ScrollLock";
        else if (vk == 0x14) baseName = "CapsLock";
        else if (vk == 0x90) baseName = "NumLock";
        else if (vk == 0x5D) baseName = "Apps";
        else if (vk == 0x1B) baseName = "Escape";
        else if (vk == 0x20) baseName = "Space";
        else if (vk == 0x09) baseName = "Tab";
        else if (vk == 0x2D) baseName = "Insert";
        else if (vk == 0x2E) baseName = "Delete";
        else if (vk == 0x24) baseName = "Home";
        else if (vk == 0x23) baseName = "End";
        else if (vk == 0x21) baseName = "PageUp";
        else if (vk == 0x22) baseName = "PageDown";
        else if (vk >= 0x30 && vk <= 0x39) baseName = ((char)('0' + (vk - 0x30))).ToString();
        else if (vk >= 0x41 && vk <= 0x5A) baseName = ((char)('A' + (vk - 0x41))).ToString();
        else if (vk >= 0x60 && vk <= 0x69) baseName = "Num " + (vk - 0x60);
        else if (vk == 0x6A) baseName = "Num *";
        else if (vk == 0x6B) baseName = "Num +";
        else if (vk == 0x6D) baseName = "Num -";
        else if (vk == 0x6E) baseName = "Num .";
        else if (vk == 0x6F) baseName = "Num /";
        else {
            try {
                Keys k = (Keys)vk;
                baseName = k.ToString();
            } catch {
                baseName = "VK_0x" + vk.ToString("X2");
            }
        }

        string result = "";
        if (ctrl && vk != 0x11 && vk != 0xA2 && vk != 0xA3) result += "Ctrl + ";
        if (alt && vk != 0x12 && vk != 0xA4 && vk != 0xA5) result += "Alt + ";
        if (shift && vk != 0x10 && vk != 0xA0 && vk != 0xA1) result += "Shift + ";
        if (win && vk != 0x5B && vk != 0x5C) result += "Win + ";
        result += baseName;
        return result;
    }

    public static void EnsureHookActive() {
        try {
            if (_hookId == IntPtr.Zero) {
                _proc = HookCallback;
                _procHandle = GCHandle.Alloc(_proc);
                using (Process curProcess = Process.GetCurrentProcess())
                using (ProcessModule curModule = curProcess.MainModule) {
                    _hookId = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
                }
            }
        } catch { }
    }

    public static void PrewarmDecoyApp() {
        if (!BossDecoyEnabled || string.IsNullOrEmpty(BossDecoyPath) || !BossDecoyPrewarm || BossDecoyPath.IndexOf("Update", StringComparison.OrdinalIgnoreCase) >= 0 || BossDecoyPath == "FakeWindowsUpdate") {
            return;
        }
        try {
            string exeName = "";
            try { exeName = System.IO.Path.GetFileNameWithoutExtension(BossDecoyPath).ToLower(); } catch { }

            // 1. If we already have a valid prewarmed HWND for this path, ensure it's hidden and return
            if (_prewarmedHwnd != IntPtr.Zero && IsWindow(_prewarmedHwnd) && _prewarmedPath == BossDecoyPath) {
                if (!IsBossModeActive) {
                    ShowWindow(_prewarmedHwnd, SW_HIDE);
                }
                return;
            }

            // 2. Check if a process of this name is ALREADY running on the system
            if (!string.IsNullOrEmpty(exeName)) {
                try {
                    Process[] running = Process.GetProcessesByName(exeName);
                    if (running != null && running.Length > 0) {
                        _prewarmedProcess = running[0];
                        _prewarmedPath = BossDecoyPath;
                        EnumWindows((w, l) => {
                            uint pid;
                            GetWindowThreadProcessId(w, out pid);
                            foreach (Process p in running) {
                                if (p.Id == (int)pid && IsWindow(w) && IsWindowVisible(w)) {
                                    _prewarmedHwnd = w;
                                    if (!IsBossModeActive) {
                                        ShowWindow(w, SW_HIDE);
                                    }
                                    return false;
                                }
                            }
                            return true;
                        }, IntPtr.Zero);

                        if (_prewarmedHwnd != IntPtr.Zero) {
                            return; // Captured already running instance! Do not spawn a new one!
                        }
                    }
                } catch { }
            }

            // 3. Otherwise, spawn single instance
            _prewarmedPath = BossDecoyPath;
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = BossDecoyPath;
            psi.UseShellExecute = true;
            psi.WindowStyle = ProcessWindowStyle.Minimized;
            psi.WorkingDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            _prewarmedProcess = Process.Start(psi);

            if (_prewarmedProcess != null) {
                System.Threading.ThreadPool.QueueUserWorkItem((state) => {
                    try {
                        for (int i = 0; i < 60; i++) {
                            System.Threading.Thread.Sleep(50);
                            IntPtr h = IntPtr.Zero;
                            if (_prewarmedProcess != null) {
                                try { h = _prewarmedProcess.MainWindowHandle; } catch { }
                            }
                            
                            if (h == IntPtr.Zero && !string.IsNullOrEmpty(exeName)) {
                                try {
                                    Process[] procs = Process.GetProcessesByName(exeName);
                                    if (procs != null && procs.Length > 0) {
                                        EnumWindows((w, l) => {
                                            uint pid;
                                            GetWindowThreadProcessId(w, out pid);
                                            foreach (Process p in procs) {
                                                if (p.Id == (int)pid && IsWindow(w) && IsWindowVisible(w)) {
                                                    h = w;
                                                    return false;
                                                }
                                            }
                                            return true;
                                        }, IntPtr.Zero);
                                    }
                                } catch { }
                            }

                            if (h != IntPtr.Zero && IsWindow(h)) {
                                _prewarmedHwnd = h;
                                if (!IsBossModeActive) {
                                    ShowWindow(h, SW_HIDE);
                                }
                                break;
                            }
                        }
                    } catch { }
                });
            }
        } catch { }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        try {
            if (nCode >= 0) {
                KBDLLHOOKSTRUCT kb = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
                int msg = wParam.ToInt32();
                bool isKeyDown = (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN);
                bool isKeyUp   = (msg == WM_KEYUP || msg == WM_SYSKEYUP);

                // Hardware-Level Key Recording Interception
                if (IsRecordingKey) {
                    if (isKeyDown) {
                        bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
                        bool alt  = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 || ((kb.flags & 0x20) != 0);
                        bool shift= (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
                        bool win  = (GetAsyncKeyState(VK_LWIN) & 0x8000) != 0 || (GetAsyncKeyState(VK_RWIN) & 0x8000) != 0;
                        uint vk   = kb.vkCode;

                        // Ignore solitary modifier keypresses unless it's a standalone Windows Key or Menu key
                        if (vk == 0x11 || vk == 0xA2 || vk == 0xA3 || vk == 0x10 || vk == 0xA0 || vk == 0xA1 || vk == 0x12 || vk == 0xA4 || vk == 0xA5) {
                            return (IntPtr)1; // Swallow modifier while recording combo
                        }

                        string name = FormatKeyName(vk, ctrl, alt, shift, win);
                        IsRecordingKey = false;
                        if (OnKeyRecorded != null) {
                            OnKeyRecorded(vk, ctrl, alt, shift, win, name);
                        }
                    }
                    return (IntPtr)1; // Swallow all keys during recording!
                }

                // 1. Ultra-Aggressive Global Boss Key Override
                if (BossKeyEnabled) {
                    bool vkMatch = false;
                    if (BossKeyVk == VK_LWIN || BossKeyVk == VK_RWIN) {
                        vkMatch = (kb.vkCode == VK_LWIN || kb.vkCode == VK_RWIN);
                    } else {
                        vkMatch = (kb.vkCode == BossKeyVk);
                    }

                    if (vkMatch) {
                        bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
                        bool alt  = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 || ((kb.flags & 0x20) != 0);
                        bool shift= (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
                        bool win  = (GetAsyncKeyState(VK_LWIN) & 0x8000) != 0 || (GetAsyncKeyState(VK_RWIN) & 0x8000) != 0;

                        bool modMatch = (ctrl == BossKeyRequireCtrl) && (alt == BossKeyRequireAlt) && (shift == BossKeyRequireShift);
                        if (BossKeyVk != VK_LWIN && BossKeyVk != VK_RWIN) {
                            modMatch = modMatch && (win == BossKeyRequireWin);
                        }

                        if (modMatch) {
                            if (isKeyDown) {
                                ToggleBossMode();
                            }
                            return (IntPtr)1; // Absolute supremacy: Swallow BOTH KeyDown & KeyUp completely!
                        }
                    }
                }

                // If Fake Windows Update is active, LOCK DOWN ALL OTHER KEYBOARD INPUT!
                if (IsBossModeActive && FakeWindowsUpdateForm.IsActive) {
                    return (IntPtr)1; // Complete keyboard block so nothing breaks the update illusion!
                }

                // 2. Check Win+D / Win+M
                if (isKeyDown && (kb.vkCode == VK_D || kb.vkCode == VK_M)) {
                    bool winDown = ((GetAsyncKeyState(VK_LWIN) & 0x8000) != 0) || ((GetAsyncKeyState(VK_RWIN) & 0x8000) != 0);
                    if (winDown) {
                        ToggleDesktop();
                        return (IntPtr)1;
                    }
                }

                // 3. Global Ctrl+P or F8 to open Settings
                if (isKeyDown) {
                    bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
                    if ((ctrl && (kb.vkCode == 0x50 || kb.vkCode == 0x70)) || kb.vkCode == 0x77) { // 0x50 is 'P', 0x77 is F8
                        if (OnOpenSettingsRequested != null) {
                            OnOpenSettingsRequested();
                            return (IntPtr)1;
                        }
                    }
                }
            }
        } catch { }
        return CallNextHookEx(_hookId, nCode, wParam, lParam);
    }

    public static void ToggleBossMode() {
        try {
            IntPtr shellHwnd = GetShellWindow();
            IntPtr progmanHwnd = FindWindow("Progman", null);

            if (!IsBossModeActive) {
                IsBossModeActive = true;
                DesktopLogger.Log("BOSS KEY TRIGGERED: Activating Stealth Panic Mode...", "STEALTH");
                _hiddenBossWindows.Clear();
                _hiddenTaskbars.Clear();

                // 1. Hide Windows Taskbars (Primary & Secondary Multi-Monitor)
                if (BossHideTaskbar) {
                    IntPtr primaryTray = FindWindow("Shell_TrayWnd", null);
                    if (primaryTray != IntPtr.Zero && IsWindowVisible(primaryTray)) {
                        ShowWindow(primaryTray, SW_HIDE);
                        _hiddenTaskbars.Add(primaryTray);
                    }

                    IntPtr secTray = IntPtr.Zero;
                    while ((secTray = FindWindowEx(IntPtr.Zero, secTray, "Shell_SecondaryTrayWnd", null)) != IntPtr.Zero) {
                        if (IsWindowVisible(secTray)) {
                            ShowWindow(secTray, SW_HIDE);
                            _hiddenTaskbars.Add(secTray);
                        }
                    }
                    DesktopLogger.Log(string.Format("Stealth Mode: {0} taskbar windows hidden.", _hiddenTaskbars.Count), "STEALTH");
                }

                // 2. Hide Top-Level Windows
                EnumWindows((hWnd, lParam) => {
                    if (hWnd != shellHwnd && hWnd != progmanHwnd && !CustomDesktopForm.DesktopHwnds.Contains(hWnd) && IsWindowVisible(hWnd)) {
                        if (hWnd != _prewarmedHwnd) {
                            ShowWindow(hWnd, SW_HIDE);
                            _hiddenBossWindows.Add(hWnd);
                        }
                    }
                    return true;
                }, IntPtr.Zero);
                DesktopLogger.Log(string.Format("Stealth Mode: {0} top-level application windows hidden.", _hiddenBossWindows.Count), "STEALTH");

                // 3. Screen Lock: Elevate Desktop Forms to TopMost if no Decoy app, or keep desktop ready
                if (!BossDecoyEnabled) {
                    foreach (IntPtr h in CustomDesktopForm.DesktopHwnds) {
                        SetWindowPos(h, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                    }
                    CustomDesktopForm.ActivateDesktop();
                    DesktopLogger.Log("Stealth Mode: Desktop forms elevated to TopMost overlay.", "STEALTH");
                }

                // 4. Mute Audio
                if (BossMuteAudio) {
                    keybd_event((byte)VK_VOLUME_MUTE, 0, 0, UIntPtr.Zero);
                    keybd_event((byte)VK_VOLUME_MUTE, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
                    DesktopLogger.Log("Stealth Mode: Master system audio muted.", "STEALTH");
                }

                // 5. Instant 0ms Decoy Reveal in Fullscreen / Maximized Mode
                if (BossDecoyEnabled) {
                    if (!string.IsNullOrEmpty(BossDecoyPath) && (BossDecoyPath.IndexOf("Update", StringComparison.OrdinalIgnoreCase) >= 0 || BossDecoyPath == "FakeWindowsUpdate" || (BossDecoyPreset != null && BossDecoyPreset.IndexOf("Update", StringComparison.OrdinalIgnoreCase) >= 0))) {
                        FakeWindowsUpdateForm.ShowUpdateScreens();
                        DesktopLogger.Log("Stealth Mode: Authentic Fake Windows 11 Update Screen launched across all displays.", "STEALTH");
                    } else {
                        IntPtr targetHwnd = IntPtr.Zero;
                        if (_prewarmedProcess != null && !_prewarmedProcess.HasExited && _prewarmedHwnd != IntPtr.Zero && IsWindow(_prewarmedHwnd)) {
                            targetHwnd = _prewarmedHwnd;
                        }

                        if (targetHwnd == IntPtr.Zero && _prewarmedProcess != null && !_prewarmedProcess.HasExited) {
                            try { targetHwnd = _prewarmedProcess.MainWindowHandle; } catch { }
                        }

                        if (targetHwnd == IntPtr.Zero && !string.IsNullOrEmpty(BossDecoyPath)) {
                            string exeName = "";
                            try { exeName = System.IO.Path.GetFileNameWithoutExtension(BossDecoyPath).ToLower(); } catch { }
                            
                            EnumWindows((w, l) => {
                                uint pid;
                                GetWindowThreadProcessId(w, out pid);
                                if (!string.IsNullOrEmpty(exeName)) {
                                    try {
                                        Process p = Process.GetProcessById((int)pid);
                                        if (p.ProcessName.ToLower() == exeName) {
                                            targetHwnd = w;
                                            _prewarmedHwnd = w;
                                            _prewarmedProcess = p;
                                            return false;
                                        }
                                    } catch { }
                                }
                                return true;
                            }, IntPtr.Zero);
                        }

                        if (targetHwnd != IntPtr.Zero && IsWindow(targetHwnd)) {
                            ShowWindow(targetHwnd, SW_RESTORE);
                            ShowWindow(targetHwnd, SW_SHOWMAXIMIZED);
                            SetWindowPos(targetHwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                            SetWindowPos(targetHwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                            BringWindowToTop(targetHwnd);
                            SetForegroundWindow(targetHwnd);
                            SwitchToThisWindow(targetHwnd, true);
                            DesktopLogger.Log(string.Format("Stealth Mode: Decoy App revealed instantly (0ms) -> HWND: 0x{0:X}", targetHwnd.ToInt64()), "STEALTH");
                        } else if (!string.IsNullOrEmpty(BossDecoyPath)) {
                            try {
                                ProcessStartInfo psi = new ProcessStartInfo();
                                psi.FileName = BossDecoyPath;
                                psi.UseShellExecute = true;
                                psi.WindowStyle = ProcessWindowStyle.Maximized;
                                psi.WorkingDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                                Process p = Process.Start(psi);
                                if (p != null) {
                                    _spawnedDecoys.Add(p);
                                    _prewarmedProcess = p;
                                    DesktopLogger.Log(string.Format("Stealth Mode: Spawned Decoy Process (PID: {0}, File: {1})", p.Id, BossDecoyPath), "STEALTH");
                                    System.Threading.ThreadPool.QueueUserWorkItem((state) => {
                                        try {
                                            for (int k = 0; k < 50; k++) {
                                                System.Threading.Thread.Sleep(50);
                                                IntPtr nw = IntPtr.Zero;
                                                try { nw = p.MainWindowHandle; } catch { }
                                                if (nw != IntPtr.Zero && IsWindow(nw)) {
                                                    _prewarmedHwnd = nw;
                                                    ShowWindow(nw, SW_SHOWMAXIMIZED);
                                                    SetWindowPos(nw, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                                                    SetWindowPos(nw, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                                                    BringWindowToTop(nw);
                                                    SetForegroundWindow(nw);
                                                    SwitchToThisWindow(nw, true);
                                                    break;
                                                }
                                            }
                                        } catch { }
                                    });
                                }
                            } catch (Exception ex) { DesktopLogger.Log("Stealth Mode: Failed to spawn decoy app - " + ex.Message, "ERROR"); }
                        }
                    }
                }
            } else {
                IsBossModeActive = false;
                DesktopLogger.Log("BOSS KEY RESTORED: Exiting Stealth Mode...", "STEALTH");

                // 1. Hide or Close Decoy Apps
                FakeWindowsUpdateForm.CloseUpdateScreens();
                DesktopLogger.Log("Stealth Mode: Closed Fake Windows Update Screens.", "STEALTH");

                if (BossDecoyPrewarm && _prewarmedProcess != null && !_prewarmedProcess.HasExited) {
                    IntPtr targetHwnd = (_prewarmedHwnd != IntPtr.Zero) ? _prewarmedHwnd : _prewarmedProcess.MainWindowHandle;
                    if (targetHwnd != IntPtr.Zero && IsWindow(targetHwnd)) {
                        ShowWindow(targetHwnd, SW_HIDE);
                    }
                    DesktopLogger.Log("Stealth Mode: Re-hid pre-warmed decoy app back to standby.", "STEALTH");
                } else if (BossDecoyCloseOnRestore && _spawnedDecoys.Count > 0) {
                    foreach (Process p in _spawnedDecoys) {
                        try {
                            if (!p.HasExited) {
                                p.CloseMainWindow();
                                if (!p.WaitForExit(400)) {
                                    p.Kill();
                                }
                            }
                            p.Dispose();
                        } catch { }
                    }
                    DesktopLogger.Log(string.Format("Stealth Mode: Closed {0} spawned decoy processes.", _spawnedDecoys.Count), "STEALTH");
                    _spawnedDecoys.Clear();
                    _prewarmedProcess = null;
                    _prewarmedHwnd = IntPtr.Zero;
                }

                // 2. Restore Taskbars
                foreach (IntPtr h in _hiddenTaskbars) {
                    ShowWindow(h, SW_SHOW);
                }
                DesktopLogger.Log(string.Format("Stealth Mode: Restored {0} taskbar windows.", _hiddenTaskbars.Count), "STEALTH");
                _hiddenTaskbars.Clear();

                // 3. Restore Application Windows
                foreach (IntPtr h in _hiddenBossWindows) {
                    ShowWindow(h, SW_SHOW);
                }
                DesktopLogger.Log(string.Format("Stealth Mode: Restored {0} top-level application windows.", _hiddenBossWindows.Count), "STEALTH");
                _hiddenBossWindows.Clear();

                // 4. Reset Desktop Forms from TopMost to Normal Desktop Layer
                foreach (IntPtr h in CustomDesktopForm.DesktopHwnds) {
                    SetWindowPos(h, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                }

                // 5. Unmute Audio
                if (BossMuteAudio) {
                    keybd_event((byte)VK_VOLUME_MUTE, 0, 0, UIntPtr.Zero);
                    keybd_event((byte)VK_VOLUME_MUTE, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
                    DesktopLogger.Log("Stealth Mode: Master system audio unmuted.", "STEALTH");
                }
            }
        } catch (Exception ex) { DesktopLogger.Log("ToggleBossMode exception: " + ex.Message, "ERROR"); }
    }

    public static void ToggleDesktop() {
        try {
            IntPtr shellHwnd = GetShellWindow();
            if (_minimizedByWinD.Count > 0) {
                foreach (IntPtr h in _minimizedByWinD) {
                    if (IsWindowVisible(h)) {
                        ShowWindowAsync(h, SW_RESTORE);
                    }
                }
                DesktopLogger.Log(string.Format("Win+D Restore: Restored {0} minimized windows.", _minimizedByWinD.Count), "AUDIT");
                _minimizedByWinD.Clear();
            } else {
                EnumWindows((hWnd, lParam) => {
                    if (hWnd != shellHwnd && !CustomDesktopForm.DesktopHwnds.Contains(hWnd) && IsWindowVisible(hWnd) && !IsIconic(hWnd)) {
                        ShowWindowAsync(hWnd, SW_MINIMIZE);
                        _minimizedByWinD.Add(hWnd);
                    }
                    return true;
                }, IntPtr.Zero);
                DesktopLogger.Log(string.Format("Win+D Minimize: Minimized {0} windows to show desktop.", _minimizedByWinD.Count), "AUDIT");
            }
        } catch (Exception ex) { DesktopLogger.Log("ToggleDesktop exception: " + ex.Message, "ERROR"); }
    }

    public void Dispose() {
        try {
            if (IsBossModeActive) {
                ToggleBossMode();
            }
            if (_prewarmedProcess != null) {
                try { if (!_prewarmedProcess.HasExited) _prewarmedProcess.Kill(); _prewarmedProcess.Dispose(); } catch { }
                _prewarmedProcess = null;
            }
            foreach (Process p in _spawnedDecoys) {
                try { if (!p.HasExited) { p.CloseMainWindow(); } p.Dispose(); } catch { }
            }
            _spawnedDecoys.Clear();
            if (_hookId != IntPtr.Zero) {
                UnhookWindowsHookEx(_hookId);
                _hookId = IntPtr.Zero;
            }
            if (_procHandle.IsAllocated) {
                _procHandle.Free();
            }
        } catch { }
    }
}

public class PropertiesWindowFocusManager : IDisposable
{
    private const uint EVENT_SYSTEM_FOREGROUND = 0x0003;
    private const uint EVENT_OBJECT_DESTROY = 0x8001;
    private const uint EVENT_OBJECT_HIDE = 0x8003;
    private const uint WIN_EVENT_OUTOFCONTEXT = 0x0000;
    private const int OBJID_WINDOW = 0;
    private const uint SHOP_FILEPATH = 0x2;

    private delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr hmodWinEventProc, WinEventDelegate lpfnWinEventProc, uint idProcess, uint idThread, uint dwFlags);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnhookWinEvent(IntPtr hWinEventHook);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr ProcessId);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern bool SHObjectProperties(IntPtr hwnd, uint shopObjectType, string pszObjectName, string pszPropertyPage);

    private IntPtr _desktopHwnd;
    private IntPtr _dialogHwnd = IntPtr.Zero;
    private IntPtr _hookForeground = IntPtr.Zero;
    private IntPtr _hookHide = IntPtr.Zero;
    private IntPtr _hookDestroy = IntPtr.Zero;
    private WinEventDelegate _procDelegate;
    private GCHandle _procDelegateHandle;

    public void ShowProperties(string filePath, IntPtr ownerHwnd)
    {
        try {
            _desktopHwnd = ownerHwnd;
            _dialogHwnd = IntPtr.Zero;

            _procDelegate = new WinEventDelegate(WinEventProc);
            _procDelegateHandle = GCHandle.Alloc(_procDelegate);

            _hookForeground = SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, IntPtr.Zero, _procDelegate, 0, 0, WIN_EVENT_OUTOFCONTEXT);
            _hookHide = SetWinEventHook(EVENT_OBJECT_HIDE, EVENT_OBJECT_HIDE, IntPtr.Zero, _procDelegate, 0, 0, WIN_EVENT_OUTOFCONTEXT);
            _hookDestroy = SetWinEventHook(EVENT_OBJECT_DESTROY, EVENT_OBJECT_DESTROY, IntPtr.Zero, _procDelegate, 0, 0, WIN_EVENT_OUTOFCONTEXT);

            SHObjectProperties(_desktopHwnd, SHOP_FILEPATH, filePath, null);
        } catch { }
    }

    private void WinEventProc(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime)
    {
        try {
            if (idObject != OBJID_WINDOW) return;

            if (eventType == EVENT_SYSTEM_FOREGROUND)
            {
                if (_dialogHwnd == IntPtr.Zero)
                {
                    StringBuilder sb = new StringBuilder(256);
                    GetClassName(hwnd, sb, sb.Capacity);
                    if (sb.ToString() == "#32770")
                    {
                        _dialogHwnd = hwnd;
                    }
                }
            }
            else if (eventType == EVENT_OBJECT_HIDE || eventType == EVENT_OBJECT_DESTROY)
            {
                if (_dialogHwnd != IntPtr.Zero && hwnd == _dialogHwnd)
                {
                    CleanupHooks();
                    ForceForegroundWindow(_desktopHwnd);
                }
            }
        } catch { }
    }

    private static void ForceForegroundWindow(IntPtr hWnd)
    {
        try {
            IntPtr hCurForeground = GetForegroundWindow();
            if (hCurForeground == hWnd) return;

            uint foreThread = GetWindowThreadProcessId(hCurForeground, IntPtr.Zero);
            uint appThread = GetCurrentThreadId();

            if (foreThread != appThread && foreThread != 0)
            {
                AttachThreadInput(appThread, foreThread, true);
                BringWindowToTop(hWnd);
                SetForegroundWindow(hWnd);
                AttachThreadInput(appThread, foreThread, false);
            }
            else
            {
                BringWindowToTop(hWnd);
                SetForegroundWindow(hWnd);
            }
        } catch {}
    }

    private void CleanupHooks()
    {
        try {
            if (_hookForeground != IntPtr.Zero) { UnhookWinEvent(_hookForeground); _hookForeground = IntPtr.Zero; }
            if (_hookHide != IntPtr.Zero) { UnhookWinEvent(_hookHide); _hookHide = IntPtr.Zero; }
            if (_hookDestroy != IntPtr.Zero) { UnhookWinEvent(_hookDestroy); _hookDestroy = IntPtr.Zero; }
            if (_procDelegateHandle.IsAllocated) { _procDelegateHandle.Free(); }
        } catch { }
    }

    public void Dispose()
    {
        CleanupHooks();
    }
}

public static class OleDropHelper
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINTL { public int x; public int y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct SIZEL { public int cx; public int cy; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct FILEDESCRIPTORW
    {
        public uint dwFlags;
        public Guid clsid;
        public SIZEL sizel;
        public POINTL pointl;
        public uint dwFileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
        public uint nFileSizeHigh;
        public uint nFileSizeLow;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string cFileName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct FILEDESCRIPTORA
    {
        public uint dwFlags;
        public Guid clsid;
        public SIZEL sizel;
        public POINTL pointl;
        public uint dwFileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
        public uint nFileSizeHigh;
        public uint nFileSizeLow;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string cFileName;
    }

    [ComImport]
    [Guid("0000000C-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IStream
    {
        void Read([Out, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1)] byte[] pv, int cb, IntPtr pcbRead);
        void Write([MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1)] byte[] pv, int cb, IntPtr pcbWritten);
        void Seek(long dlibMove, int dwOrigin, IntPtr plibNewPosition);
        void SetSize(long libNewSize);
        void CopyTo(IStream pstm, long cb, IntPtr pcbRead, IntPtr pcbWritten);
        void Commit(int grfCommitFlags);
        void Revert();
        void LockRegion(long libOffset, long cb, int dwLockType);
        void UnlockRegion(long libOffset, long cb, int dwLockType);
        void Stat(out System.Runtime.InteropServices.ComTypes.STATSTG pstatstg, int grfStatFlag);
        void Clone(out IStream ppstm);
    }

    [DllImport("kernel32.dll", ExactSpelling = true)]
    public static extern IntPtr GlobalLock(IntPtr handle);

    [DllImport("kernel32.dll", ExactSpelling = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GlobalUnlock(IntPtr handle);

    [DllImport("kernel32.dll", ExactSpelling = true)]
    public static extern int GlobalSize(IntPtr handle);

    [DllImport("ole32.dll", ExactSpelling = true)]
    public static extern void ReleaseStgMedium(ref STGMEDIUM pmedium);

    public static List<string> ExtractFiles(System.Windows.Forms.IDataObject dataObject, string destinationDirectory)
    {
        List<string> extractedFiles = new List<string>();
        if (dataObject == null || string.IsNullOrEmpty(destinationDirectory)) return extractedFiles;

        try {
            if (!Directory.Exists(destinationDirectory)) {
                Directory.CreateDirectory(destinationDirectory);
            }

            if (dataObject.GetDataPresent(DataFormats.FileDrop))
            {
                string[] files = null;
                try { files = (string[])dataObject.GetData(DataFormats.FileDrop); } catch { }
                if (files != null)
                {
                    foreach (string sourceFile in files)
                    {
                        try {
                            if (string.IsNullOrEmpty(sourceFile)) continue;
                            string destFile = Path.Combine(destinationDirectory, Path.GetFileName(sourceFile));
                            if (File.Exists(sourceFile))
                            {
                                if (sourceFile.Equals(destFile, StringComparison.OrdinalIgnoreCase)) {
                                    destFile = GetUniquePath(destFile);
                                }
                                File.Copy(sourceFile, destFile, true);
                                extractedFiles.Add(destFile);
                            }
                            else if (Directory.Exists(sourceFile))
                            {
                                if (sourceFile.Equals(destFile, StringComparison.OrdinalIgnoreCase)) {
                                    destFile = GetUniquePath(destFile);
                                }
                                CopyDirectoryRecursive(sourceFile, destFile);
                                extractedFiles.Add(destFile);
                            }
                        } catch { }
                    }
                    if (extractedFiles.Count > 0) return extractedFiles;
                }
            }

            bool isUnicode = false;
            bool isAnsi = false;
            try { isUnicode = dataObject.GetDataPresent("FileGroupDescriptorW"); } catch { }
            try { isAnsi = !isUnicode && dataObject.GetDataPresent("FileGroupDescriptor"); } catch { }

            if (isUnicode || isAnsi)
            {
                string formatName = isUnicode ? "FileGroupDescriptorW" : "FileGroupDescriptor";
                System.Runtime.InteropServices.ComTypes.IDataObject comDataObject = dataObject as System.Runtime.InteropServices.ComTypes.IDataObject;
                MemoryStream fdStream = null;
                try { fdStream = dataObject.GetData(formatName) as MemoryStream; } catch { }
                
                if (fdStream != null && comDataObject != null)
                {
                    byte[] fdBytes = fdStream.ToArray();
                    if (fdBytes.Length >= 4)
                    {
                        uint cItems = BitConverter.ToUInt32(fdBytes, 0);
                        int fdSize = isUnicode ? Marshal.SizeOf(typeof(FILEDESCRIPTORW)) : Marshal.SizeOf(typeof(FILEDESCRIPTORA));
                        
                        for (int i = 0; i < cItems; i++)
                        {
                            int offset = 4 + (i * fdSize);
                            if (offset + fdSize > fdBytes.Length) break;

                            string fileName = "";
                            IntPtr ptr = Marshal.AllocHGlobal(fdSize);
                            try
                            {
                                Marshal.Copy(fdBytes, offset, ptr, fdSize);
                                if (isUnicode) {
                                    FILEDESCRIPTORW fd = (FILEDESCRIPTORW)Marshal.PtrToStructure(ptr, typeof(FILEDESCRIPTORW));
                                    fileName = fd.cFileName;
                                } else {
                                    FILEDESCRIPTORA fd = (FILEDESCRIPTORA)Marshal.PtrToStructure(ptr, typeof(FILEDESCRIPTORA));
                                    fileName = fd.cFileName;
                                }
                            }
                            finally { Marshal.FreeHGlobal(ptr); }

                            if (!string.IsNullOrEmpty(fileName))
                            {
                                try {
                                    string destFile = Path.Combine(destinationDirectory, fileName);
                                    string destDir = Path.GetDirectoryName(destFile);
                                    if (!Directory.Exists(destDir)) Directory.CreateDirectory(destDir);

                                    destFile = GetUniquePath(destFile);
                                    if (ExtractFileContent(comDataObject, i, destFile))
                                    {
                                        extractedFiles.Add(destFile);
                                    }
                                } catch { }
                            }
                        }
                    }
                }
                if (extractedFiles.Count > 0) return extractedFiles;
            }

            if (dataObject.GetDataPresent(DataFormats.Text))
            {
                string text = null;
                try { text = (string)dataObject.GetData(DataFormats.Text); } catch { }
                if (!string.IsNullOrWhiteSpace(text))
                {
                    string[] lines = text.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string line in lines)
                    {
                        try {
                            string p = line.Trim().Trim('\"', '\'');
                            if (File.Exists(p))
                            {
                                string destFile = GetUniquePath(Path.Combine(destinationDirectory, Path.GetFileName(p)));
                                File.Copy(p, destFile, true);
                                extractedFiles.Add(destFile);
                            }
                            else if (Directory.Exists(p))
                            {
                                string destFile = GetUniquePath(Path.Combine(destinationDirectory, Path.GetFileName(p)));
                                CopyDirectoryRecursive(p, destFile);
                                extractedFiles.Add(destFile);
                            }
                        } catch { }
                    }
                }
            }
        } catch { }

        return extractedFiles;
    }

    private static string GetUniquePath(string path) {
        if (!File.Exists(path) && !Directory.Exists(path)) return path;
        string dir = Path.GetDirectoryName(path);
        string baseName = Path.GetFileNameWithoutExtension(path);
        string ext = Path.GetExtension(path);
        int counter = 2;
        string newPath = Path.Combine(dir, baseName + " - Copy" + ext);
        while (File.Exists(newPath) || Directory.Exists(newPath)) {
            newPath = Path.Combine(dir, baseName + " - Copy (" + counter + ")" + ext);
            counter++;
        }
        return newPath;
    }

    private static void CopyDirectoryRecursive(string sourceDir, string destinationDir) {
        Directory.CreateDirectory(destinationDir);
        foreach (string file in Directory.GetFiles(sourceDir)) {
            File.Copy(file, Path.Combine(destinationDir, Path.GetFileName(file)), true);
        }
        foreach (string subDir in Directory.GetDirectories(sourceDir)) {
            CopyDirectoryRecursive(subDir, Path.Combine(destinationDir, Path.GetFileName(subDir)));
        }
    }

    private static bool ExtractFileContent(System.Runtime.InteropServices.ComTypes.IDataObject comDataObject, int index, string destinationPath)
    {
        FORMATETC formatetc = new FORMATETC
        {
            cfFormat = (short)DataFormats.GetFormat("FileContents").Id,
            dwAspect = DVASPECT.DVASPECT_CONTENT,
            lindex = index,
            ptd = IntPtr.Zero,
            tymed = TYMED.TYMED_ISTREAM | TYMED.TYMED_HGLOBAL
        };

        STGMEDIUM medium = new STGMEDIUM();
        try
        {
            comDataObject.GetData(ref formatetc, out medium);

            if (medium.tymed == TYMED.TYMED_ISTREAM)
            {
                IStream stream = (IStream)Marshal.GetObjectForIUnknown(medium.unionmember);
                using (FileStream fs = new FileStream(destinationPath, FileMode.Create, FileAccess.Write))
                {
                    byte[] buffer = new byte[8192];
                    IntPtr pcbRead = Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(int)));
                    try
                    {
                        while (true)
                        {
                            stream.Read(buffer, buffer.Length, pcbRead);
                            int bytesRead = Marshal.ReadInt32(pcbRead);
                            if (bytesRead <= 0) break;
                            fs.Write(buffer, 0, bytesRead);
                        }
                    }
                    finally
                    {
                        Marshal.FreeCoTaskMem(pcbRead);
                    }
                }
                return true;
            }
            else if (medium.tymed == TYMED.TYMED_HGLOBAL)
            {
                IntPtr ptr = GlobalLock(medium.unionmember);
                try
                {
                    int size = GlobalSize(medium.unionmember);
                    byte[] buffer = new byte[size];
                    Marshal.Copy(ptr, buffer, 0, size);
                    File.WriteAllBytes(destinationPath, buffer);
                }
                finally { GlobalUnlock(medium.unionmember); }
                return true;
            }
        }
        catch { }
        finally
        {
            if (medium.unionmember != IntPtr.Zero)
            {
                ReleaseStgMedium(ref medium);
            }
        }

        return false;
    }
}

public static class ShellIcons
{
    private const int CSIDL_BITBUCKET = 0x000a;
    private const uint SHGFI_PIDL = 0x00000008;
    private const uint SHGFI_SYSICONINDEX = 0x00004000;
    private const uint SHGFI_USEFILEATTRIBUTES = 0x00000010;
    private const uint SHGFI_ICON = 0x00000100;
    private const uint SHGFI_LARGEICON = 0x00000000;
    private const uint FILE_ATTRIBUTE_DIRECTORY = 0x10;
    private const uint FILE_ATTRIBUTE_NORMAL = 0x80;
    private const int SHIL_JUMBO = 4;
    private const int SHIL_EXTRALARGE = 2;
    private const int ILD_TRANSPARENT = 1;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SHFILEINFO {
        public IntPtr hIcon; public int iIcon; public uint dwAttributes;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szDisplayName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)] public string szTypeName;
    }

    [DllImport("shell32.dll")]
    public static extern int SHGetSpecialFolderLocation(IntPtr hwnd, int csidl, out IntPtr ppidl);
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SHGetFileInfo(IntPtr ppidl, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbSizeFileInfo, uint uFlags);
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SHGetFileInfo(string pszPath, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbSizeFileInfo, uint uFlags);
    [DllImport("ole32.dll")]
    public static extern void CoTaskMemFree(IntPtr pv);
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool DestroyIcon(IntPtr hIcon);

    [DllImport("shell32.dll", EntryPoint = "#727")]
    private static extern int SHGetImageList(int iImageList, ref Guid riid, out IImageList ppv);

    [ComImportAttribute()]
    [GuidAttribute("46EB5926-582E-4017-9FDF-E8998DAA0950")]
    [InterfaceTypeAttribute(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IImageList {
        [PreserveSig] int Add(IntPtr hbmImage, IntPtr hbmMask, ref int pi);
        [PreserveSig] int ReplaceIcon(int i, IntPtr hicon, ref int pi);
        [PreserveSig] int SetOverlayImage(int iImage, int iOverlay);
        [PreserveSig] int Replace(int i, IntPtr hbmImage, IntPtr hbmMask);
        [PreserveSig] int AddMasked(IntPtr hbmImage, int crMask, ref int pi);
        [PreserveSig] int Draw(IntPtr pimldp);
        [PreserveSig] int Remove(int i);
        [PreserveSig] int GetIcon(int i, int flags, ref IntPtr picon);
        [PreserveSig] int GetImageInfo(int i, IntPtr pImageInfo);
    };

    private static readonly Guid IImageListGuid = new Guid("46EB5926-582E-4017-9FDF-E8998DAA0950");
    private static PropertiesWindowFocusManager _propsTracker = null;

    public static void ShowProperties(string path, IntPtr owner) {
        try {
            if (_propsTracker != null) { _propsTracker.Dispose(); _propsTracker = null; }
            _propsTracker = new PropertiesWindowFocusManager();
            _propsTracker.ShowProperties(path, owner);
        } catch { }
    }

    public static Bitmap GetRecycleBinIcon() {
        IntPtr pidl = IntPtr.Zero;
        try {
            if (SHGetSpecialFolderLocation(IntPtr.Zero, CSIDL_BITBUCKET, out pidl) == 0 && pidl != IntPtr.Zero) {
                SHFILEINFO shinfo = new SHFILEINFO();
                IntPtr res = SHGetFileInfo(pidl, 0, ref shinfo, (uint)Marshal.SizeOf(typeof(SHFILEINFO)), SHGFI_PIDL | SHGFI_SYSICONINDEX);
                if (res != IntPtr.Zero) {
                    Guid iidImageList = IImageListGuid;
                    IImageList iml;
                    int hres = SHGetImageList(SHIL_JUMBO, ref iidImageList, out iml);
                    if (hres != 0 || iml == null) { hres = SHGetImageList(SHIL_EXTRALARGE, ref iidImageList, out iml); }
                    if (hres == 0 && iml != null) {
                        try {
                            IntPtr hIcon = IntPtr.Zero;
                            iml.GetIcon(shinfo.iIcon, ILD_TRANSPARENT, ref hIcon);
                            if (hIcon != IntPtr.Zero) {
                                try {
                                    using (Icon icon = Icon.FromHandle(hIcon)) {
                                        return new Bitmap(icon.ToBitmap());
                                    }
                                }
                                finally { DestroyIcon(hIcon); }
                            }
                        }
                        finally { Marshal.ReleaseComObject(iml); }
                    }
                }
            }
        } catch { }
        finally {
            if (pidl != IntPtr.Zero) CoTaskMemFree(pidl);
        }
        return null;
    }

    public static Bitmap GetIcon(string path, bool isDirectory) {
        if (string.IsNullOrEmpty(path)) return null;

        // 1. High-DPI Jumbo (256x256) & Extra Large (48x48) Shell ImageList with 100% Alpha Transparency
        try {
            SHFILEINFO shinfo = new SHFILEINFO();
            uint attrs = isDirectory ? FILE_ATTRIBUTE_DIRECTORY : FILE_ATTRIBUTE_NORMAL;
            uint flags = SHGFI_SYSICONINDEX;
            IntPtr res = SHGetFileInfo(path, 0, ref shinfo, (uint)Marshal.SizeOf(typeof(SHFILEINFO)), flags);
            if (res == IntPtr.Zero) {
                shinfo = new SHFILEINFO();
                flags = SHGFI_SYSICONINDEX | SHGFI_USEFILEATTRIBUTES;
                res = SHGetFileInfo(path, attrs, ref shinfo, (uint)Marshal.SizeOf(typeof(SHFILEINFO)), flags);
            }
            if (res != IntPtr.Zero) {
                Guid iidImageList = IImageListGuid;
                IImageList iml;
                int hres = SHGetImageList(SHIL_JUMBO, ref iidImageList, out iml);
                if (hres != 0 || iml == null) { hres = SHGetImageList(SHIL_EXTRALARGE, ref iidImageList, out iml); }
                if (hres == 0 && iml != null) {
                    try {
                        IntPtr hIcon = IntPtr.Zero;
                        iml.GetIcon(shinfo.iIcon, ILD_TRANSPARENT, ref hIcon);
                        if (hIcon != IntPtr.Zero) {
                            try { 
                                using (Icon icon = Icon.FromHandle(hIcon)) {
                                    return new Bitmap(icon.ToBitmap());
                                } 
                            }
                            finally { DestroyIcon(hIcon); }
                        }
                    }
                    finally { Marshal.ReleaseComObject(iml); }
                }
            }
        } catch { }

        // 2. Direct HICON extraction with SHGFI_ICON
        try {
            SHFILEINFO shinfo = new SHFILEINFO();
            uint attrs = isDirectory ? FILE_ATTRIBUTE_DIRECTORY : FILE_ATTRIBUTE_NORMAL;
            uint flags = SHGFI_ICON | SHGFI_LARGEICON;
            IntPtr res = SHGetFileInfo(path, 0, ref shinfo, (uint)Marshal.SizeOf(typeof(SHFILEINFO)), flags);
            if (res == IntPtr.Zero) {
                flags |= SHGFI_USEFILEATTRIBUTES;
                res = SHGetFileInfo(path, attrs, ref shinfo, (uint)Marshal.SizeOf(typeof(SHFILEINFO)), flags);
            }
            if (res != IntPtr.Zero && shinfo.hIcon != IntPtr.Zero) {
                try {
                    using (Icon icon = Icon.FromHandle(shinfo.hIcon)) {
                        return new Bitmap(icon.ToBitmap());
                    }
                } finally {
                    DestroyIcon(shinfo.hIcon);
                }
            }
        } catch { }

        // 3. Fallback: ExtractAssociatedIcon
        if (!isDirectory && File.Exists(path)) {
            try {
                using (Icon ico = Icon.ExtractAssociatedIcon(path)) {
                    if (ico != null) return ico.ToBitmap();
                }
            } catch { }
        }

        // 4. Universal Fallback for custom / unassociated / extensionless files & folders
        try {
            SHFILEINFO shinfo = new SHFILEINFO();
            string fallbackExt = isDirectory ? ".dir" : ".txt";
            uint attrs = isDirectory ? FILE_ATTRIBUTE_DIRECTORY : FILE_ATTRIBUTE_NORMAL;
            IntPtr res = SHGetFileInfo(fallbackExt, attrs, ref shinfo, (uint)Marshal.SizeOf(typeof(SHFILEINFO)), SHGFI_USEFILEATTRIBUTES | SHGFI_ICON | SHGFI_LARGEICON);
            if (res != IntPtr.Zero && shinfo.hIcon != IntPtr.Zero) {
                try {
                    using (Icon icon = Icon.FromHandle(shinfo.hIcon)) {
                        return new Bitmap(icon.ToBitmap());
                    }
                } finally {
                    DestroyIcon(shinfo.hIcon);
                }
            }
        } catch { }

        return null;
    }
}

public class DarkColorTable : ProfessionalColorTable {
    public override Color MenuItemSelected { get { return ColorTranslator.FromHtml("#1e293b"); } }
    public override Color MenuItemBorder { get { return Color.Transparent; } }
    public override Color ToolStripDropDownBackground { get { return ColorTranslator.FromHtml("#0f172a"); } }
    public override Color ImageMarginGradientBegin { get { return ColorTranslator.FromHtml("#0f172a"); } }
    public override Color ImageMarginGradientMiddle { get { return ColorTranslator.FromHtml("#0f172a"); } }
    public override Color ImageMarginGradientEnd { get { return ColorTranslator.FromHtml("#0f172a"); } }
    public override Color MenuBorder { get { return ColorTranslator.FromHtml("#1e293b"); } }
    public override Color SeparatorDark { get { return ColorTranslator.FromHtml("#1e293b"); } }
    public override Color SeparatorLight { get { return Color.Transparent; } }
    public override Color CheckBackground { get { return ColorTranslator.FromHtml("#2563eb"); } }
    public override Color CheckSelectedBackground { get { return ColorTranslator.FromHtml("#3b82f6"); } }
    public override Color CheckPressedBackground { get { return ColorTranslator.FromHtml("#1d4ed8"); } }
    public override Color ButtonCheckedHighlight { get { return ColorTranslator.FromHtml("#2563eb"); } }
    public override Color ButtonCheckedGradientBegin { get { return ColorTranslator.FromHtml("#2563eb"); } }
    public override Color ButtonCheckedGradientMiddle { get { return ColorTranslator.FromHtml("#2563eb"); } }
    public override Color ButtonCheckedGradientEnd { get { return ColorTranslator.FromHtml("#2563eb"); } }
}

public class DarkMenuRenderer : ToolStripProfessionalRenderer {
    public DarkMenuRenderer() : base(new DarkColorTable()) { }
    
    protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e) {
        e.TextColor = Color.White;
        base.OnRenderItemText(e);
    }

    protected override void OnRenderItemCheck(ToolStripItemImageRenderEventArgs e) {
        Rectangle rc = e.ImageRectangle;
        if (rc.Width <= 0 || rc.Height <= 0) {
            rc = new Rectangle(5, (e.Item.Height - 16) / 2, 16, 16);
        } else {
            rc = new Rectangle(rc.X + (rc.Width - 16) / 2, rc.Y + (rc.Height - 16) / 2, 16, 16);
        }
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        using (SolidBrush bg = new SolidBrush(ColorTranslator.FromHtml("#2563eb")))
        using (Pen pen = new Pen(Color.White, 2f)) {
            e.Graphics.FillRectangle(bg, rc);
            Point[] checkPts = new Point[] {
                new Point(rc.X + 3, rc.Y + 8),
                new Point(rc.X + 6, rc.Y + 12),
                new Point(rc.X + 13, rc.Y + 4)
            };
            e.Graphics.DrawLines(pen, checkPts);
        }
    }
}
'@ -ReferencedAssemblies @("System.Drawing", "System.Windows.Forms", "System.Xaml", "PresentationCore", "PresentationFramework", "WindowsBase", "WindowsFormsIntegration")

# Initialize native logger
try { [DesktopLogger]::Initialize($script:logFile) } catch {}
Write-DesktopLog "Native C# DesktopLogger initialized ($script:logFile)"
Write-ConsoleStatus "        -> Core native C# subsystems compiled [OK]" "Green"

# ============================================================
# 009 - ICON RESIZING & CACHED LOADER
# ============================================================

function Clear-IconCache {
    foreach ($bmp in $script:iconCache.Values) {
        if ($null -ne $bmp) { try { $bmp.Dispose() } catch {} }
    }
    $script:iconCache.Clear()
}

function Resize-IconBitmap {
    param([System.Drawing.Bitmap]$Source, [int]$Size)
    if ($null -eq $Source -or $Size -lt 8 -or $Source.Width -le 0 -or $Source.Height -le 0) { return $null }
    try {
        $result = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($result)
        try {
            $g.Clear([System.Drawing.Color]::Transparent); $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality; $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $ratio = [Math]::Min($Size / [double]$Source.Width, $Size / [double]$Source.Height)
            $w = [Math]::Max(1, [int]($Source.Width * $ratio)); $h = [Math]::Max(1, [int]($Source.Height * $ratio))
            $x = [int](($Size - $w) / 2); $y = [int](($Size - $h) / 2)
            $g.DrawImage($Source, $x, $y, $w, $h)
        } finally { $g.Dispose() }
        return $result
    } catch { return $null }
}

function Get-DesktopIcon {
    param([System.IO.FileSystemInfo]$Item, [int]$Size)
    $cacheKey = "$($Item.FullName)_$Size"
    if ($script:iconCache.ContainsKey($cacheKey) -and $null -ne $script:iconCache[$cacheKey]) {
        return $script:iconCache[$cacheKey]
    }
    
    $raw = $null
    try { $raw = [ShellIcons]::GetIcon([string]$Item.FullName, [bool]$Item.PSIsContainer) } catch { }
    if ($null -eq $raw -and -not $Item.PSIsContainer) {
        try { $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($Item.FullName); if ($null -ne $ico) { $raw = $ico.ToBitmap(); $ico.Dispose() } } catch { }
    }
    if ($null -eq $raw) {
        try { if ($Item.PSIsContainer) { $raw = [System.Drawing.SystemIcons]::WinLogo.ToBitmap() } else { $raw = [System.Drawing.SystemIcons]::Application.ToBitmap() } } catch { return $null }
    }
    $scaled = Resize-IconBitmap $raw $Size
    try { $raw.Dispose() } catch { }
    
    if ($null -ne $scaled) {
        $script:iconCache[$cacheKey] = $scaled
    }
    return $scaled
}

$script:videoPlayer = $null

function Start-VideoWallpaper($VideoPath) {
    Stop-VideoWallpaper
    if ([string]::IsNullOrWhiteSpace($VideoPath) -or -not (Test-Path -LiteralPath $VideoPath)) { return }
    try {
        $wmpType = [System.Type]::GetTypeFromCLSID([System.Guid]::Parse("6BF52A52-394A-11D3-B153-00C04F79FAA6"))
        if ($null -ne $wmpType) {
            $script:videoPlayer = [System.Activator]::CreateInstance($wmpType)
            $script:videoPlayer.uiMode = "none"
            $script:videoPlayer.settings.setMode("loop", $true)
            $script:videoPlayer.settings.volume = 0
            $script:videoPlayer.settings.autoStart = $true
            $script:videoPlayer.URL = $VideoPath
        }
    } catch { }
}

function Stop-VideoWallpaper {
    if ($null -ne $script:videoPlayer) {
        try {
            $script:videoPlayer.close()
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($script:videoPlayer) | Out-Null
        } catch { }
        $script:videoPlayer = $null
    }
}

function Load-BackgroundImage {
    [LiveWallpaperEngine]::StopGifAnimation()
    [LiveWallpaperEngine]::StopAllVideos()

    if ($null -ne $script:backgroundImage) { 
        try { $script:backgroundImage.Dispose() } catch { }
        $script:backgroundImage = $null 
    }
    if ($settings.BackgroundType -ne "Image" -or [string]::IsNullOrWhiteSpace($settings.ImagePath) -or -not (Test-Path -LiteralPath $settings.ImagePath)) { return }
    
    if ([LiveWallpaperEngine]::IsVideo($settings.ImagePath)) {
        $validForms = New-Object System.Collections.Generic.List[System.Windows.Forms.Form]
        foreach ($f in $script:forms) {
            if ($null -ne $f -and -not $f.IsDisposed) {
                [void]$validForms.Add($f)
            }
        }
        if ($validForms.Count -gt 0) {
            [LiveWallpaperEngine]::StartVideoWallpaper($settings.ImagePath, $validForms, $true)
        }
        return
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($settings.ImagePath)
        $ms = New-Object System.IO.MemoryStream($bytes, 0, $bytes.Length)
        $source = [System.Drawing.Image]::FromStream($ms)

        if ([LiveWallpaperEngine]::IsGif($settings.ImagePath)) {
            $script:backgroundImage = $source
            $validForms = New-Object System.Collections.Generic.List[System.Windows.Forms.Form]
            foreach ($f in $script:forms) {
                if ($null -ne $f -and -not $f.IsDisposed) {
                    [void]$validForms.Add($f)
                }
            }
            if ($validForms.Count -gt 0) {
                [LiveWallpaperEngine]::StartGifAnimation($script:backgroundImage, $validForms)
            }
        } else {
            try { 
                $script:backgroundImage = New-Object System.Drawing.Bitmap($source) 
            } finally { 
                $source.Dispose()
                $ms.Dispose()
            }
        }
    } catch { 
        $script:backgroundImage = $null 
    }
}

function Apply-Background {
    Load-BackgroundImage

    if ($settings.BackgroundType -eq "Image" -and [LiveWallpaperEngine]::IsVideoActive) {
        foreach ($form in $script:forms) {
            if ($null -ne $form -and -not $form.IsDisposed) {
                $form.BackColor = [System.Drawing.Color]::FromArgb(1, 1, 1)
                $form.TransparencyKey = [System.Drawing.Color]::FromArgb(1, 1, 1)
                if ($form.BackgroundImage) { try { $form.BackgroundImage.Dispose() } catch {}; $form.BackgroundImage = $null }
                $form.Invalidate()
            }
        }
        return
    }

    foreach ($form in $script:forms) {
        if ($null -eq $form -or $form.IsDisposed -or $form.ClientSize.Width -le 0 -or $form.ClientSize.Height -le 0) { continue }
        $form.TransparencyKey = [System.Drawing.Color]::Empty
        
        try {
            $bmp = New-Object System.Drawing.Bitmap($form.ClientSize.Width, $form.ClientSize.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $width = $bmp.Width; $height = $bmp.Height
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

                if ($settings.BackgroundType -eq "Brand") {
                    # 1. Base Pitch Black Canvas
                    $rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
                    $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#020104"))

                    # 2. REAL Optical Bicubic Gaussian Blur for the -45 Degree Crimson Beam
                    $lowW = 160; $lowH = 90
                    $blurBmp = New-Object System.Drawing.Bitmap($lowW, $lowH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                    $bgLow = [System.Drawing.Graphics]::FromImage($blurBmp)
                    $bgLow.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

                    $lowRect = New-Object System.Drawing.Rectangle(0, 0, $lowW, $lowH)
                    $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($lowRect, [System.Drawing.Color]::Transparent, [System.Drawing.Color]::Transparent, -45.0)

                    $cb = New-Object System.Drawing.Drawing2D.ColorBlend
                    $cb.Positions = @(0.0, 0.20, 0.40, 0.50, 0.60, 0.80, 1.0)
                    $cb.Colors = @(
                        [System.Drawing.Color]::FromArgb(0, 0, 0, 0),
                        [System.Drawing.Color]::FromArgb(10, 50, 6, 10),
                        [System.Drawing.Color]::FromArgb(35, 120, 16, 24),
                        [System.Drawing.Color]::FromArgb(70, 220, 30, 45),
                        [System.Drawing.Color]::FromArgb(35, 120, 16, 24),
                        [System.Drawing.Color]::FromArgb(10, 50, 6, 10),
                        [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
                    )
                    $gradBrush.InterpolationColors = $cb
                    $bgLow.FillRectangle($gradBrush, $lowRect)
                    $gradBrush.Dispose()
                    $bgLow.Dispose()

                    $destRect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
                    $g.DrawImage($blurBmp, $destRect, 0, 0, $lowW, $lowH, [System.Drawing.GraphicsUnit]::Pixel)
                    $blurBmp.Dispose()

                    # 3. Unified Single-Line Typography: "RedSkia" (Red) + ".dev" (White) on the exact same baseline
                    $fontMain = New-Object System.Drawing.Font("Segoe UI", 38, [System.Drawing.FontStyle]::Bold)
                    $fontSub  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

                    $sfCenter = New-Object System.Drawing.StringFormat
                    $sfCenter.Alignment = [System.Drawing.StringAlignment]::Center
                    $sfCenter.LineAlignment = [System.Drawing.StringAlignment]::Center

                    $shadowDeep = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(250, 0, 0, 0))
                    $shadowSoft = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(140, 0, 0, 0))

                    $redBrush   = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#ef4444"))
                    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#ffffff"))

                    # Measure accurately for single-line inline placement
                    $szRedSkia = $g.MeasureString("RedSkia", $fontMain)
                    $szDev     = $g.MeasureString(".dev", $fontMain)

                    $k = 10
                    $totalTitleW = ($szRedSkia.Width - $k) + $szDev.Width

                    $startX = [int](($width - $totalTitleW) / 2)
                    $centerY = [int]($height / 2) - 15

                    $titleY = $centerY - 38

                    # Shadows (Same single line)
                    $g.DrawString("RedSkia", $fontMain, $shadowSoft, [float]($startX + 3), [float]($titleY + 3))
                    $g.DrawString("RedSkia", $fontMain, $shadowDeep, [float]($startX + 1.5), [float]($titleY + 1.5))

                    $xDev = $startX + $szRedSkia.Width - $k
                    $g.DrawString(".dev", $fontMain, $shadowSoft, [float]($xDev + 3), [float]($titleY + 3))
                    $g.DrawString(".dev", $fontMain, $shadowDeep, [float]($xDev + 1.5), [float]($titleY + 1.5))

                    # Foregrounds: RedSkia in RED (#ef4444) and .dev in WHITE (#ffffff)
                    $g.DrawString("RedSkia", $fontMain, $redBrush, [float]$startX, [float]$titleY)
                    $g.DrawString(".dev", $fontMain, $whiteBrush, [float]$xDev, [float]$titleY)

                    # 4. Splitter Line: Exactly Centered Horizontally & Mathematically Centered Vertically
                    $titleHeight = 52
                    $barY = $titleY + $titleHeight + 14
                    $barW = 160; $barH = 2
                    $barX = [int](($width - $barW) / 2)

                    $barRect = New-Object System.Drawing.Rectangle($barX, $barY, $barW, $barH)
                    $barBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($barRect, [System.Drawing.Color]::Transparent, [System.Drawing.Color]::Transparent, 0.0)
                    $barCb = New-Object System.Drawing.Drawing2D.ColorBlend
                    $barCb.Positions = @(0.0, 0.5, 1.0)
                    $barCb.Colors = @(
                        [System.Drawing.Color]::FromArgb(0, 239, 68, 68),
                        [System.Drawing.Color]::FromArgb(230, 239, 68, 68),
                        [System.Drawing.Color]::FromArgb(0, 239, 68, 68)
                    )
                    $barBrush.InterpolationColors = $barCb
                    try {
                        $g.FillRectangle($barBrush, $barRect)
                    } finally { $barBrush.Dispose() }

                    # 5. Subtitle: D E S K T O P   E M U L A T O R in clean WHITE (#ffffff) (14px gap below splitter line)
                    $subY = $barY + 2 + 14
                    $subRect = New-Object System.Drawing.RectangleF(0, [float]$subY, [float]$width, 24)
                    $subShadowRect = New-Object System.Drawing.RectangleF(1, [float]($subY + 1), [float]$width, 24)
                    $g.DrawString("D E S K T O P   E M U L A T O R", $fontSub, $shadowDeep, $subShadowRect, $sfCenter)
                    $g.DrawString("D E S K T O P   E M U L A T O R", $fontSub, $whiteBrush, $subRect, $sfCenter)

                    $fontMain.Dispose(); $fontSub.Dispose(); $sfCenter.Dispose()
                    $whiteBrush.Dispose(); $redBrush.Dispose(); $shadowDeep.Dispose(); $shadowSoft.Dispose()
                } elseif ($settings.BackgroundType -eq "Image" -and $null -ne $script:backgroundImage -and -not [LiveWallpaperEngine]::IsGifActive) {
                    $g.Clear((Get-ColorFromHex $settings.BackgroundColor))
                    $image = $script:backgroundImage
                    if ($image.Width -gt 0 -and $image.Height -gt 0) {
                        try {
                            $mode = [string]$settings.ImageMode
                            if ($mode -eq "Stretch") {
                                $g.DrawImage($image, (New-Object System.Drawing.Rectangle(0,0,$width,$height)))
                            } elseif ($mode -eq "Center") {
                                $x = [int](($width - $image.Width) / 2); $y = [int](($height - $image.Height) / 2)
                                $g.DrawImage($image, $x, $y, $image.Width, $image.Height)
                            } elseif ($mode -eq "Tile") {
                                $brush = New-Object System.Drawing.TextureBrush($image)
                                try { $g.FillRectangle($brush, 0, 0, $width, $height) } finally { $brush.Dispose() }
                            } else {
                                if ($mode -eq "Fit") { $scale = [Math]::Min($width / [double]$image.Width, $height / [double]$image.Height) }
                                else { $scale = [Math]::Max($width / [double]$image.Width, $height / [double]$image.Height) }
                                $newWidth = [int]($image.Width * $scale); $newHeight = [int]($image.Height * $scale)
                                $x = [int](($width - $newWidth) / 2); $y = [int](($height - $newHeight) / 2)
                                $g.DrawImage($image, (New-Object System.Drawing.Rectangle($x, $y, $newWidth, $newHeight)))
                            }
                        } catch { }
                    }
                } else {
                    $g.Clear((Get-ColorFromHex $settings.BackgroundColor))
                }

                $dimVal = [Math]::Max(0, [Math]::Min(90, [int]$settings.WallpaperDimming))
                if ($dimVal -gt 0 -and -not [LiveWallpaperEngine]::IsGifActive) {
                    $alpha = [int](255 * ($dimVal / 100.0))
                    $dimBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 0, 0, 0))
                    try {
                        $g.FillRectangle($dimBrush, 0, 0, $width, $height)
                    } finally { $dimBrush.Dispose() }
                }
            } finally { $g.Dispose() }
            
            if ($form.BackgroundImage) { $form.BackgroundImage.Dispose() }
            $form.BackgroundImage = $bmp
        } catch { }
    }
}

function Paint-DesktopBackground {
    param($Sender, $Event)
    if ($null -eq $Event -or $null -eq $script:desktopFont -or -not $settings.ShowDesktopIcons) { return }

    try {
        $g = $Event.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

        if ($settings.BackgroundType -eq "Image" -and [LiveWallpaperEngine]::IsVideoActive) {
            $g.Clear([System.Drawing.Color]::FromArgb(1, 1, 1))
        } elseif ($settings.BackgroundType -eq "Image" -and [LiveWallpaperEngine]::IsGifActive) {
            $gifImg = [LiveWallpaperEngine]::CurrentGifImage
            if ($null -ne $gifImg) {
                try {
                    $w = $Sender.ClientSize.Width; $h = $Sender.ClientSize.Height
                    $mode = [string]$settings.ImageMode
                    if ($mode -eq "Stretch") {
                        $g.DrawImage($gifImg, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)))
                    } elseif ($mode -eq "Center") {
                        $x = [int](($w - $gifImg.Width) / 2); $y = [int](($h - $gifImg.Height) / 2)
                        $g.DrawImage($gifImg, $x, $y, $gifImg.Width, $gifImg.Height)
                    } else {
                        if ($mode -eq "Fit") { $scale = [Math]::Min($w / [double]$gifImg.Width, $h / [double]$gifImg.Height) }
                        else { $scale = [Math]::Max($w / [double]$gifImg.Width, $h / [double]$gifImg.Height) }
                        $newWidth = [int]($gifImg.Width * $scale); $newHeight = [int]($gifImg.Height * $scale)
                        $x = [int](($w - $newWidth) / 2); $y = [int](($h - $newHeight) / 2)
                        $g.DrawImage($gifImg, (New-Object System.Drawing.Rectangle($x, $y, $newWidth, $newHeight)))
                    }
                    $dimVal = [Math]::Max(0, [Math]::Min(90, [int]$settings.WallpaperDimming))
                    if ($dimVal -gt 0) {
                        $alpha = [int](255 * ($dimVal / 100.0))
                        $dimBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 0, 0, 0))
                        try { $g.FillRectangle($dimBrush, 0, 0, $w, $h) } finally { $dimBrush.Dispose() }
                    }
                } catch { }
            }
        }

        $hoverBrush = New-Object System.Drawing.SolidBrush($script:Colors.PanelHover)
        $selBrush = New-Object System.Drawing.SolidBrush($script:Colors.Selected)
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
        $sf.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

        $iconSize = [int]$settings.IconScale
        $uiScale = 1.0; if ($null -ne $settings.UiScale -and [double]$settings.UiScale -gt 0) { $uiScale = [double]$settings.UiScale }
        $labelHeight = [int](38 * $uiScale)

        try {
            # 1. Draw Stationary Desktop Items (Filtered by Form client area for proper multi-monitor support)
            foreach ($item in $script:desktopItems) {
                if ($null -eq $item) { continue }
                if ($script:isDragging -and ($script:selectedItems -contains $item)) { continue }
                $b = $item.Bounds
                
                if (-not $Sender.ClientRectangle.IntersectsWith($b)) { continue }
                
                $isCut = ($script:cutFiles -contains $item.Path)
                
                if ($item.Selected) {
                    $g.FillRectangle($selBrush, $b)
                } elseif ($item.Hovered) {
                    $g.FillRectangle($hoverBrush, $b)
                }

                $iconX = $b.X + (($b.Width - $iconSize) / 2)
                $iconY = $b.Y + 4

                if ($null -ne $item.Icon) {
                    if ($isCut) {
                        $cm = New-Object System.Drawing.Imaging.ColorMatrix
                        $cm.Matrix33 = 0.45f
                        $ia = New-Object System.Drawing.Imaging.ImageAttributes
                        $ia.SetColorMatrix($cm)
                        try {
                            $g.DrawImage($item.Icon, (New-Object System.Drawing.Rectangle([int]$iconX, [int]$iconY, $iconSize, $iconSize)), 0, 0, $item.Icon.Width, $item.Icon.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
                        } finally { $ia.Dispose() }
                    } else {
                        $g.DrawImage($item.Icon, [int]$iconX, [int]$iconY, $iconSize, $iconSize)
                    }
                }

                # Subtle authentic Windows shortcut arrow badge on .lnk files
                if ($item.Path.EndsWith(".lnk", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $badgeX = $iconX + 2
                    $badgeY = $iconY + $iconSize - 13
                    $badgeRect = New-Object System.Drawing.Rectangle([int]$badgeX, [int]$badgeY, 12, 12)
                    $badgeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
                    $badgePen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1e293b"), 1)
                    $arrowPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#0284c7"), [float]2)
                    try {
                        $g.FillRectangle($badgeBrush, $badgeRect)
                        $g.DrawRectangle($badgePen, $badgeRect)
                        $g.DrawLine($arrowPen, [int]($badgeX + 2), [int]($badgeY + 9), [int]($badgeX + 9), [int]($badgeY + 2))
                        $g.DrawLine($arrowPen, [int]($badgeX + 5), [int]($badgeY + 2), [int]($badgeX + 9), [int]($badgeY + 2))
                        $g.DrawLine($arrowPen, [int]($badgeX + 9), [int]($badgeY + 2), [int]($badgeX + 9), [int]($badgeY + 6))
                    } finally { $badgeBrush.Dispose(); $badgePen.Dispose(); $arrowPen.Dispose() }
                }

                if (-not [string]::IsNullOrEmpty($item.Text)) {
                    $textY = $b.Y + $iconSize + 6
                    $textH = $labelHeight
                    $textRect = New-Object System.Drawing.RectangleF([float]($b.X + 2), [float]$textY, [float]($b.Width - 4), [float]$textH)
                    
                    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
                    try {
                        $shadowRect = New-Object System.Drawing.RectangleF([float]($textRect.X + 1), [float]($textRect.Y + 1), $textRect.Width, $textRect.Height)
                        $g.DrawString($item.Text, $script:desktopFont, $shadowBrush, $shadowRect, $sf)
                    } finally { $shadowBrush.Dispose() }
                    
                    $g.DrawString($item.Text, $script:desktopFont, $textBrush, $textRect, $sf)
                }
            }

            # 2. Lasso Selection Box (Precise 4-quadrant tracking)
            if ($script:isLassoing -and -not $script:lassoRect.IsEmpty) {
                $lassoFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 59, 130, 246))
                $lassoPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#3b82f6"), 1)
                try {
                    $g.FillRectangle($lassoFill, $script:lassoRect)
                    $g.DrawRectangle($lassoPen, $script:lassoRect)
                } finally {
                    $lassoFill.Dispose(); $lassoPen.Dispose()
                }
            }

            $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
            $cWidth = [int]$script:cellWidth; $cHeight = [int]$script:cellHeight

            # 3. Draw Grid Lines (if dragging with CTRL or AlignToGrid)
            if ($script:isDragging -and ($isCtrl -or $settings.AlignToGrid) -and $cWidth -gt 0 -and $cHeight -gt 0) {
                $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(35, 255, 255, 255), 1)
                $gridPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                try {
                    $gMargin = [int]($script:gridMargin * $settings.UiScale)
                    $cw = $Sender.ClientSize.Width; $ch = $Sender.ClientSize.Height
                    for ($gx = $gMargin; $gx -lt $cw; $gx += $cWidth) {
                        $g.DrawLine($gridPen, $gx, 0, $gx, $ch)
                    }
                    for ($gy = $gMargin; $gy -lt $ch; $gy += $cHeight) {
                        $g.DrawLine($gridPen, 0, $gy, $cw, $gy)
                    }
                } finally { $gridPen.Dispose() }
            }

            # 4. Drag Ghost Preview (Instant local grid snapping)
            if ($script:isDragging -and $script:selectedItems.Count -gt 0) {
                $ghostSelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(85, 59, 130, 246))
                $ghostBorderPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#3b82f6"), 1)
                $gMargin = [int]($script:gridMargin * $settings.UiScale)
                $fLeft = $Sender.Left; $fTop = $Sender.Top
                
                try {
                    foreach ($sel in $script:selectedItems) {
                        if ($null -eq $sel) { continue }
                        $orig = $script:dragOriginalPositions[$sel.Path]
                        $rawX = if ($null -ne $orig) { [int]$orig.X + [int]$script:dragDeltaX } else { [int]$sel.Bounds.X + [int]$script:dragDeltaX }
                        $rawY = if ($null -ne $orig) { [int]$orig.Y + [int]$script:dragDeltaY } else { [int]$sel.Bounds.Y + [int]$script:dragDeltaY }
                        
                        if ($isCtrl -or $settings.AlignToGrid) {
                            $relX = $rawX - $fLeft - $gMargin
                            $relY = $rawY - $fTop - $gMargin
                            $col = [int][Math]::Max(0, [Math]::Round($relX / [double]$cWidth))
                            $row = [int][Math]::Max(0, [Math]::Round($relY / [double]$cHeight))
                            $rawX = $fLeft + $gMargin + ($col * $cWidth)
                            $rawY = $fTop + $gMargin + ($row * $cHeight)
                        }
                        
                        $ghostRect = New-Object System.Drawing.Rectangle($rawX, $rawY, $sel.Bounds.Width, $sel.Bounds.Height)
                        if (-not $Sender.ClientRectangle.IntersectsWith($ghostRect)) { continue }
                        
                        $g.FillRectangle($ghostSelBrush, $ghostRect)
                        $g.DrawRectangle($ghostBorderPen, $ghostRect)

                        if ($null -ne $sel.Icon) {
                            $iconX = $ghostRect.X + (($ghostRect.Width - $iconSize) / 2)
                            $iconY = $ghostRect.Y + 4
                            $g.DrawImage($sel.Icon, [int]$iconX, [int]$iconY, $iconSize, $iconSize)
                        }
                        if (-not [string]::IsNullOrEmpty($sel.Text)) {
                            $textY = $ghostRect.Y + $iconSize + 6
                            $textH = $labelHeight
                            $textRect = New-Object System.Drawing.RectangleF([float]($ghostRect.X + 2), [float]$textY, [float]($ghostRect.Width - 4), [float]$textH)
                            
                            $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
                            try {
                                $shadowRect = New-Object System.Drawing.RectangleF([float]($textRect.X + 1), [float]($textRect.Y + 1), $textRect.Width, $textRect.Height)
                                $g.DrawString($sel.Text, $script:desktopFont, $shadowBrush, $shadowRect, $sf)
                            } finally { $shadowBrush.Dispose() }
                            
                            $g.DrawString($sel.Text, $script:desktopFont, $textBrush, $textRect, $sf)
                        }
                    }
                } finally {
                    if ($null -ne $ghostSelBrush) { $ghostSelBrush.Dispose() }
                    if ($null -ne $ghostBorderPen) { $ghostBorderPen.Dispose() }
                }
            }

            # 5. Desktop Glass Acrylic Widgets HUD (Clock, RAM & Storage)
            if ($settings.ShowWidgets -and $null -ne $script:primaryForm -and ($Sender.Handle -eq $script:primaryForm.Handle)) {
                $wWidth = [int](250 * $uiScale)
                $itemsCount = 0
                if ($settings.ShowWidgetClock) { $itemsCount += 2 }
                if ($settings.ShowWidgetSystem) { $itemsCount += 1 }
                if ($settings.ShowWidgetStorage) { $itemsCount += 1 }

                if ($itemsCount -gt 0) {
                    $wHeight = [int](30 * $uiScale)
                    if ($settings.ShowWidgetClock) { $wHeight += [int](65 * $uiScale) }
                    if ($settings.ShowWidgetSystem) { $wHeight += [int](48 * $uiScale) }
                    if ($settings.ShowWidgetStorage) { $wHeight += [int](48 * $uiScale) }

                    $margin = [int](25 * $uiScale)
                    $wX = $Sender.ClientSize.Width - $wWidth - $margin
                    $wY = $margin

                    if ($settings.WidgetPosition -eq "TopLeft") {
                        $wX = $margin
                        $wY = $margin
                    } elseif ($settings.WidgetPosition -eq "BottomRight") {
                        $wX = $Sender.ClientSize.Width - $wWidth - $margin
                        $wY = $Sender.ClientSize.Height - $wHeight - $margin
                    } elseif ($settings.WidgetPosition -eq "BottomLeft") {
                        $wX = $margin
                        $wY = $Sender.ClientSize.Height - $wHeight - $margin
                    }

                    $widgetRect = New-Object System.Drawing.Rectangle($wX, $wY, $wWidth, $wHeight)
                    [DesktopWidgetRenderer]::DrawWidget($g, $widgetRect, [float]$uiScale, [bool]$settings.ShowWidgetClock, [bool]$settings.ShowWidgetSystem, [bool]$settings.ShowWidgetStorage)
                }
            }
        } finally { if ($null -ne $hoverBrush) { $hoverBrush.Dispose() }; if ($null -ne $selBrush) { $selBrush.Dispose() }; if ($null -ne $textBrush) { $textBrush.Dispose() }; if ($null -ne $sf) { $sf.Dispose() } }
    } catch { }
}

# ============================================================
# 011 - DESKTOP INTERACTION ACTIONS & RECYCLE BIN
# ============================================================

function Dispose-DesktopControls {
    $script:desktopItems = @()
    if ($null -ne $script:desktopFont) { try { $script:desktopFont.Dispose() } catch {}; $script:desktopFont = $null }
}

function Open-DesktopItem {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if ($Path -eq "::{645FF040-5081-101B-9F08-00AA002F954E}" -or $Path -eq "shell:RecycleBinFolder") {
        Write-DesktopLog "ACTION: Opening Recycle Bin via explorer.exe" -Level "AUDIT"
        try { Start-Process "explorer.exe" -ArgumentList "shell:RecycleBinFolder" -ErrorAction SilentlyContinue } catch {}
        return
    }
    if (-not (Test-Path -LiteralPath $Path)) { 
        Write-DesktopLog "ACTION FAILED: Target item does not exist: '$Path'" -Level "WARN"
        return 
    }
    Write-DesktopLog "ACTION: Opening desktop item: '$Path'" -Level "AUDIT"
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Path
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-DesktopLog "ACTION SUCCESS: Launched process for '$Path'" -Level "AUDIT"
    } catch {
        try { 
            Invoke-Item -LiteralPath $Path -ErrorAction SilentlyContinue 
            Write-DesktopLog "ACTION SUCCESS: Invoked default item handler for '$Path'" -Level "AUDIT"
        } catch {
            Write-DesktopLog "ACTION ERROR: Failed to open item '$Path'" -Level "ERROR" -Exception $_.Exception
        }
    }
}

function Save-ItemPosition {
    param([string]$Path, [int]$X, [int]$Y, [switch]$NoSave)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $settings.Positions[$Path] = @{ X = $X; Y = $Y }
    if (-not $NoSave) { 
        Save-DesktopSettings
        Write-DesktopLog "LAYOUT: Saved custom position for '$Path' at ($X, $Y)" -Level "AUDIT"
    }
}

function Save-AllPositions {
    foreach ($item in $script:desktopItems) {
        if ($null -eq $item) { continue }
        Save-ItemPosition -Path $item.Path -X $item.Bounds.X -Y $item.Bounds.Y -NoSave
    }
    Save-DesktopSettings
    Write-DesktopLog "LAYOUT: Saved all $($script:desktopItems.Count) item positions to settings" -Level "AUDIT"
}

function Rename-DesktopItem {
    param([string]$Path)
    if ($Path -eq "::{645FF040-5081-101B-9F08-00AA002F954E}" -or -not (Test-Path -LiteralPath $Path)) { return }
    Write-DesktopLog "ACTION: Prompting rename dialog for item '$Path'" -Level "AUDIT"
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $dialog = New-Object System.Windows.Forms.Form
        $dialog.Width = 450; $dialog.Height = 180
        $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen; $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
        $dialog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181b")
        Enable-DoubleBuffer $dialog
        $dialog.Add_Paint({
            param($s, $e)
            $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#3f3f46"), 1)
            try { $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1) } finally { $pen.Dispose() }
        })

        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Rename Item"; $label.Left = 20; $label.Top = 20; $label.AutoSize = $true
        $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $label.ForeColor = [System.Drawing.Color]::White
        $dialog.Controls.Add($label)

        $box = New-Object System.Windows.Forms.TextBox
        $box.Left = 20; $box.Top = 60; $box.Width = 410; $box.Height = 28
        $box.Font = New-Object System.Drawing.Font("Segoe UI", 11); $box.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272a"); $box.ForeColor = [System.Drawing.Color]::White
        $box.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $box.Text = $item.Name
        $dialog.Controls.Add($box)

        $ok = New-Object System.Windows.Forms.Button
        $ok.Text = "Save"; $ok.Left = 220; $ok.Top = 120; $ok.Width = 100; $ok.Height = 35
        $ok.BackColor = $script:Colors.Accent; $ok.ForeColor = [System.Drawing.Color]::White; $ok.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $ok.FlatAppearance.BorderSize = 0
        $ok.Cursor = [System.Windows.Forms.Cursors]::Hand
        $ok.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563eb") }); $ok.Add_MouseLeave({ $this.BackColor = $script:Colors.Accent })
        $dialog.Controls.Add($ok)
        
        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = "Cancel"; $cancel.Left = 330; $cancel.Top = 120; $cancel.Width = 100; $cancel.Height = 35
        $cancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3f3f46"); $cancel.ForeColor = [System.Drawing.Color]::White; $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $cancel.FlatAppearance.BorderSize = 0
        $cancel.Cursor = [System.Windows.Forms.Cursors]::Hand
        $cancel.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#52525b") }); $cancel.Add_MouseLeave({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3f3f46") })
        $dialog.Controls.Add($cancel)

        Enable-FormDragging $dialog @($label)

        $dialog.AcceptButton = $ok; $dialog.CancelButton = $cancel
        $ok.Add_Click({
            $newName = $box.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($newName)) { return }
            if (-not $item.PSIsContainer -and -not [string]::IsNullOrEmpty($item.Extension)) {
                if ($newName -notmatch "\.") { $newName += $item.Extension }
            }
            try {
                Rename-Item -LiteralPath $Path -NewName $newName -ErrorAction Stop
                $newPath = Join-Path (Split-Path -Parent $Path) $newName
                if ($settings.Positions.ContainsKey($Path)) {
                    $oldPosition = $settings.Positions[$Path]; $settings.Positions.Remove($Path)
                    $settings.Positions[$newPath] = @{ X = [int]$oldPosition.X; Y = [int]$oldPosition.Y }
                }
                Save-DesktopSettings; Clear-Selection; $dialog.Close()
                Write-DesktopLog "ACTION SUCCESS: Renamed '$Path' -> '$newPath'" -Level "AUDIT"
            } catch { 
                Write-DesktopLog "ACTION ERROR: Failed to rename '$Path' to '$newName'" -Level "ERROR" -Exception $_.Exception
                [System.Windows.Forms.MessageBox]::Show("Could not rename the item.", "Rename", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null 
            }
        })
        $cancel.Add_Click({ 
            Write-DesktopLog "ACTION: Rename dialog canceled by user" -Level "AUDIT"
            $dialog.Close() 
        })
        
        if (-not $item.PSIsContainer -and -not [string]::IsNullOrEmpty($item.Extension)) {
            $box.Select(0, $item.Name.Length - $item.Extension.Length)
        } else {
            $box.SelectAll()
        }
        $box.Focus(); [void]$dialog.ShowDialog(); $dialog.Dispose()
    } catch { }
}

function Delete-DesktopItems {
    $realItems = @($script:selectedItems | Where-Object { $_.Path -ne "::{645FF040-5081-101B-9F08-00AA002F954E}" })
    if ($realItems.Count -eq 0) { return }
    try {
        $count = $realItems.Count
        Write-DesktopLog "ACTION: User requested delete for $count item(s)" -Level "AUDIT"
        $msg = if ($count -eq 1) { "Move this item to the Recycle Bin?" } else { "Move these $count items to the Recycle Bin?" }
        $result = [System.Windows.Forms.MessageBox]::Show($msg, "Delete", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) { 
            Write-DesktopLog "ACTION: Delete confirmation declined by user" -Level "AUDIT"
            return 
        }
        
        $shell = New-Object -ComObject Shell.Application
        try {
            foreach ($item in $realItems) {
                $path = [string]$item.Path
                if (-not (Test-Path -LiteralPath $path)) { continue }
                $folder = $shell.Namespace((Split-Path -Parent $path)); $shellItem = $folder.ParseName((Split-Path -Leaf $path))
                if ($null -ne $shellItem) { $shellItem.InvokeVerb("delete") }
                if ($settings.Positions.ContainsKey($path)) { $settings.Positions.Remove($path) }
                Write-DesktopLog "ACTION SUCCESS: Moved '$path' to Recycle Bin" -Level "AUDIT"
            }
        } finally {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        Save-DesktopSettings; Clear-Selection; Refresh-Desktop
    } catch { 
        Write-DesktopLog "ACTION ERROR: Delete-DesktopItems failed" -Level "ERROR" -Exception $_.Exception
    }
}

function Show-ItemProperties {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    Write-DesktopLog "ACTION: Requesting Windows Properties dialog for '$Path'" -Level "AUDIT"
    try {
        $owner = if ($null -ne $script:primaryForm) { $script:primaryForm.Handle } else { [IntPtr]::Zero }
        [ShellIcons]::ShowProperties($Path, $owner)
        Write-DesktopLog "ACTION SUCCESS: Windows Properties dialog displayed for '$Path'" -Level "AUDIT"
    } catch {
        Write-DesktopLog "ACTION ERROR: Failed to show properties for '$Path'" -Level "ERROR" -Exception $_.Exception
    }
}

function Copy-SelectedFiles {
    $realItems = @($script:selectedItems | Where-Object { $_.Path -ne "::{645FF040-5081-101B-9F08-00AA002F954E}" })
    if ($realItems.Count -eq 0) { return }
    try {
        $script:cutFiles = @()
        $paths = New-Object System.Collections.Specialized.StringCollection
        foreach ($item in $realItems) {
            $path = [string]$item.Path
            if (-not [string]::IsNullOrWhiteSpace($path)) { [void]$paths.Add($path) }
        }
        if ($paths.Count -gt 0) { 
            [System.Windows.Forms.Clipboard]::SetFileDropList($paths) 
            Write-DesktopLog "ACTION: Copied $($paths.Count) item(s) to Windows clipboard" -Level "AUDIT"
        }
    } catch { }
}

function Cut-SelectedFiles {
    $realItems = @($script:selectedItems | Where-Object { $_.Path -ne "::{645FF040-5081-101B-9F08-00AA002F954E}" })
    if ($realItems.Count -eq 0) { return }
    try {
        $script:cutFiles = @()
        $paths = New-Object System.Collections.Specialized.StringCollection
        foreach ($item in $realItems) {
            $path = [string]$item.Path
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                $script:cutFiles += $path
                [void]$paths.Add($path)
            }
        }
        if ($paths.Count -gt 0) { 
            [System.Windows.Forms.Clipboard]::SetFileDropList($paths) 
            Write-DesktopLog "ACTION: Cut $($paths.Count) item(s) to Windows clipboard" -Level "AUDIT"
        }
        Invalidate-AllDesktopForms
    } catch { }
}

function Paste-ClipboardFiles {
    $now = [Environment]::TickCount
    if ($script:isPasting -or [Math]::Abs($now - $script:lastPasteTime) -lt 250) { return }
    $script:lastPasteTime = $now
    $script:isPasting = $true
    Write-DesktopLog "ACTION: Paste clipboard files initiated..." -Level "AUDIT"
    try {
        $refreshNeeded = $false
        
        if ($null -ne $script:cutFiles -and $script:cutFiles.Count -gt 0) {
            $currentCut = @($script:cutFiles)
            $script:cutFiles = @()
            foreach ($cutPath in $currentCut) {
                if (-not (Test-Path -LiteralPath $cutPath)) { continue }
                $leaf = Split-Path -Leaf $cutPath
                $dest = Join-Path $script:desktopPath $leaf
                if ($cutPath -ne $dest) {
                    try {
                        Move-Item -LiteralPath $cutPath -Destination $dest -Force -ErrorAction Stop
                        $refreshNeeded = $true
                        Write-DesktopLog "ACTION SUCCESS: Moved cut file '$cutPath' -> '$dest'" -Level "AUDIT"
                    } catch {}
                }
            }
        }
        
        $dataObj = $null
        for ($retry = 0; $retry -lt 3; $retry++) {
            try {
                $dataObj = [System.Windows.Forms.Clipboard]::GetDataObject()
                if ($null -ne $dataObj) { break }
            } catch {
                [System.Threading.Thread]::Sleep(20)
            }
        }
        
        if ($null -ne $dataObj) {
            try {
                $extracted = [OleDropHelper]::ExtractFiles($dataObj, $script:desktopPath)
                if ($null -ne $extracted -and $extracted.Count -gt 0) {
                    $refreshNeeded = $true
                    Write-DesktopLog "ACTION SUCCESS: Pasted $($extracted.Count) file(s) via OLE drop extractor" -Level "AUDIT"
                }
            } catch {}
            
            if (-not $refreshNeeded) {
                try {
                    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
                        $img = [System.Windows.Forms.Clipboard]::GetImage()
                        if ($null -ne $img) {
                            $c = 1
                            $imgName = "Pasted Image.png"
                            $imgPath = Join-Path $script:desktopPath $imgName
                            while (Test-Path -LiteralPath $imgPath) {
                                $c++
                                $imgPath = Join-Path $script:desktopPath "Pasted Image ($c).png"
                            }
                            $img.Save($imgPath, [System.Drawing.Imaging.ImageFormat]::Png)
                            $img.Dispose()
                            $refreshNeeded = $true
                            Write-DesktopLog "ACTION SUCCESS: Saved clipboard image to '$imgPath'" -Level "AUDIT"
                        }
                    }
                } catch {}
            }
            
            if (-not $refreshNeeded) {
                try {
                    if ([System.Windows.Forms.Clipboard]::ContainsText()) {
                        $txt = [System.Windows.Forms.Clipboard]::GetText()
                        if (-not [string]::IsNullOrWhiteSpace($txt)) {
                            $lines = $txt.Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries)
                            $allExist = $true
                            foreach ($l in $lines) {
                                $p = $l.Trim('"', "'", " ")
                                if (-not (Test-Path -LiteralPath $p)) { $allExist = $false; break }
                            }
                            if ($allExist -and $lines.Count -gt 0) {
                                foreach ($l in $lines) {
                                    $p = $l.Trim('"', "'", " ")
                                    $leaf = Split-Path -Leaf $p
                                    $dest = Join-Path $script:desktopPath $leaf
                                    Copy-Item -LiteralPath $p -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
                                    Write-DesktopLog "ACTION SUCCESS: Copied file from text path '$p' -> '$dest'" -Level "AUDIT"
                                }
                                $refreshNeeded = $true
                            }
                        }
                    }
                } catch {}
            }
        }

        if ($refreshNeeded) {
            Refresh-Desktop
        }
    } catch { }
    finally {
        $script:isPasting = $false
    }
}

function New-DesktopFolder {
    try {
        $number = 0
        do { if ($number -eq 0) { $name = "New Folder" } else { $name = "New Folder ($number)" }; $path = Join-Path $script:desktopPath $name; $number++ } while (Test-Path -LiteralPath $path)
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-DesktopLog "ACTION SUCCESS: Created new folder '$path'" -Level "AUDIT"
        Refresh-Desktop
    } catch { 
        Write-DesktopLog "ACTION ERROR: Failed to create new folder" -Level "ERROR" -Exception $_.Exception
    }
}

function New-DesktopTextFile {
    try {
        $number = 0
        do { if ($number -eq 0) { $name = "New Text Document.txt" } else { $name = "New Text Document ($number).txt" }; $path = Join-Path $script:desktopPath $name; $number++ } while (Test-Path -LiteralPath $path)
        [System.IO.File]::WriteAllText($path, "")
        Write-DesktopLog "ACTION SUCCESS: Created new text document '$path'" -Level "AUDIT"
        Refresh-Desktop
    } catch { 
        Write-DesktopLog "ACTION ERROR: Failed to create new text file" -Level "ERROR" -Exception $_.Exception
    }
}

# ============================================================
# 012 - CONTEXT MENUS (DISPOSAL SAFE & THEMED)
# ============================================================

function Create-ContextMenus {
    $uiScale = 1.0; if ($null -ne $settings.UiScale) { $uiScale = [double]$settings.UiScale }

    if ($null -ne $script:contextMenu) { try { $script:contextMenu.Dispose() } catch {} }
    if ($null -ne $script:itemContextMenu) { try { $script:itemContextMenu.Dispose() } catch {} }
    if ($null -ne $script:recycleBinContextMenu) { try { $script:recycleBinContextMenu.Dispose() } catch {} }

    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.MaximumSize = New-Object System.Drawing.Size(0, [int]([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height * 0.9))
    $menu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    $menu.ForeColor = [System.Drawing.Color]::White
    $menu.ShowImageMargin = $true; $menu.ShowCheckMargin = $false
    $menu.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale))
    try { $menu.Renderer = New-Object DarkMenuRenderer } catch { }

    function Add-MenuItem($M, $Txt, $Key, $Act, $Checked = $null) {
        $i = if ($M -is [System.Windows.Forms.ToolStripMenuItem]) { $M.DropDownItems.Add($Txt) } else { $M.Items.Add($Txt) }
        $i.ForeColor = [System.Drawing.Color]::White
        if ($null -ne $Key) { $i.ShortcutKeyDisplayString = $Key; $i.ShowShortcutKeys = $true }
        if ($null -ne $Checked) {
            $i.CheckOnClick = $false
            $i.Checked = [bool]$Checked
        }
        if ($null -ne $Act) { $i.Add_Click($Act) }
        return $i
    }

    # View Submenu
    $viewMenu = New-Object System.Windows.Forms.ToolStripMenuItem("View")
    $viewMenu.ForeColor = [System.Drawing.Color]::White
    $viewMenu.DropDown.ShowImageMargin = $true; $viewMenu.DropDown.ShowCheckMargin = $false
    try { $viewMenu.DropDown.Renderer = New-Object DarkMenuRenderer } catch {}

    Add-MenuItem $viewMenu "Large icons" $null { Write-DesktopLog "MENU: Selected View -> Large icons (96px)" -Level "AUDIT"; $settings.IconScale = 96; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop } ($settings.IconScale -ge 96) | Out-Null
    Add-MenuItem $viewMenu "Medium icons" $null { Write-DesktopLog "MENU: Selected View -> Medium icons (72px)" -Level "AUDIT"; $settings.IconScale = 72; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop } ($settings.IconScale -ge 64 -and $settings.IconScale -lt 96) | Out-Null
    Add-MenuItem $viewMenu "Small icons" $null { Write-DesktopLog "MENU: Selected View -> Small icons (48px)" -Level "AUDIT"; $settings.IconScale = 48; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop } ($settings.IconScale -lt 64) | Out-Null
    [void]$viewMenu.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $viewMenu "Auto arrange icons" $null { 
        $settings.AutoArrange = $false
        $settings.Positions = @{}
        Write-DesktopLog "MENU: Selected View -> Auto arrange icons (cleared saved positions)" -Level "AUDIT"
        Save-DesktopSettings; Refresh-Desktop 
    } | Out-Null
    
    Add-MenuItem $viewMenu "Align icons to grid" $null { 
        Write-DesktopLog "MENU: Selected View -> Align icons to grid" -Level "AUDIT"
        $occupiedMap = @{}
        foreach ($item in $script:desktopItems) {
            if ($null -eq $item) { continue }
            $slot = Find-NearestFreeGridSlot $item.Bounds.X $item.Bounds.Y $occupiedMap
            $snapX = $slot.X
            $snapY = $slot.Y
            $item.Bounds = New-Object System.Drawing.Rectangle($snapX, $snapY, $item.Bounds.Width, $item.Bounds.Height)
            Save-ItemPosition -Path $item.Path -X $snapX -Y $snapY -NoSave
        }
        Save-DesktopSettings; Refresh-Desktop 
    } | Out-Null
    
    [void]$viewMenu.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $viewMenu "Show desktop icons" $null { $settings.ShowDesktopIcons = -not $settings.ShowDesktopIcons; Write-DesktopLog "MENU: Toggled Show desktop icons -> $($settings.ShowDesktopIcons)" -Level "AUDIT"; Save-DesktopSettings; Refresh-Desktop } ($settings.ShowDesktopIcons) | Out-Null
    Add-MenuItem $viewMenu "Show Recycle Bin" $null { $settings.ShowRecycleBin = -not $settings.ShowRecycleBin; Write-DesktopLog "MENU: Toggled Show Recycle Bin -> $($settings.ShowRecycleBin)" -Level "AUDIT"; Save-DesktopSettings; Refresh-Desktop } ($settings.ShowRecycleBin) | Out-Null
    [void]$menu.Items.Add($viewMenu)

    # Sort By Submenu
    $sortMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Sort by")
    $sortMenu.ForeColor = [System.Drawing.Color]::White
    $sortMenu.DropDown.ShowImageMargin = $true; $sortMenu.DropDown.ShowCheckMargin = $false
    try { $sortMenu.DropDown.Renderer = New-Object DarkMenuRenderer } catch {}

    Add-MenuItem $sortMenu "Name" $null { $settings.SortBy = "Name"; $settings.Positions = @{}; Write-DesktopLog "MENU: Selected Sort by -> Name" -Level "AUDIT"; Save-DesktopSettings; Refresh-Desktop } ($settings.SortBy -eq "Name") | Out-Null
    Add-MenuItem $sortMenu "Size" $null { $settings.SortBy = "Size"; $settings.Positions = @{}; Write-DesktopLog "MENU: Selected Sort by -> Size" -Level "AUDIT"; Save-DesktopSettings; Refresh-Desktop } ($settings.SortBy -eq "Size") | Out-Null
    Add-MenuItem $sortMenu "Date modified" $null { $settings.SortBy = "Date"; $settings.Positions = @{}; Write-DesktopLog "MENU: Selected Sort by -> Date modified" -Level "AUDIT"; Save-DesktopSettings; Refresh-Desktop } ($settings.SortBy -eq "Date") | Out-Null
    [void]$menu.Items.Add($sortMenu)

    Add-MenuItem $menu "Refresh" "F5" { Write-DesktopLog "MENU: Selected Refresh (F5)" -Level "AUDIT"; Refresh-Desktop } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $menu "Paste" "Ctrl+V" { Write-DesktopLog "MENU: Selected Paste (Ctrl+V)" -Level "AUDIT"; Paste-ClipboardFiles } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $newMenu = New-Object System.Windows.Forms.ToolStripMenuItem("New")
    $newMenu.ForeColor = [System.Drawing.Color]::White
    $newMenu.DropDown.ShowImageMargin = $false; $newMenu.DropDown.ShowCheckMargin = $false
    try { $newMenu.DropDown.Renderer = New-Object DarkMenuRenderer } catch {}

    Add-MenuItem $newMenu "Folder" "Ctrl+Shift+N" { Write-DesktopLog "MENU: Selected New -> Folder" -Level "AUDIT"; New-DesktopFolder } | Out-Null
    Add-MenuItem $newMenu "Text Document" $null { Write-DesktopLog "MENU: Selected New -> Text Document" -Level "AUDIT"; New-DesktopTextFile } | Out-Null
    [void]$menu.Items.Add($newMenu)
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    Add-MenuItem $menu "Settings" "Ctrl+P" { Write-DesktopLog "MENU: Selected Settings (Ctrl+P)" -Level "AUDIT"; Show-Settings } | Out-Null
    $script:contextMenu = $menu

    # Item Context Menu
    $itemMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $itemMenu.MaximumSize = New-Object System.Drawing.Size(0, [int]([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height * 0.9))
    $itemMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    $itemMenu.ForeColor = [System.Drawing.Color]::White
    $itemMenu.ShowImageMargin = $false; $itemMenu.ShowCheckMargin = $false
    $itemMenu.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale))
    try { $itemMenu.Renderer = New-Object DarkMenuRenderer } catch { }

    Add-MenuItem $itemMenu "Open" "Enter" { 
        Write-DesktopLog "MENU: Selected Open for $($script:selectedItems.Count) item(s)" -Level "AUDIT"
        foreach ($item in $script:selectedItems) { 
            $path = [string]$item.Path; if (-not [string]::IsNullOrWhiteSpace($path)) { Open-DesktopItem $path }
        } 
    } | Out-Null
    Add-MenuItem $itemMenu "Edit" $null { 
        Write-DesktopLog "MENU: Selected Edit in Notepad for $($script:selectedItems.Count) item(s)" -Level "AUDIT"
        foreach ($item in $script:selectedItems) { 
            $path = [string]$item.Path; if (-not [string]::IsNullOrWhiteSpace($path) -and -not (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue).PSIsContainer) { try { Start-Process "notepad.exe" -ArgumentList "`"$path`"" -ErrorAction SilentlyContinue } catch { } }
        } 
    } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $itemMenu "Cut" "Ctrl+X" { Write-DesktopLog "MENU: Selected Cut for $($script:selectedItems.Count) item(s)" -Level "AUDIT"; Cut-SelectedFiles } | Out-Null
    Add-MenuItem $itemMenu "Copy" "Ctrl+C" { Write-DesktopLog "MENU: Selected Copy for $($script:selectedItems.Count) item(s)" -Level "AUDIT"; Copy-SelectedFiles } | Out-Null
    Add-MenuItem $itemMenu "Compress to ZIP file" $null {
        $real = @($script:selectedItems | Where-Object { $_.Path -ne "::{645FF040-5081-101B-9F08-00AA002F954E}" })
        if ($real.Count -eq 0) { return }
        Write-DesktopLog "MENU: Selected Compress to ZIP for $($real.Count) item(s)" -Level "AUDIT"
        try {
            $paths = @()
            foreach ($item in $real) {
                if (-not [string]::IsNullOrWhiteSpace($item.Path)) { $paths += $item.Path }
            }
            if ($paths.Count -gt 0) {
                $baseName = if ($paths.Count -eq 1) { [System.IO.Path]::GetFileNameWithoutExtension($paths[0]) } else { "Archive" }
                $zipPath = Join-Path $script:desktopPath "$baseName.zip"
                $i = 1; while (Test-Path -LiteralPath $zipPath) { $zipPath = Join-Path $script:desktopPath "$baseName ($i).zip"; $i++ }
                Compress-Archive -LiteralPath $paths -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue
                Write-DesktopLog "ACTION SUCCESS: Compressed $($paths.Count) items to '$zipPath'" -Level "AUDIT"
                Refresh-Desktop
            }
        } catch { 
            Write-DesktopLog "ACTION ERROR: Compress to ZIP failed" -Level "ERROR" -Exception $_.Exception
        }
    } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $itemMenu "Rename" "F2" { 
        Write-DesktopLog "MENU: Selected Rename" -Level "AUDIT"
        if ($script:selectedItems.Count -eq 1) { 
            $p = [string]$script:selectedItems[0].Path; if (-not [string]::IsNullOrWhiteSpace($p)) { Rename-DesktopItem $p }
        }
    } | Out-Null
    Add-MenuItem $itemMenu "Delete" "Del" { Write-DesktopLog "MENU: Selected Delete" -Level "AUDIT"; Delete-DesktopItems } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $itemMenu "Properties" "Alt+Enter" { 
        Write-DesktopLog "MENU: Selected Properties" -Level "AUDIT"
        $p = if ($script:selectedItems.Count -gt 0) { [string]$script:selectedItems[0].Path } else { [string]$script:itemContextMenu.Tag }
        if (-not [string]::IsNullOrWhiteSpace($p)) { Show-ItemProperties $p } 
    } | Out-Null
    $script:itemContextMenu = $itemMenu

    # Recycle Bin Special Context Menu
    $rbMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $rbMenu.MaximumSize = New-Object System.Drawing.Size(0, [int]([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height * 0.9))
    $rbMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    $rbMenu.ForeColor = [System.Drawing.Color]::White
    $rbMenu.ShowImageMargin = $false; $rbMenu.ShowCheckMargin = $false
    $rbMenu.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale))
    try { $rbMenu.Renderer = New-Object DarkMenuRenderer } catch { }

    Add-MenuItem $rbMenu "Open" "Enter" { Write-DesktopLog "MENU: Selected Open Recycle Bin" -Level "AUDIT"; Open-DesktopItem "shell:RecycleBinFolder" } | Out-Null
    Add-MenuItem $rbMenu "Empty Recycle Bin" $null { 
        Write-DesktopLog "MENU: Selected Empty Recycle Bin" -Level "AUDIT"
        $owner = if ($null -ne $script:primaryForm) { $script:primaryForm.Handle } else { [IntPtr]::Zero }
        [CustomDesktopForm]::EmptyRecycleBin($owner)
        Write-DesktopLog "ACTION SUCCESS: Empty Recycle Bin Win32 API executed" -Level "AUDIT"
        Refresh-Desktop
    } | Out-Null
    [void]$rbMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $rbMenu "Properties" "Alt+Enter" { Write-DesktopLog "MENU: Selected Recycle Bin Properties" -Level "AUDIT"; Show-ItemProperties "::{645FF040-5081-101B-9F08-00AA002F954E}" } | Out-Null
    $script:recycleBinContextMenu = $rbMenu

    foreach ($f in $script:forms) {
        if ($null -ne $f -and -not $f.IsDisposed) {
            $f.ContextMenuStrip = $script:contextMenu
        }
    }
}

# ============================================================
# 013 - REFRESH & RICH SETTINGS UI (MODERN SCROLLBAR)
# ============================================================

function Refresh-Desktop {
    if ($script:refreshing) { return }
    $script:refreshing = $true
    try {
        if (-not (Test-Path -LiteralPath $script:desktopPath)) {
            $script:desktopPath = Join-Path $env:USERPROFILE "Desktop"
        }
        Apply-Background
        Create-ContextMenus
        Build-DesktopIcons
        Invalidate-AllDesktopForms
    } finally { $script:refreshing = $false }
}

function Show-Settings {
    if ($null -ne $script:settingsForm) {
        try {
            if (-not $script:settingsForm.IsDisposed) {
                $script:settingsForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
                $script:settingsForm.BringToFront()
                $script:settingsForm.Activate()
                [WinDInterceptor]::SetForegroundWindow($script:settingsForm.Handle)
                return
            }
        } catch { }
        $script:settingsForm = $null
    }

    $uiScale = 1.0; if ($null -ne $settings.UiScale) { $uiScale = [double]$settings.UiScale }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "RedSkia.Dev Settings"
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.Width = [int](560 * $uiScale); $form.Height = [int](730 * $uiScale)
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    $form.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.25 * $uiScale), [System.Drawing.FontStyle]::Regular)
    $form.KeyPreview = $true
    $form.TopMost = $true
    Enable-DoubleBuffer $form

    $form.Add_KeyDown({
        param($s, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $form.Close()
            $e.Handled = $true
        }
    })

    $form.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#334155"), 1)
        try { $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1) } finally { $pen.Dispose() }
    })

    # Modern Acrylic Header Bar
    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = [System.Windows.Forms.DockStyle]::Top
    $header.Height = [int](72 * $uiScale)
    $header.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    $header.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1e293b"), 1)
        try { $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1) } finally { $pen.Dispose() }
    })
    
    $title = New-Object System.Windows.Forms.Label
    $title.Text = "RedSkia.Dev Settings"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", [float](13.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $title.AutoSize = $true
    $title.Left = [int](22 * $uiScale); $title.Top = [int](14 * $uiScale)
    $header.Controls.Add($title)

    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = "Personalize wallpaper, layout, HUD widgets & stealth panic mode"
    $subtitle.Font = New-Object System.Drawing.Font("Segoe UI", [float](8.5 * $uiScale))
    $subtitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8")
    $subtitle.AutoSize = $true
    $subtitle.Left = [int](22 * $uiScale); $subtitle.Top = [int](42 * $uiScale)
    $header.Controls.Add($subtitle)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "X"
    $closeBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](10 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $closeBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8")
    $closeBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeBtn.FlatAppearance.BorderSize = 0
    $closeBtn.Width = [int](36 * $uiScale); $closeBtn.Height = [int](36 * $uiScale)
    $closeBtn.Left = $form.Width - [int](48 * $uiScale); $closeBtn.Top = [int](14 * $uiScale)
    $closeBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $closeBtn.Add_MouseEnter({ $closeBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444") })
    $closeBtn.Add_MouseLeave({ $closeBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8") })
    $closeBtn.Add_Click({ $form.Close() })
    $header.Controls.Add($closeBtn)

    Enable-FormDragging $form @($header, $title, $subtitle)
    $form.Controls.Add($header)

    # Modern Outer Container Panel (Zero Win95 Scrollbars)
    $body = New-Object System.Windows.Forms.Panel
    $body.Dock = [System.Windows.Forms.DockStyle]::Fill
    $body.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    $body.AutoScroll = $false
    Enable-DoubleBuffer $body
    $form.Controls.Add($body)
    $body.BringToFront()

    # Inner Movable Content Panel
    $content = New-Object System.Windows.Forms.Panel
    $content.Left = 0; $content.Top = 0; $content.Width = $body.Width - [int](14 * $uiScale)
    $content.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    Enable-DoubleBuffer $content
    $body.Controls.Add($content)

    # Modern Rounded Dark Scrollbar
    $scrollBar = New-Object ModernScrollBar
    $scrollBar.Left = $body.Width - [int](10 * $uiScale)
    $scrollBar.Top = 0
    $scrollBar.Width = [int](8 * $uiScale)
    $scrollBar.Height = $body.Height
    $scrollBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $body.Controls.Add($scrollBar)

    $scrollBar.Add_ValueChanged({
        $content.Top = -$scrollBar.Value
    })

    $cardW = [int](505 * $uiScale)
    $script:currY = [int](16 * $uiScale)

    function Add-SettingsCard([string]$CardTitle, [int]$CardHeight, [string]$AccentColor = "#3b82f6") {
        $c = New-Object System.Windows.Forms.Panel
        $c.Left = [int](15 * $uiScale); $c.Top = $script:currY; $c.Width = $cardW; $c.Height = [int]($CardHeight * $uiScale)
        $c.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827")
        Enable-DoubleBuffer $c
        $c.Add_Paint({
            param($s, $e)
            $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $borderPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1e293b"), 1)
            $accentBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($AccentColor))
            try { 
                $e.Graphics.DrawRectangle($borderPen, 0, 0, $s.Width - 1, $s.Height - 1)
                $e.Graphics.FillRectangle($accentBrush, 0, [int](12 * $uiScale), [int](3 * $uiScale), [int](16 * $uiScale))
            } finally { 
                $borderPen.Dispose()
                $accentBrush.Dispose()
            }
        })
        
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $CardTitle
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](10.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
        $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc")
        $lbl.AutoSize = $true
        $lbl.Left = [int](14 * $uiScale); $lbl.Top = [int](11 * $uiScale)
        $c.Controls.Add($lbl)
        $content.Controls.Add($c)
        $script:currY += [int](($CardHeight + 16) * $uiScale)
        return $c
    }

    # Card 1: Background & Wallpaper Engine (Signature RedSkia.Dev Branding Included)
    $cardBg = Add-SettingsCard "Desktop Background & Wallpaper" 310 "#ef4444"
    $rbBrand = New-Object ModernRadioButton; $rbBrand.Text = "RedSkia.Dev (Default)"; $rbBrand.Left = [int](15 * $uiScale); $rbBrand.Top = [int](42 * $uiScale); $rbBrand.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $rbColor = New-Object ModernRadioButton; $rbColor.Text = "Solid Color"; $rbColor.Left = [int](180 * $uiScale); $rbColor.Top = [int](42 * $uiScale); $rbColor.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $rbImage = New-Object ModernRadioButton; $rbImage.Text = "Image / Wallpaper"; $rbImage.Left = [int](295 * $uiScale); $rbImage.Top = [int](42 * $uiScale); $rbImage.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    
    if ($settings.BackgroundType -eq "Image") { $rbImage.Checked = $true } 
    elseif ($settings.BackgroundType -eq "Color") { $rbColor.Checked = $true }
    else { $rbBrand.Checked = $true }

    $cardBg.Controls.Add($rbBrand); $cardBg.Controls.Add($rbColor); $cardBg.Controls.Add($rbImage)

    # Top 10 Vibrant Rainbow Palette Swatches + Dark Neutrals
    $rainbowHexes = @("#ef4444", "#f97316", "#eab308", "#84cc16", "#10b981", "#06b6d4", "#3b82f6", "#6366f1", "#a855f7", "#ec4899", "#0f172a", "#040306")
    $swatchX = [int](15 * $uiScale)
    foreach ($colHex in $rainbowHexes) {
        $sw = New-Object System.Windows.Forms.Panel
        $sw.Left = $swatchX; $sw.Top = [int](76 * $uiScale); $sw.Width = [int](22 * $uiScale); $sw.Height = [int](22 * $uiScale)
        $sw.BackColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
        $sw.Cursor = [System.Windows.Forms.Cursors]::Hand
        $sw.Tag = $colHex
        $sw.Add_Click({
            $settings.BackgroundColor = $this.Tag
            $settings.BackgroundType = "Color"
            $rbColor.Checked = $true
            Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms
        })
        $cardBg.Controls.Add($sw)
        $swatchX += [int](26 * $uiScale)
    }

    $colorBtn = New-Object System.Windows.Forms.Button
    $colorBtn.Text = "Pick Custom Color..."
    $colorBtn.Left = [int](15 * $uiScale); $colorBtn.Top = [int](112 * $uiScale); $colorBtn.Width = [int](215 * $uiScale); $colorBtn.Height = [int](32 * $uiScale)
    $colorBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $colorBtn.FlatAppearance.BorderSize = 1; $colorBtn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $colorBtn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $colorBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc"); $colorBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $colorBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $colorBtn.Add_Click({
        $cd = New-Object System.Windows.Forms.ColorDialog
        $cd.Color = [System.Drawing.ColorTranslator]::FromHtml($settings.BackgroundColor)
        if ($cd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $settings.BackgroundColor = [System.Drawing.ColorTranslator]::ToHtml($cd.Color)
            $settings.BackgroundType = "Color"
            $rbColor.Checked = $true
            Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms
        }
        $cd.Dispose()
    })
    $cardBg.Controls.Add($colorBtn)

    $browseBtn = New-Object System.Windows.Forms.Button
    $browseBtn.Text = "Browse Image / Video / GIF..."
    $browseBtn.Left = [int](245 * $uiScale); $browseBtn.Top = [int](112 * $uiScale); $browseBtn.Width = [int](225 * $uiScale); $browseBtn.Height = [int](32 * $uiScale)
    $browseBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $browseBtn.FlatAppearance.BorderSize = 1; $browseBtn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $browseBtn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $browseBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc"); $browseBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $browseBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $browseBtn.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "All Supported Media (*.jpg;*.png;*.gif;*.webp;*.mp4;*.wmv;*.avi;*.mov;*.mkv;*.webm;*.flv;*.m4v)|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.jfif;*.mp4;*.wmv;*.avi;*.mov;*.mkv;*.webm;*.flv;*.m4v;*.mpg;*.mpeg;*.3gp;*.ts|Video Wallpapers (*.mp4;*.wmv;*.avi;*.mov;*.mkv;*.webm;*.flv;*.m4v)|*.mp4;*.wmv;*.avi;*.mov;*.mkv;*.webm;*.flv;*.m4v;*.mpg;*.mpeg;*.3gp;*.ts|Animated Images (*.gif;*.webp)|*.gif;*.webp|Static Images (*.jpg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp;*.jfif|All Files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $settings.ImagePath = $ofd.FileName
            $settings.BackgroundType = "Image"
            $rbImage.Checked = $true
            Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms
        }
        $ofd.Dispose()
    })
    $cardBg.Controls.Add($browseBtn)

    # Fit Mode selector
    $fitLbl = New-Object System.Windows.Forms.Label; $fitLbl.Text = "Image Fit Mode:"; $fitLbl.Left = [int](15 * $uiScale); $fitLbl.Top = [int](160 * $uiScale); $fitLbl.AutoSize = $true; $fitLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    $cardBg.Controls.Add($fitLbl)

    $fitCombo = New-Object ModernComboBox
    $fitCombo.Left = [int](135 * $uiScale); $fitCombo.Top = [int](155 * $uiScale); $fitCombo.Width = [int](140 * $uiScale)
    [void]$fitCombo.Items.AddRange(@("Fill", "Fit", "Stretch", "Tile", "Center"))
    $fitCombo.SelectedItem = $settings.ImageMode
    $fitCombo.Add_SelectedIndexChanged({
        $settings.ImageMode = [string]$fitCombo.SelectedItem
        Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms
    })
    $cardBg.Controls.Add($fitCombo)

    # Wallpaper Dimming Slider & Presets
    $dimLbl = New-Object System.Windows.Forms.Label; $dimLbl.Text = "Wallpaper Dimming: $($settings.WallpaperDimming)%"; $dimLbl.Left = [int](15 * $uiScale); $dimLbl.Top = [int](202 * $uiScale); $dimLbl.AutoSize = $true; $dimLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    $cardBg.Controls.Add($dimLbl)

    $dimTrack = New-Object NoScrollTrackBar
    $dimTrack.Minimum = 0; $dimTrack.Maximum = 80; $dimTrack.Value = [Math]::Max(0, [Math]::Min(80, [int]$settings.WallpaperDimming))
    $dimTrack.Left = [int](195 * $uiScale); $dimTrack.Top = [int](196 * $uiScale); $dimTrack.Width = [int](275 * $uiScale)
    $dimTrack.TickFrequency = 10
    $cardBg.Controls.Add($dimTrack)

    $dimTrack.Add_Scroll({
        $dimLbl.Text = "Wallpaper Dimming: $($dimTrack.Value)%"
        $settings.WallpaperDimming = $dimTrack.Value
        Save-DesktopSettings
        Apply-Background
        Invalidate-AllDesktopForms
    })

    $d0 = New-Object System.Windows.Forms.Button; $d0.Text = "None (0%)"; $d0.Left = [int](15 * $uiScale); $d0.Top = [int](250 * $uiScale); $d0.Width = [int](105 * $uiScale); $d0.Height = [int](28 * $uiScale); $d0.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d0.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $d0.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $d0.FlatAppearance.BorderSize = 1; $d0.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $d0.Cursor = [System.Windows.Forms.Cursors]::Hand
    $d20 = New-Object System.Windows.Forms.Button; $d20.Text = "Light (20%)"; $d20.Left = [int](130 * $uiScale); $d20.Top = [int](250 * $uiScale); $d20.Width = [int](105 * $uiScale); $d20.Height = [int](28 * $uiScale); $d20.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d20.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $d20.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $d20.FlatAppearance.BorderSize = 1; $d20.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $d20.Cursor = [System.Windows.Forms.Cursors]::Hand
    $d40 = New-Object System.Windows.Forms.Button; $d40.Text = "Medium (40%)"; $d40.Left = [int](245 * $uiScale); $d40.Top = [int](250 * $uiScale); $d40.Width = [int](105 * $uiScale); $d40.Height = [int](28 * $uiScale); $d40.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d40.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $d40.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $d40.FlatAppearance.BorderSize = 1; $d40.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $d40.Cursor = [System.Windows.Forms.Cursors]::Hand
    $d60 = New-Object System.Windows.Forms.Button; $d60.Text = "Dark (60%)"; $d60.Left = [int](360 * $uiScale); $d60.Top = [int](250 * $uiScale); $d60.Width = [int](110 * $uiScale); $d60.Height = [int](28 * $uiScale); $d60.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d60.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $d60.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $d60.FlatAppearance.BorderSize = 1; $d60.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $d60.Cursor = [System.Windows.Forms.Cursors]::Hand

    $d0.Add_Click({ $dimTrack.Value = 0; $dimLbl.Text = "Wallpaper Dimming: 0%"; $settings.WallpaperDimming = 0; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })
    $d20.Add_Click({ $dimTrack.Value = 20; $dimLbl.Text = "Wallpaper Dimming: 20%"; $settings.WallpaperDimming = 20; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })
    $d40.Add_Click({ $dimTrack.Value = 40; $dimLbl.Text = "Wallpaper Dimming: 40%"; $settings.WallpaperDimming = 40; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })
    $d60.Add_Click({ $dimTrack.Value = 60; $dimLbl.Text = "Wallpaper Dimming: 60%"; $settings.WallpaperDimming = 60; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })

    $cardBg.Controls.Add($d0); $cardBg.Controls.Add($d20); $cardBg.Controls.Add($d40); $cardBg.Controls.Add($d60)

    $rbBrand.Add_CheckedChanged({ if ($rbBrand.Checked) { $settings.BackgroundType = "Brand"; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms } })
    $rbColor.Add_CheckedChanged({ if ($rbColor.Checked) { $settings.BackgroundType = "Color"; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms } })
    $rbImage.Add_CheckedChanged({ if ($rbImage.Checked) { $settings.BackgroundType = "Image"; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms } })

    # Card 2: Desktop Path & Explorer
    $cardPath = Add-SettingsCard "Desktop Folder Location" 105 "#10b981"
    $pathBox = New-Object System.Windows.Forms.TextBox
    $pathBox.Left = [int](15 * $uiScale); $pathBox.Top = [int](45 * $uiScale); $pathBox.Width = [int](340 * $uiScale); $pathBox.Height = [int](28 * $uiScale)
    $pathBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a"); $pathBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc"); $pathBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pathBox.Text = $script:desktopPath
    $cardPath.Controls.Add($pathBox)

    $pathBtn = New-Object System.Windows.Forms.Button
    $pathBtn.Text = "Browse..."
    $pathBtn.Left = [int](365 * $uiScale); $pathBtn.Top = [int](45 * $uiScale); $pathBtn.Width = [int](115 * $uiScale); $pathBtn.Height = [int](28 * $uiScale)
    $pathBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $pathBtn.FlatAppearance.BorderSize = 1; $pathBtn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $pathBtn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $pathBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc"); $pathBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $pathBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $pathBtn.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.SelectedPath = $script:desktopPath
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $pathBox.Text = $fbd.SelectedPath
            $settings.DesktopPath = $fbd.SelectedPath
            $script:desktopPath = $fbd.SelectedPath
            Save-DesktopSettings; Refresh-Desktop
        }
        $fbd.Dispose()
    })
    $cardPath.Controls.Add($pathBtn)

    # Card 3: Dual Independent Scalers (Icon Scale & UI/Font Scale)
    $cardScale = Add-SettingsCard "Independent Icon & UI Scaling" 245 "#38bdf8"
    
    $iconLbl = New-Object System.Windows.Forms.Label; $iconLbl.Text = "Icon Size: $($settings.IconScale)px"; $iconLbl.Left = [int](15 * $uiScale); $iconLbl.Top = [int](38 * $uiScale); $iconLbl.AutoSize = $true; $iconLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    $cardScale.Controls.Add($iconLbl)

    $track = New-Object NoScrollTrackBar
    $track.Minimum = 32; $track.Maximum = 160; $track.Value = [int]$settings.IconScale
    $track.Left = [int](150 * $uiScale); $track.Top = [int](32 * $uiScale); $track.Width = [int](320 * $uiScale)
    $track.TickFrequency = 16
    $cardScale.Controls.Add($track)

    $track.Add_Scroll({
        $iconLbl.Text = "Icon Size: $($track.Value)px"
        $settings.IconScale = $track.Value
        Clear-IconCache
        Save-DesktopSettings
        Refresh-Desktop
    })

    $p1 = New-Object System.Windows.Forms.Button; $p1.Text = "Small (48px)"; $p1.Left = [int](15 * $uiScale); $p1.Top = [int](76 * $uiScale); $p1.Width = [int](105 * $uiScale); $p1.Height = [int](26 * $uiScale); $p1.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p1.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $p1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $p1.FlatAppearance.BorderSize = 1; $p1.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $p1.Cursor = [System.Windows.Forms.Cursors]::Hand
    $p2 = New-Object System.Windows.Forms.Button; $p2.Text = "Medium (72px)"; $p2.Left = [int](130 * $uiScale); $p2.Top = [int](76 * $uiScale); $p2.Width = [int](105 * $uiScale); $p2.Height = [int](26 * $uiScale); $p2.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p2.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $p2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $p2.FlatAppearance.BorderSize = 1; $p2.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $p2.Cursor = [System.Windows.Forms.Cursors]::Hand
    $p3 = New-Object System.Windows.Forms.Button; $p3.Text = "Large (96px)"; $p3.Left = [int](245 * $uiScale); $p3.Top = [int](76 * $uiScale); $p3.Width = [int](105 * $uiScale); $p3.Height = [int](26 * $uiScale); $p3.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p3.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $p3.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $p3.FlatAppearance.BorderSize = 1; $p3.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $p3.Cursor = [System.Windows.Forms.Cursors]::Hand
    $p4 = New-Object System.Windows.Forms.Button; $p4.Text = "X-Large (128px)"; $p4.Left = [int](360 * $uiScale); $p4.Top = [int](76 * $uiScale); $p4.Width = [int](110 * $uiScale); $p4.Height = [int](26 * $uiScale); $p4.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p4.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $p4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $p4.FlatAppearance.BorderSize = 1; $p4.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $p4.Cursor = [System.Windows.Forms.Cursors]::Hand

    $p1.Add_Click({ $track.Value = 48; $iconLbl.Text = "Icon Size: 48px"; $settings.IconScale = 48; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $p2.Add_Click({ $track.Value = 72; $iconLbl.Text = "Icon Size: 72px"; $settings.IconScale = 72; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $p3.Add_Click({ $track.Value = 96; $iconLbl.Text = "Icon Size: 96px"; $settings.IconScale = 96; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $p4.Add_Click({ $track.Value = 128; $iconLbl.Text = "Icon Size: 128px"; $settings.IconScale = 128; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $cardScale.Controls.Add($p1); $cardScale.Controls.Add($p2); $cardScale.Controls.Add($p3); $cardScale.Controls.Add($p4)

    # 2. UI / Font / Spacing Scale Slider
    $uiPct = [int]([double]$settings.UiScale * 100)
    $uiLbl = New-Object System.Windows.Forms.Label; $uiLbl.Text = "UI & Font Scale: $uiPct%"; $uiLbl.Left = [int](15 * $uiScale); $uiLbl.Top = [int](130 * $uiScale); $uiLbl.AutoSize = $true; $uiLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    $cardScale.Controls.Add($uiLbl)

    $uiTrack = New-Object NoScrollTrackBar
    $uiTrack.Minimum = 70; $uiTrack.Maximum = 180; $uiTrack.Value = [Math]::Max(70, [Math]::Min(180, $uiPct))
    $uiTrack.Left = [int](150 * $uiScale); $uiTrack.Top = [int](124 * $uiScale); $uiTrack.Width = [int](320 * $uiScale)
    $uiTrack.TickFrequency = 10
    $cardScale.Controls.Add($uiTrack)

    $uiTrack.Add_Scroll({
        $uiLbl.Text = "UI & Font Scale: $($uiTrack.Value)%"
        $settings.UiScale = [double]($uiTrack.Value / 100.0)
        Save-DesktopSettings; Refresh-Desktop
    })

    $u1 = New-Object System.Windows.Forms.Button; $u1.Text = "Compact (80%)"; $u1.Left = [int](15 * $uiScale); $u1.Top = [int](172 * $uiScale); $u1.Width = [int](105 * $uiScale); $u1.Height = [int](26 * $uiScale); $u1.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u1.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $u1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $u1.FlatAppearance.BorderSize = 1; $u1.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $u1.Cursor = [System.Windows.Forms.Cursors]::Hand
    $u2 = New-Object System.Windows.Forms.Button; $u2.Text = "Standard (100%)"; $u2.Left = [int](130 * $uiScale); $u2.Top = [int](172 * $uiScale); $u2.Width = [int](105 * $uiScale); $u2.Height = [int](26 * $uiScale); $u2.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u2.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $u2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $u2.FlatAppearance.BorderSize = 1; $u2.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $u2.Cursor = [System.Windows.Forms.Cursors]::Hand
    $u3 = New-Object System.Windows.Forms.Button; $u3.Text = "Spacious (125%)"; $u3.Left = [int](245 * $uiScale); $u3.Top = [int](172 * $uiScale); $u3.Width = [int](105 * $uiScale); $u3.Height = [int](26 * $uiScale); $u3.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u3.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $u3.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $u3.FlatAppearance.BorderSize = 1; $u3.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $u3.Cursor = [System.Windows.Forms.Cursors]::Hand
    $u4 = New-Object System.Windows.Forms.Button; $u4.Text = "Large (150%)"; $u4.Left = [int](360 * $uiScale); $u4.Top = [int](172 * $uiScale); $u4.Width = [int](110 * $uiScale); $u4.Height = [int](26 * $uiScale); $u4.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u4.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $u4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e2e8f0"); $u4.FlatAppearance.BorderSize = 1; $u4.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $u4.Cursor = [System.Windows.Forms.Cursors]::Hand

    $u1.Add_Click({ $uiTrack.Value = 80; $uiLbl.Text = "UI & Font Scale: 80%"; $settings.UiScale = 0.8; Save-DesktopSettings; Refresh-Desktop })
    $u2.Add_Click({ $uiTrack.Value = 100; $uiLbl.Text = "UI & Font Scale: 100%"; $settings.UiScale = 1.0; Save-DesktopSettings; Refresh-Desktop })
    $u3.Add_Click({ $uiTrack.Value = 125; $uiLbl.Text = "UI & Font Scale: 125%"; $settings.UiScale = 1.25; Save-DesktopSettings; Refresh-Desktop })
    $u4.Add_Click({ $uiTrack.Value = 150; $uiLbl.Text = "UI & Font Scale: 150%"; $settings.UiScale = 1.5; Save-DesktopSettings; Refresh-Desktop })
    $cardScale.Controls.Add($u1); $cardScale.Controls.Add($u2); $cardScale.Controls.Add($u3); $cardScale.Controls.Add($u4)

    # Card 4: Layout & Grid Behavior
    $cardLayout = Add-SettingsCard "Layout & Icon Arrangement" 160 "#a855f7"
    $chkAuto = New-Object ModernCheckBox; $chkAuto.Text = "Auto Arrange Icons"; $chkAuto.Left = [int](15 * $uiScale); $chkAuto.Top = [int](38 * $uiScale); $chkAuto.Checked = [bool]$settings.AutoArrange; $chkAuto.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#a855f7")
    $chkGrid = New-Object ModernCheckBox; $chkGrid.Text = "Align to Grid"; $chkGrid.Left = [int](255 * $uiScale); $chkGrid.Top = [int](38 * $uiScale); $chkGrid.Checked = [bool]$settings.AlignToGrid; $chkGrid.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#a855f7")
    
    $chkShow = New-Object ModernCheckBox; $chkShow.Text = "Show Desktop Icons"; $chkShow.Left = [int](15 * $uiScale); $chkShow.Top = [int](74 * $uiScale); $chkShow.Checked = [bool]$settings.ShowDesktopIcons; $chkShow.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#a855f7")
    $chkRecycle = New-Object ModernCheckBox; $chkRecycle.Text = "Show Recycle Bin"; $chkRecycle.Left = [int](255 * $uiScale); $chkRecycle.Top = [int](74 * $uiScale); $chkRecycle.Checked = [bool]$settings.ShowRecycleBin; $chkRecycle.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#a855f7")
    
    $chkConfirmExit = New-Object ModernCheckBox; $chkConfirmExit.Text = "Confirm exit on Escape (Yes/No dialog)"; $chkConfirmExit.Left = [int](15 * $uiScale); $chkConfirmExit.Top = [int](110 * $uiScale); $chkConfirmExit.Checked = [bool]$settings.ConfirmExit; $chkConfirmExit.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#a855f7")

    $chkAuto.Add_CheckedChanged({ $settings.AutoArrange = $chkAuto.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkGrid.Add_CheckedChanged({ $settings.AlignToGrid = $chkGrid.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkShow.Add_CheckedChanged({ $settings.ShowDesktopIcons = $chkShow.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkRecycle.Add_CheckedChanged({ $settings.ShowRecycleBin = $chkRecycle.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkConfirmExit.Add_CheckedChanged({ $settings.ConfirmExit = $chkConfirmExit.Checked; Save-DesktopSettings })
    $cardLayout.Controls.Add($chkAuto); $cardLayout.Controls.Add($chkGrid); $cardLayout.Controls.Add($chkShow); $cardLayout.Controls.Add($chkRecycle); $cardLayout.Controls.Add($chkConfirmExit)

    # Card 5: Desktop Glass Widgets & HUD
    $cardWidgets = Add-SettingsCard "Desktop Glass Widgets & Live HUD" 135 "#06b6d4"
    $chkWidgets = New-Object ModernCheckBox; $chkWidgets.Text = "Enable Desktop Glass Widgets"; $chkWidgets.Left = [int](15 * $uiScale); $chkWidgets.Top = [int](38 * $uiScale); $chkWidgets.Checked = [bool]$settings.ShowWidgets; $chkWidgets.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#06b6d4")
    $cardWidgets.Controls.Add($chkWidgets)

    $lblWidgetPos = New-Object System.Windows.Forms.Label; $lblWidgetPos.Text = "Position:"; $lblWidgetPos.Left = [int](270 * $uiScale); $lblWidgetPos.Top = [int](38 * $uiScale); $lblWidgetPos.AutoSize = $true; $lblWidgetPos.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    $cardWidgets.Controls.Add($lblWidgetPos)

    $cmbWidgetPos = New-Object ModernComboBox
    $cmbWidgetPos.Left = [int](335 * $uiScale); $cmbWidgetPos.Top = [int](34 * $uiScale); $cmbWidgetPos.Width = [int](135 * $uiScale)
    [void]$cmbWidgetPos.Items.AddRange(@("TopRight", "TopLeft", "BottomRight", "BottomLeft"))
    $cmbWidgetPos.SelectedItem = if ([string]::IsNullOrWhiteSpace($settings.WidgetPosition)) { "TopRight" } else { [string]$settings.WidgetPosition }
    $cardWidgets.Controls.Add($cmbWidgetPos)

    $chkClock = New-Object ModernCheckBox; $chkClock.Text = "Clock & Date"; $chkClock.Left = [int](15 * $uiScale); $chkClock.Top = [int](78 * $uiScale); $chkClock.Checked = [bool]$settings.ShowWidgetClock; $chkClock.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#06b6d4")
    $chkSys = New-Object ModernCheckBox; $chkSys.Text = "RAM Monitor"; $chkSys.Left = [int](175 * $uiScale); $chkSys.Top = [int](78 * $uiScale); $chkSys.Checked = [bool]$settings.ShowWidgetSystem; $chkSys.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#06b6d4")
    $chkDisk = New-Object ModernCheckBox; $chkDisk.Text = "Disk (C:) Storage"; $chkDisk.Left = [int](325 * $uiScale); $chkDisk.Top = [int](78 * $uiScale); $chkDisk.Checked = [bool]$settings.ShowWidgetStorage; $chkDisk.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#06b6d4")
    $cardWidgets.Controls.Add($chkClock); $cardWidgets.Controls.Add($chkSys); $cardWidgets.Controls.Add($chkDisk)

    $chkWidgets.Add_CheckedChanged({ $settings.ShowWidgets = $chkWidgets.Checked; Save-DesktopSettings; Invalidate-AllDesktopForms })
    $cmbWidgetPos.Add_SelectedIndexChanged({ $settings.WidgetPosition = [string]$cmbWidgetPos.SelectedItem; Save-DesktopSettings; Invalidate-AllDesktopForms })
    $chkClock.Add_CheckedChanged({ $settings.ShowWidgetClock = $chkClock.Checked; Save-DesktopSettings; Invalidate-AllDesktopForms })
    $chkSys.Add_CheckedChanged({ $settings.ShowWidgetSystem = $chkSys.Checked; Save-DesktopSettings; Invalidate-AllDesktopForms })
    $chkDisk.Add_CheckedChanged({ $settings.ShowWidgetStorage = $chkDisk.Checked; Save-DesktopSettings; Invalidate-AllDesktopForms })

    # Card 6: Boss Key & Panic Stealth Mode
    $cardBoss = Add-SettingsCard "Boss Key & Panic Stealth Mode" 525 "#ef4444"
    $chkBoss = New-Object ModernCheckBox; $chkBoss.Text = "Enable Boss Key (Ultra-Aggressive Stealth Mode)"; $chkBoss.Left = [int](15 * $uiScale); $chkBoss.Top = [int](38 * $uiScale); $chkBoss.Checked = [bool]$settings.BossKeyEnabled; $chkBoss.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $cardBoss.Controls.Add($chkBoss)

    $lblBossKey = New-Object System.Windows.Forms.Label; $lblBossKey.Text = "Trigger Hotkey:"; $lblBossKey.Left = [int](15 * $uiScale); $lblBossKey.Top = [int](68 * $uiScale); $lblBossKey.AutoSize = $true; $lblBossKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#cbd5e1")
    $cardBoss.Controls.Add($lblBossKey)

    $txtBossKey = New-Object System.Windows.Forms.TextBox
    $txtBossKey.Left = [int](115 * $uiScale); $txtBossKey.Top = [int](64 * $uiScale); $txtBossKey.Width = [int](160 * $uiScale); $txtBossKey.Height = [int](26 * $uiScale)
    $txtBossKey.ReadOnly = $true; $txtBossKey.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a"); $txtBossKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc")
    $txtBossKey.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $txtBossKey.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    $txtBossKey.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $txtBossKey.Text = [string]$settings.BossKeyName
    $cardBoss.Controls.Add($txtBossKey)

    $btnRecord = New-Object System.Windows.Forms.Button
    $btnRecord.Text = "Click to Bind Key"
    $btnRecord.Left = [int](285 * $uiScale); $btnRecord.Top = [int](63 * $uiScale); $btnRecord.Width = [int](190 * $uiScale); $btnRecord.Height = [int](28 * $uiScale)
    $btnRecord.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnRecord.FlatAppearance.BorderSize = 0
    $btnRecord.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444"); $btnRecord.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff"); $btnRecord.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnRecord.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $cardBoss.Controls.Add($btnRecord)

    function Show-BossKeyCaptureDialog {
        $dlg = New-Object System.Windows.Forms.Form
        $dlg.Text = "Record Boss Key"
        $dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
        $dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
        $dlg.Width = [int](440 * $uiScale); $dlg.Height = [int](210 * $uiScale)
        $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
        $dlg.KeyPreview = $true
        $dlg.TopMost = $true
        Enable-DoubleBuffer $dlg

        $dlg.Add_Paint({
            param($s, $e)
            $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#ef4444"), 2)
            try { $e.Graphics.DrawRectangle($pen, 1, 1, $s.Width - 2, $s.Height - 2) } finally { $pen.Dispose() }
        })

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = "RECORDING BOSS KEY (TOTAL OVERRIDE)"
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", [float](12.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
        $lblTitle.AutoSize = $true; $lblTitle.Left = [int](25 * $uiScale); $lblTitle.Top = [int](25 * $uiScale)
        $dlg.Controls.Add($lblTitle)

        $lblPrompt = New-Object System.Windows.Forms.Label
        $lblPrompt.Text = "Press ANY key on your keyboard (including Windows Key)..."
        $lblPrompt.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale))
        $lblPrompt.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
        $lblPrompt.AutoSize = $true; $lblPrompt.Left = [int](25 * $uiScale); $lblPrompt.Top = [int](62 * $uiScale)
        $dlg.Controls.Add($lblPrompt)

        $lblSub = New-Object System.Windows.Forms.Label
        $lblSub.Text = "Supports: Windows Key, Win+AnyKey, F1-F24, Alt/Ctrl/Shift combos"
        $lblSub.Font = New-Object System.Drawing.Font("Segoe UI", [float](8.5 * $uiScale))
        $lblSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8")
        $lblSub.AutoSize = $true; $lblSub.Left = [int](25 * $uiScale); $lblSub.Top = [int](92 * $uiScale)
        $dlg.Controls.Add($lblSub)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancel"
        $btnCancel.Left = [int](160 * $uiScale); $btnCancel.Top = [int](145 * $uiScale); $btnCancel.Width = [int](120 * $uiScale); $btnCancel.Height = [int](32 * $uiScale)
        $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnCancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b")
        $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
        $btnCancel.FlatAppearance.BorderSize = 1
        $btnCancel.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
        $btnCancel.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnCancel.Add_Click({ 
            [WinDInterceptor]::IsRecordingKey = $false
            $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $dlg.Close() 
        })
        $dlg.Controls.Add($btnCancel)

        $script:recordedBossKeyResult = $null

        # Hardware-Level Hook Handler
        [WinDInterceptor]::OnKeyRecorded = [WinDInterceptor+KeyRecordedHandler]{
            param($vk, $ctrl, $alt, $shift, $win, $name)
            $script:recordedBossKeyResult = @{
                Name  = $name
                Vk    = $vk
                Ctrl  = $ctrl
                Alt   = $alt
                Shift = $shift
                Win   = $win
            }
            try {
                if (-not $dlg.IsDisposed) {
                    $dlg.BeginInvoke([Action]{ 
                        $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $dlg.Close() 
                    })
                }
            } catch { }
        }

        [WinDInterceptor]::IsRecordingKey = $true

        $dlg.Add_FormClosed({
            [WinDInterceptor]::IsRecordingKey = $false
            [WinDInterceptor]::OnKeyRecorded = $null
        })

        $dlg.ShowDialog($form) | Out-Null
        $dlg.Dispose()
        return $script:recordedBossKeyResult
    }

    $btnRecord.Add_Click({
        $result = Show-BossKeyCaptureDialog
        if ($null -ne $result) {
            $settings.BossKeyName  = [string]$result.Name
            $settings.BossKeyVk    = [int]$result.Vk
            $settings.BossKeyCtrl  = [bool]$result.Ctrl
            $settings.BossKeyAlt   = [bool]$result.Alt
            $settings.BossKeyShift = [bool]$result.Shift
            $settings.BossKeyWin   = [bool]$result.Win
            
            $txtBossKey.Text = [string]$result.Name
            Save-DesktopSettings
            Apply-BossKeySettings
        }
    })

    # Mode Selector Header
    $lblModeTitle = New-Object System.Windows.Forms.Label
    $lblModeTitle.Text = "Stealth Panic Action Mode:"
    $lblModeTitle.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $lblModeTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc")
    $lblModeTitle.Left = [int](15 * $uiScale); $lblModeTitle.Top = [int](102 * $uiScale); $lblModeTitle.AutoSize = $true
    $cardBoss.Controls.Add($lblModeTitle)

    # 3 Clear Mode Choices
    $rbModeUpdate = New-Object ModernRadioButton
    $rbModeUpdate.Text = "Fake Windows 11 Update (Authentic Full-Screen Stealth)"
    $rbModeUpdate.Left = [int](15 * $uiScale); $rbModeUpdate.Top = [int](126 * $uiScale)
    $rbModeUpdate.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#38bdf8")
    $cardBoss.Controls.Add($rbModeUpdate)

    $rbModeSoftware = New-Object ModernRadioButton
    $rbModeSoftware.Text = "Launch Decoy Application / Busy Work (Software, Document, URL)"
    $rbModeSoftware.Left = [int](15 * $uiScale); $rbModeSoftware.Top = [int](150 * $uiScale)
    $rbModeSoftware.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $cardBoss.Controls.Add($rbModeSoftware)

    $rbModeClean = New-Object ModernRadioButton
    $rbModeClean.Text = "Clean Desktop Only (Minimize active windows, mute audio)"
    $rbModeClean.Left = [int](15 * $uiScale); $rbModeClean.Top = [int](174 * $uiScale)
    $rbModeClean.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#10b981")
    $cardBoss.Controls.Add($rbModeClean)

    # Subpanel for Windows Update Mode
    $pnlUpdate = New-Object System.Windows.Forms.Panel
    $pnlUpdate.Left = [int](15 * $uiScale); $pnlUpdate.Top = [int](200 * $uiScale); $pnlUpdate.Width = [int](475 * $uiScale); $pnlUpdate.Height = [int](65 * $uiScale)
    $pnlUpdate.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    $pnlUpdate.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1e293b"), 1)
        try { $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1) } finally { $pen.Dispose() }
    })
    $lblUpInfo1 = New-Object System.Windows.Forms.Label
    $lblUpInfo1.Text = "• Full-Screen OLED Pitch-Black with Windows 11 Fluent Ring & System Fonts"
    $lblUpInfo1.Font = New-Object System.Drawing.Font("Segoe UI", [float](8.25 * $uiScale))
    $lblUpInfo1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38bdf8")
    $lblUpInfo1.Left = [int](10 * $uiScale); $lblUpInfo1.Top = [int](10 * $uiScale); $lblUpInfo1.AutoSize = $true
    $pnlUpdate.Controls.Add($lblUpInfo1)

    $lblUpInfo2 = New-Object System.Windows.Forms.Label
    $lblUpInfo2.Text = "• Real-time % progression, multi-monitor coverage & automatic cursor concealment"
    $lblUpInfo2.Font = New-Object System.Drawing.Font("Segoe UI", [float](8.25 * $uiScale))
    $lblUpInfo2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8")
    $lblUpInfo2.Left = [int](10 * $uiScale); $lblUpInfo2.Top = [int](34 * $uiScale); $lblUpInfo2.AutoSize = $true
    $pnlUpdate.Controls.Add($lblUpInfo2)
    $cardBoss.Controls.Add($pnlUpdate)

    # Subpanel for Decoy Software Mode
    $pnlSoftware = New-Object System.Windows.Forms.Panel
    $pnlSoftware.Left = [int](15 * $uiScale); $pnlSoftware.Top = [int](200 * $uiScale); $pnlSoftware.Width = [int](475 * $uiScale); $pnlSoftware.Height = [int](175 * $uiScale)
    $pnlSoftware.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827")
    $cardBoss.Controls.Add($pnlSoftware)

    function Show-SoftwarePickerDialog {
        $dlg = New-Object System.Windows.Forms.Form
        $dlg.Text = "Select Installed Software"
        $dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
        $dlg.Width = [int](540 * $uiScale); $dlg.Height = [int](480 * $uiScale)
        $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
        $dlg.KeyPreview = $true
        $dlg.TopMost = $true
        Enable-DoubleBuffer $dlg

        $dlg.Add_Paint({
            param($s, $e)
            $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#ef4444"), 2)
            try { $e.Graphics.DrawRectangle($pen, 1, 1, $s.Width - 2, $s.Height - 2) } finally { $pen.Dispose() }
        })

        $titleLbl = New-Object System.Windows.Forms.Label
        $titleLbl.Text = "SELECT INSTALLED SOFTWARE"
        $titleLbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](12.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
        $titleLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
        $titleLbl.AutoSize = $true; $titleLbl.Left = [int](25 * $uiScale); $titleLbl.Top = [int](20 * $uiScale)
        $dlg.Controls.Add($titleLbl)

        $subLbl = New-Object System.Windows.Forms.Label
        $subLbl.Text = "Choose any software installed on your PC as your instant Boss Key decoy:"
        $subLbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale))
        $subLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8")
        $subLbl.AutoSize = $true; $subLbl.Left = [int](25 * $uiScale); $subLbl.Top = [int](50 * $uiScale)
        $dlg.Controls.Add($subLbl)

        $searchBox = New-Object System.Windows.Forms.TextBox
        $searchBox.Left = [int](25 * $uiScale); $searchBox.Top = [int](78 * $uiScale); $searchBox.Width = [int](490 * $uiScale); $searchBox.Height = [int](28 * $uiScale)
        $searchBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a"); $searchBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
        $searchBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $searchBox.Font = New-Object System.Drawing.Font("Segoe UI", [float](10 * $uiScale))
        $dlg.Controls.Add($searchBox)

        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Left = [int](25 * $uiScale); $listBox.Top = [int](115 * $uiScale); $listBox.Width = [int](490 * $uiScale); $listBox.Height = [int](270 * $uiScale)
        $listBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827"); $listBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
        $listBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $listBox.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale))
        $listBox.ItemHeight = [int](22 * $uiScale)
        $dlg.Controls.Add($listBox)

        $pathLbl = New-Object System.Windows.Forms.Label
        $pathLbl.Text = ""
        $pathLbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](8.5 * $uiScale))
        $pathLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#64748b")
        $pathLbl.Left = [int](25 * $uiScale); $pathLbl.Top = [int](395 * $uiScale); $pathLbl.Width = [int](490 * $uiScale); $pathLbl.Height = [int](20 * $uiScale)
        $dlg.Controls.Add($pathLbl)

        $btnSelect = New-Object System.Windows.Forms.Button
        $btnSelect.Text = "Select Application"
        $btnSelect.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
        $btnSelect.Left = [int](245 * $uiScale); $btnSelect.Top = [int](425 * $uiScale); $btnSelect.Width = [int](150 * $uiScale); $btnSelect.Height = [int](34 * $uiScale)
        $btnSelect.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnSelect.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
        $btnSelect.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
        $btnSelect.FlatAppearance.BorderSize = 0
        $btnSelect.Cursor = [System.Windows.Forms.Cursors]::Hand
        $dlg.Controls.Add($btnSelect)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancel"
        $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale))
        $btnCancel.Left = [int](405 * $uiScale); $btnCancel.Top = [int](425 * $uiScale); $btnCancel.Width = [int](110 * $uiScale); $btnCancel.Height = [int](34 * $uiScale)
        $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnCancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b")
        $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
        $btnCancel.FlatAppearance.BorderSize = 1
        $btnCancel.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
        $btnCancel.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnCancel.Add_Click({ $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $dlg.Close() })
        $dlg.Controls.Add($btnCancel)

        $allApps = Get-InstalledSoftwareList
        $filteredApps = [System.Collections.Generic.List[PSObject]]::new()

        $updateList = {
            $query = $searchBox.Text.Trim()
            $listBox.BeginUpdate()
            $listBox.Items.Clear()
            $filteredApps.Clear()
            
            foreach ($app in $allApps) {
                if ([string]::IsNullOrWhiteSpace($query) -or ($app.Name -match [regex]::Escape($query)) -or ($app.Path -match [regex]::Escape($query))) {
                    $filteredApps.Add($app)
                    $listBox.Items.Add($app.Name) | Out-Null
                }
            }
            $listBox.EndUpdate()
            if ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = 0 }
        }

        $listBox.Add_SelectedIndexChanged({
            if ($listBox.SelectedIndex -ge 0 -and $listBox.SelectedIndex -lt $filteredApps.Count) {
                $pathLbl.Text = $filteredApps[$listBox.SelectedIndex].Path
            } else {
                $pathLbl.Text = ""
            }
        })

        $script:softwarePickerResult = $null

        $confirmSelection = {
            if ($listBox.SelectedIndex -ge 0 -and $listBox.SelectedIndex -lt $filteredApps.Count) {
                $sel = $filteredApps[$listBox.SelectedIndex]
                $script:softwarePickerResult = @{
                    Name = $sel.Name
                    Path = $sel.Path
                }
                $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $dlg.Close()
            }
        }

        $btnSelect.Add_Click($confirmSelection)
        $listBox.Add_DoubleClick($confirmSelection)

        $searchBox.Add_TextChanged($updateList)
        $dlg.Add_KeyDown({
            param($s, $e)
            if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                & $confirmSelection
                $e.Handled = $true
            } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                $dlg.Close()
                $e.Handled = $true
            }
        })

        & $updateList
        $dlg.ShowDialog($form) | Out-Null
        $dlg.Dispose()
        return $script:softwarePickerResult
    }

    # Software Mode Controls
    $cmbDecoy = New-Object ModernComboBox
    $cmbDecoy.Left = 0; $cmbDecoy.Top = 0; $cmbDecoy.Width = [int](245 * $uiScale)

    $btnPickSoftware = New-Object System.Windows.Forms.Button
    $btnPickSoftware.Text = "Browse Installed Software..."
    $btnPickSoftware.Left = [int](255 * $uiScale); $btnPickSoftware.Top = 0; $btnPickSoftware.Width = [int](220 * $uiScale); $btnPickSoftware.Height = [int](28 * $uiScale)
    $btnPickSoftware.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnPickSoftware.FlatAppearance.BorderSize = 0
    $btnPickSoftware.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444"); $btnPickSoftware.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff"); $btnPickSoftware.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnPickSoftware.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $pnlSoftware.Controls.Add($btnPickSoftware)

    $allInstalled = Get-InstalledSoftwareList
    $presetDecoys = @("Notepad (Quick Notes)", "Visual Studio / VS Code", "Excel / Spreadsheet", "PowerShell / Terminal", "Calculator", "Web Work / Google Docs")
    foreach ($p in $presetDecoys) { [void]$cmbDecoy.Items.Add($p) }
    
    [void]$cmbDecoy.Items.Add("─── Installed Applications (Dynamic) ───")
    foreach ($inst in $allInstalled) {
        if ($inst.Name -notmatch "Notepad|Calculator|PowerShell") {
            [void]$cmbDecoy.Items.Add($inst.Name)
        }
    }
    [void]$cmbDecoy.Items.Add("─── Custom ───")
    [void]$cmbDecoy.Items.Add("Custom File, App or URL...")

    $matchedDecoy = 0
    for ($d = 0; $d -lt $cmbDecoy.Items.Count; $d++) {
        if ([string]$cmbDecoy.Items[$d] -eq [string]$settings.BossDecoyPreset) { $matchedDecoy = $d; break }
    }
    $cmbDecoy.SelectedIndex = $matchedDecoy
    $pnlSoftware.Controls.Add($cmbDecoy)

    $txtDecoyPath = New-Object System.Windows.Forms.TextBox
    $txtDecoyPath.Left = 0; $txtDecoyPath.Top = [int](36 * $uiScale); $txtDecoyPath.Width = [int](350 * $uiScale); $txtDecoyPath.Height = [int](26 * $uiScale)
    $txtDecoyPath.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a"); $txtDecoyPath.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff"); $txtDecoyPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $txtDecoyPath.Text = if ([string]::IsNullOrWhiteSpace($settings.BossDecoyPath) -or $settings.BossDecoyPath -eq "FakeWindowsUpdate") { "notepad.exe" } else { [string]$settings.BossDecoyPath }
    $pnlSoftware.Controls.Add($txtDecoyPath)

    $btnBrowseDecoy = New-Object System.Windows.Forms.Button
    $btnBrowseDecoy.Text = "Browse..."
    $btnBrowseDecoy.Left = [int](360 * $uiScale); $btnBrowseDecoy.Top = [int](35 * $uiScale); $btnBrowseDecoy.Width = [int](115 * $uiScale); $btnBrowseDecoy.Height = [int](28 * $uiScale)
    $btnBrowseDecoy.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnBrowseDecoy.FlatAppearance.BorderSize = 1; $btnBrowseDecoy.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $btnBrowseDecoy.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $btnBrowseDecoy.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc"); $btnBrowseDecoy.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnBrowseDecoy.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $pnlSoftware.Controls.Add($btnBrowseDecoy)

    $chkDecoyPrewarm = New-Object ModernCheckBox; $chkDecoyPrewarm.Text = "Pre-warm in background (0ms Instant Reveal - No loading delay)"; $chkDecoyPrewarm.Left = 0; $chkDecoyPrewarm.Top = [int](72 * $uiScale); $chkDecoyPrewarm.Checked = [bool]$settings.BossDecoyPrewarm; $chkDecoyPrewarm.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $pnlSoftware.Controls.Add($chkDecoyPrewarm)

    $chkDecoyClose = New-Object ModernCheckBox; $chkDecoyClose.Text = "Automatically close Decoy App when exiting Stealth Mode"; $chkDecoyClose.Left = 0; $chkDecoyClose.Top = [int](102 * $uiScale); $chkDecoyClose.Checked = [bool]$settings.BossDecoyCloseOnRestore; $chkDecoyClose.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $pnlSoftware.Controls.Add($chkDecoyClose)

    # Bottom Toggles & Test Button
    $chkTaskbar = New-Object ModernCheckBox; $chkTaskbar.Text = "Hide Windows Taskbar on all monitors"; $chkTaskbar.Left = [int](15 * $uiScale); $chkTaskbar.Top = [int](390 * $uiScale); $chkTaskbar.Checked = [bool]$settings.BossHideTaskbar; $chkTaskbar.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $chkMute = New-Object ModernCheckBox; $chkMute.Text = "Mute Master Audio in Stealth Mode"; $chkMute.Left = [int](15 * $uiScale); $chkMute.Top = [int](422 * $uiScale); $chkMute.Checked = [bool]$settings.BossMuteAudio; $chkMute.AccentColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $cardBoss.Controls.Add($chkTaskbar)
    $cardBoss.Controls.Add($chkMute)

    $testBossBtn = New-Object System.Windows.Forms.Button
    $testBossBtn.Text = "Test Stealth Mode (3s Preview)"
    $testBossBtn.Left = [int](15 * $uiScale); $testBossBtn.Top = [int](465 * $uiScale); $testBossBtn.Width = [int](475 * $uiScale); $testBossBtn.Height = [int](38 * $uiScale)
    $testBossBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $testBossBtn.FlatAppearance.BorderSize = 1; $testBossBtn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $testBossBtn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b"); $testBossBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc"); $testBossBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $testBossBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](9 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $cardBoss.Controls.Add($testBossBtn)

    # Handlers & Dynamic UI Switcher
    $updateModeUI = {
        if ($rbModeUpdate.Checked) {
            $pnlUpdate.Visible = $true
            $pnlSoftware.Visible = $false
            $settings.BossDecoyMode = "WindowsUpdate"
            $settings.BossDecoyEnabled = $true
            $settings.BossDecoyPath = "FakeWindowsUpdate"
            $settings.BossDecoyPreset = "Windows 11 Update Screen (Fake Stealth Screen)"
            Write-DesktopLog "SETTINGS: Set BossDecoyMode -> WindowsUpdate" -Level "AUDIT"
            Save-DesktopSettings
            Apply-BossKeySettings
        } elseif ($rbModeSoftware.Checked) {
            $pnlUpdate.Visible = $false
            $pnlSoftware.Visible = $true
            $settings.BossDecoyMode = "Software"
            $settings.BossDecoyEnabled = $true
            $settings.BossDecoyPath = $txtDecoyPath.Text
            $settings.BossDecoyPreset = [string]$cmbDecoy.SelectedItem
            Write-DesktopLog "SETTINGS: Set BossDecoyMode -> Software ($($settings.BossDecoyPath))" -Level "AUDIT"
            Save-DesktopSettings
            Apply-BossKeySettings
        } else {
            $pnlUpdate.Visible = $false
            $pnlSoftware.Visible = $false
            $settings.BossDecoyMode = "None"
            $settings.BossDecoyEnabled = $false
            Write-DesktopLog "SETTINGS: Set BossDecoyMode -> None (Clean Desktop Only)" -Level "AUDIT"
            Save-DesktopSettings
            Apply-BossKeySettings
        }
    }

    $rbModeUpdate.Add_CheckedChanged({ if ($rbModeUpdate.Checked) { & $updateModeUI } })
    $rbModeSoftware.Add_CheckedChanged({ if ($rbModeSoftware.Checked) { & $updateModeUI } })
    $rbModeClean.Add_CheckedChanged({ if ($rbModeClean.Checked) { & $updateModeUI } })

    # Initial Mode State
    $initMode = if ($settings.BossDecoyMode) { [string]$settings.BossDecoyMode } elseif ($settings.BossDecoyPath -match "Update|FakeWindowsUpdate") { "WindowsUpdate" } elseif ($settings.BossDecoyEnabled) { "Software" } else { "None" }
    if ($initMode -eq "WindowsUpdate") {
        $rbModeUpdate.Checked = $true
        $pnlUpdate.Visible = $true; $pnlSoftware.Visible = $false
    } elseif ($initMode -eq "Software") {
        $rbModeSoftware.Checked = $true
        $pnlUpdate.Visible = $false; $pnlSoftware.Visible = $true
    } else {
        $rbModeClean.Checked = $true
        $pnlUpdate.Visible = $false; $pnlSoftware.Visible = $false
    }

    $btnPickSoftware.Add_Click({
        $picked = Show-SoftwarePickerDialog
        if ($null -ne $picked) {
            $txtDecoyPath.Text = [string]$picked.Path
            $settings.BossDecoyPath = [string]$picked.Path
            $settings.BossDecoyPreset = [string]$picked.Name
            
            $idx = $cmbDecoy.Items.IndexOf([string]$picked.Name)
            if ($idx -ge 0) {
                $cmbDecoy.SelectedIndex = $idx
            } else {
                $cmbDecoy.SelectedItem = "Custom File, App or URL..."
            }
            Save-DesktopSettings
            Apply-BossKeySettings
        }
    })

    $cmbDecoy.Add_SelectedIndexChanged({
        $sel = [string]$cmbDecoy.SelectedItem
        if ($sel.StartsWith("───")) { return }
        $settings.BossDecoyPreset = $sel
        
        if ($sel -match "Notepad") { $txtDecoyPath.Text = "notepad.exe" }
        elseif ($sel -match "Visual Studio") { 
            if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
                $txtDecoyPath.Text = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
            } elseif (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe") {
                $txtDecoyPath.Text = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
            } else {
                $txtDecoyPath.Text = "devenv.exe"
            }
        }
        elseif ($sel -match "Excel") { $txtDecoyPath.Text = "excel.exe" }
        elseif ($sel -match "PowerShell") { $txtDecoyPath.Text = "powershell.exe" }
        elseif ($sel -match "Calculator") { $txtDecoyPath.Text = "calc.exe" }
        elseif ($sel -match "Google Docs") { $txtDecoyPath.Text = "https://docs.google.com" }
        else {
            foreach ($app in $allInstalled) {
                if ($app.Name -eq $sel) {
                    $txtDecoyPath.Text = $app.Path
                    break
                }
            }
        }
        $settings.BossDecoyPath = $txtDecoyPath.Text
        Save-DesktopSettings
        Apply-BossKeySettings
    })

    $txtDecoyPath.Add_TextChanged({
        if ($rbModeSoftware.Checked) {
            $settings.BossDecoyPath = $txtDecoyPath.Text
            Save-DesktopSettings
        }
    })

    $btnBrowseDecoy.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Title = "Select Busy Work / Decoy File or Program"
        $ofd.Filter = "All Supported Files (*.exe;*.sln;*.docx;*.xlsx;*.pdf;*.txt;*.py;*.cmd)|*.exe;*.sln;*.docx;*.xlsx;*.pdf;*.txt;*.py;*.cmd|All Files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtDecoyPath.Text = $ofd.FileName
            $settings.BossDecoyPath = $ofd.FileName
            $settings.BossDecoyPreset = "Custom File, App or URL..."
            $cmbDecoy.SelectedItem = "Custom File, App or URL..."
            Save-DesktopSettings
            Apply-BossKeySettings
        }
    })

    $testBossBtn.Add_Click({
        Write-DesktopLog "SETTINGS: Triggered 3-second Stealth Mode preview test" -Level "AUDIT"
        [WinDInterceptor]::ToggleBossMode()
        $previewTimer = New-Object System.Windows.Forms.Timer
        $previewTimer.Interval = 3000
        $previewTimer.Add_Tick({
            param($s, $e)
            try {
                if ($null -ne $s) {
                    $s.Stop()
                    $s.Dispose()
                }
            } catch { }
            if ([WinDInterceptor]::IsBossModeActive) {
                Write-DesktopLog "SETTINGS: Stealth Mode preview test finished -> restoring" -Level "AUDIT"
                [WinDInterceptor]::ToggleBossMode()
            }
        })
        $previewTimer.Start()
    })

    $chkBoss.Add_CheckedChanged({ $settings.BossKeyEnabled = $chkBoss.Checked; Write-DesktopLog "SETTINGS: Toggled BossKeyEnabled -> $($chkBoss.Checked)" -Level "AUDIT"; Save-DesktopSettings; Apply-BossKeySettings })
    $chkTaskbar.Add_CheckedChanged({ $settings.BossHideTaskbar = $chkTaskbar.Checked; Write-DesktopLog "SETTINGS: Toggled BossHideTaskbar -> $($chkTaskbar.Checked)" -Level "AUDIT"; Save-DesktopSettings; Apply-BossKeySettings })
    $chkMute.Add_CheckedChanged({ $settings.BossMuteAudio = $chkMute.Checked; Write-DesktopLog "SETTINGS: Toggled BossMuteAudio -> $($chkMute.Checked)" -Level "AUDIT"; Save-DesktopSettings; Apply-BossKeySettings })
    $chkDecoyPrewarm.Add_CheckedChanged({ $settings.BossDecoyPrewarm = $chkDecoyPrewarm.Checked; Write-DesktopLog "SETTINGS: Toggled BossDecoyPrewarm -> $($chkDecoyPrewarm.Checked)" -Level "AUDIT"; Save-DesktopSettings; Apply-BossKeySettings })
    $chkDecoyClose.Add_CheckedChanged({ $settings.BossDecoyCloseOnRestore = $chkDecoyClose.Checked; Write-DesktopLog "SETTINGS: Toggled BossDecoyCloseOnRestore -> $($chkDecoyClose.Checked)" -Level "AUDIT"; Save-DesktopSettings; Apply-BossKeySettings })

    # Reset Defaults Button
    $resetBtn = New-Object System.Windows.Forms.Button
    $resetBtn.Text = "Reset All Settings to Defaults"
    $resetBtn.Left = [int](15 * $uiScale); $resetBtn.Top = $script:currY; $resetBtn.Width = $cardW; $resetBtn.Height = [int](40 * $uiScale)
    $resetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $resetBtn.FlatAppearance.BorderSize = 1
    $resetBtn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#475569")
    $resetBtn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e293b")
    $resetBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc")
    $resetBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $resetBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $resetBtn.Add_Click({
        Write-DesktopLog "SETTINGS: User clicked 'Reset All Settings to Defaults'" -Level "AUDIT"
        $defs = Get-DefaultSettings
        foreach ($k in $defs.Keys) { $script:settings[$k] = $defs[$k] }
        $script:desktopPath = $script:settings.DesktopPath
        Clear-IconCache
        Save-DesktopSettings
        Refresh-Desktop
        $form.Close()
    })
    $content.Controls.Add($resetBtn)
    $script:currY += [int](60 * $uiScale)

    # Configure content height and modern scrollbar range
    $content.Height = $script:currY
    $maxScroll = [Math]::Max(0, $content.Height - $body.Height)
    $scrollBar.Maximum = $maxScroll
    $scrollBar.LargeChange = $body.Height
    $scrollBar.Visible = ($maxScroll -gt 0)

    # Mouse wheel smooth scrolling across the entire Settings window
    $wheelScroll = {
        param($s, $e)
        if ($scrollBar.Visible) {
            $step = if ($e.Delta -gt 0) { -50 } else { 50 }
            $scrollBar.Value = [Math]::Max(0, [Math]::Min($scrollBar.Maximum, $scrollBar.Value + $step))
        }
    }

    function Attach-RecursiveWheel([System.Windows.Forms.Control]$ctl) {
        if ($null -eq $ctl) { return }
        $ctl.Add_MouseWheel($wheelScroll)
        if ($ctl -is [NoScrollTrackBar]) {
            $ctl.OnForwardMouseWheel = {
                param($delta)
                if ($scrollBar.Visible) {
                    $step = if ($delta -gt 0) { -50 } else { 50 }
                    $scrollBar.Value = [Math]::Max(0, [Math]::Min($scrollBar.Maximum, $scrollBar.Value + $step))
                }
            }
        }
        foreach ($child in $ctl.Controls) {
            Attach-RecursiveWheel $child
        }
    }
    Attach-RecursiveWheel $form

    $script:settingsForm = $form
    Write-DesktopLog "SETTINGS: Displaying Settings modal dialog" -Level "AUDIT"
    try {
        [void]$form.ShowDialog()
    } catch {
        Write-DesktopLog "SETTINGS ERROR: ShowDialog failed" -Level "ERROR" -Exception $_.Exception
    } finally {
        try { $form.Dispose() } catch {}
        $script:settingsForm = $null
        Write-DesktopLog "SETTINGS: Closed Settings modal dialog" -Level "AUDIT"
        [CustomDesktopForm]::ActivateDesktop()
    }
}

# ============================================================
# 014 - ICON LAYOUT ENGINE & CACHE (MULTI-MONITOR RESTORE)
# ============================================================

function Build-DesktopIcons {
    Dispose-DesktopControls
    if ($null -eq $script:primaryForm -or -not $settings.ShowDesktopIcons) { return }

    $uiScale = 1.0; if ($null -ne $settings.UiScale -and [double]$settings.UiScale -gt 0) { $uiScale = [double]$settings.UiScale }
    $iconSize = [int]$settings.IconScale
    $itemWidth = [int]($iconSize + (36 * $uiScale))
    $labelHeight = [int](38 * $uiScale)
    $itemHeight = [int]($iconSize + $labelHeight + (14 * $uiScale))

    $script:cellWidth = $itemWidth + [int](12 * $uiScale)
    $script:cellHeight = $itemHeight + [int](12 * $uiScale)
    $script:desktopFont = New-Object System.Drawing.Font("Segoe UI", [float](9.0 * $uiScale), [System.Drawing.FontStyle]::Regular)

    $occupiedSlots = @{}
    $pendingPlacement = @()

    # Special Icon: Recycle Bin (Cached in $script:iconCache for zero GDI leak)
    if ($settings.ShowRecycleBin) {
        $rbPath = "::{645FF040-5081-101B-9F08-00AA002F954E}"
        $rbCacheKey = "${rbPath}_$iconSize"
        
        $rbIcon = $null
        if ($script:iconCache.ContainsKey($rbCacheKey) -and $null -ne $script:iconCache[$rbCacheKey]) {
            $rbIcon = $script:iconCache[$rbCacheKey]
        } else {
            $rawRb = [ShellIcons]::GetRecycleBinIcon()
            if ($null -ne $rawRb) {
                $rbIcon = Resize-IconBitmap $rawRb $iconSize
                $rawRb.Dispose()
                if ($null -ne $rbIcon) { $script:iconCache[$rbCacheKey] = $rbIcon }
            }
        }

        $rbItem = [PSCustomObject]@{
            Path     = $rbPath
            Text     = "Recycle Bin"
            Icon     = $rbIcon
            Bounds   = [System.Drawing.Rectangle]::Empty
            Selected = $false
            Hovered  = $false
        }

        $savedRb = $null
        if (-not $settings.AutoArrange -and $settings.Positions.ContainsKey($rbPath)) {
            $p = $settings.Positions[$rbPath]
            if ($null -ne $p) {
                $coord = Get-VisibleDesktopCoordinate ([int]$p.X) ([int]$p.Y) $itemWidth $itemHeight
                $savedRb = New-Object System.Drawing.Point($coord.X, $coord.Y)
            }
        }

        if ($null -ne $savedRb) {
            $screen = Get-ScreenForPoint $savedRb.X $savedRb.Y
            $sInfo = Get-ScreenGridBounds $screen
            $col = [int][Math]::Max(0, [Math]::Min($sInfo.Cols - 1, [Math]::Round(($savedRb.X - $sInfo.Left - $sInfo.Margin) / [double]$script:cellWidth)))
            $row = [int][Math]::Max(0, [Math]::Min($sInfo.Rows - 1, [Math]::Round(($savedRb.Y - $sInfo.Top - $sInfo.Margin) / [double]$script:cellHeight)))
            $slotKey = "$($screen.DeviceName)_$col,$row"
            if (-not $occupiedSlots.ContainsKey($slotKey)) {
                $occupiedSlots[$slotKey] = $true
                $rbItem.Bounds = New-Object System.Drawing.Rectangle($savedRb.X, $savedRb.Y, $itemWidth, $itemHeight)
                $script:desktopItems += $rbItem
            } else {
                $pendingPlacement += $rbItem
            }
        } else {
            $pendingPlacement += $rbItem
        }
    }

    if (Test-Path -LiteralPath $script:desktopPath) {
        $items = Get-ChildItem -LiteralPath $script:desktopPath -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "desktop.ini" -and -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) }

        switch ($settings.SortBy) {
            "Size" { $items = $items | Sort-Object -Property @{ Expression = { if ($_.PSIsContainer) { 0 } else { $_.Length } }; Descending = $true }, Name }
            "Date" { $items = $items | Sort-Object -Property LastWriteTime -Descending }
            Default { $items = $items | Sort-Object -Property @{ Expression = { if ($_.PSIsContainer) { 0 } else { 1 } } }, Name }
        }

        # Pass 1: Place items with existing non-conflicting saved positions across all active monitors
        foreach ($file in $items) {
            $loadedIcon = Get-DesktopIcon $file $iconSize
            
            $itemObj = [PSCustomObject]@{
                Path     = $file.FullName
                Text     = $file.Name
                Icon     = $loadedIcon
                Bounds   = [System.Drawing.Rectangle]::Empty
                Selected = $false
                Hovered  = $false
            }

            $savedPos = $null
            if (-not $settings.AutoArrange -and $settings.Positions.ContainsKey($file.FullName)) {
                $p = $settings.Positions[$file.FullName]
                if ($null -ne $p) {
                    $coord = Get-VisibleDesktopCoordinate ([int]$p.X) ([int]$p.Y) $itemWidth $itemHeight
                    $savedPos = New-Object System.Drawing.Point($coord.X, $coord.Y)
                }
            }

            if ($null -ne $savedPos) {
                $screen = Get-ScreenForPoint $savedPos.X $savedPos.Y
                $sInfo = Get-ScreenGridBounds $screen
                $col = [int][Math]::Max(0, [Math]::Min($sInfo.Cols - 1, [Math]::Round(($savedPos.X - $sInfo.Left - $sInfo.Margin) / [double]$script:cellWidth)))
                $row = [int][Math]::Max(0, [Math]::Min($sInfo.Rows - 1, [Math]::Round(($savedPos.Y - $sInfo.Top - $sInfo.Margin) / [double]$script:cellHeight)))
                $slotKey = "$($screen.DeviceName)_$col,$row"
                if (-not $occupiedSlots.ContainsKey($slotKey)) {
                    $occupiedSlots[$slotKey] = $true
                    $itemObj.Bounds = New-Object System.Drawing.Rectangle($savedPos.X, $savedPos.Y, $itemWidth, $itemHeight)
                    $script:desktopItems += $itemObj
                } else {
                    $pendingPlacement += $itemObj
                }
            } else {
                $pendingPlacement += $itemObj
            }
        }
    }

    # Pass 2: Place all new/unplaced items into nearest free grid slots across screens (filling columns top to bottom)
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    $pInfo = Get-ScreenGridBounds $primaryScreen
    
    foreach ($itemObj in $pendingPlacement) {
        $freeSlot = Find-NearestFreeGridSlot $pInfo.Left $pInfo.Top $occupiedSlots
        $x = $freeSlot.X
        $y = $freeSlot.Y
        $itemObj.Bounds = New-Object System.Drawing.Rectangle($x, $y, $itemWidth, $itemHeight)
        Save-ItemPosition -Path $itemObj.Path -X $x -Y $y -NoSave
        $script:desktopItems += $itemObj
    }

    # Restore active selection
    $newSelected = @()
    foreach ($sel in $script:selectedItems) {
        $match = $script:desktopItems | Where-Object { $_.Path -eq $sel.Path } | Select-Object -First 1
        if ($null -ne $match) { $match.Selected = $true; $newSelected += $match }
    }
    $script:selectedItems = $newSelected
}

# ============================================================
# 015 - DRAG & DROP AND LASSO SYSTEM (COLLISION FREE)
# ============================================================

$script:dragEnterHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop) -or $e.Data.GetDataPresent("FileGroupDescriptorW") -or $e.Data.GetDataPresent("FileGroupDescriptor") -or $e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::Text)) {
            $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
        } else {
            $e.Effect = [System.Windows.Forms.DragDropEffects]::None
        }
    } catch {}
}

$script:dragOverHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop) -or $e.Data.GetDataPresent("FileGroupDescriptorW") -or $e.Data.GetDataPresent("FileGroupDescriptor") -or $e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::Text)) {
            $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
            $sp = [System.Windows.Forms.Cursor]::Position
            $script:dragDeltaX = $sp.X - $script:dragStartScreen.X
            $script:dragDeltaY = $sp.Y - $script:dragStartScreen.Y
            $sender.Invalidate()
        }
    } catch {}
}

$script:dragLeaveHandler = {
    param($sender, $e)
    if ($null -eq $sender) { return }
    $sender.Invalidate()
}

$script:dragDropHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        $dropScreenPoint = New-Object System.Drawing.Point($e.X, $e.Y)
        $extracted = [OleDropHelper]::ExtractFiles($e.Data, $script:desktopPath)
        
        if ($null -ne $extracted -and $extracted.Count -gt 0) {
            $occupiedMap = Get-OccupiedGridMap
            $curX = $dropScreenPoint.X
            $curY = $dropScreenPoint.Y
            
            foreach ($newFile in $extracted) {
                $slot = Find-NearestFreeGridSlot $curX $curY $occupiedMap
                Save-ItemPosition -Path $newFile -X $slot.X -Y $slot.Y -NoSave
                $curY += [int]$script:cellHeight
            }
            Save-DesktopSettings
            Refresh-Desktop
        }
    } catch {}
}

$script:paintHandler = { param($sender, $e); Paint-DesktopBackground $sender $e }

$script:mouseDownHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        [CustomDesktopForm]::ActivateDesktop()
        $sender.Focus()
        $clickedItem = $null
        foreach ($item in $script:desktopItems) { if ($null -ne $item -and $item.Bounds.Contains($e.Location)) { $clickedItem = $item; break } }
        
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ($null -ne $clickedItem) {
                $now = [Environment]::TickCount
                if ($script:lastClickPanel -eq $clickedItem -and [Math]::Abs($now - $script:lastClickTime) -lt [System.Windows.Forms.SystemInformation]::DoubleClickTime) {
                    $script:lastClickTime = 0
                    Write-DesktopLog "USER DOUBLE-CLICK: Icon '$($clickedItem.Text)' -> launching" -Level "AUDIT"
                    Open-DesktopItem $clickedItem.Path
                    foreach ($p in $script:selectedItems) { if ($p.Path -ne $clickedItem.Path) { Open-DesktopItem $p.Path } }
                    Clear-Selection; return
                }
                $script:lastClickTime = $now; $script:lastClickPanel = $clickedItem
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                
                if ($isCtrl) {
                    if ($script:selectedItems -contains $clickedItem) { 
                        Remove-Selection $clickedItem
                        Write-DesktopLog "USER CLICK: Ctrl+Left-click toggled off selection for '$($clickedItem.Text)'" -Level "AUDIT"
                        return 
                    } else { 
                        Set-Selection $clickedItem 
                        Write-DesktopLog "USER CLICK: Ctrl+Left-click added '$($clickedItem.Text)' to selection" -Level "AUDIT"
                    }
                } else {
                    if ($script:selectedItems -notcontains $clickedItem) {
                        Clear-Selection; Set-Selection $clickedItem
                        Write-DesktopLog "USER CLICK: Left-click selected icon '$($clickedItem.Text)'" -Level "AUDIT"
                    }
                }
                
                $sp = [System.Windows.Forms.Cursor]::Position
                $script:dragStartScreen = $sp
                $script:dragDeltaX = 0; $script:dragDeltaY = 0; $script:isDragging = $false
                $script:dragOriginalPositions.Clear()
                foreach ($item in $script:selectedItems) {
                    if ($null -ne $item) { $script:dragOriginalPositions[$item.Path] = New-Object System.Drawing.Point($item.Bounds.X, $item.Bounds.Y) }
                }
                $script:dragPanel = $clickedItem
                $sender.Capture = $true
            } else {
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                if (-not $isCtrl) { Clear-Selection }
                $script:isLassoing = $true
                $script:lassoStart = $e.Location; $script:lassoEnd = $e.Location
                $script:lassoRect = [System.Drawing.Rectangle]::Empty
                $script:lassoInitialSelection = @($script:selectedItems)
                Write-DesktopLog "USER CLICK: Left-clicked empty desktop at ($($e.X), $($e.Y)) -> started lasso selection" -Level "AUDIT"
            }
        } elseif ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $curPos = [System.Windows.Forms.Cursor]::Position
            if ($null -ne $clickedItem) {
                if ($script:selectedItems -notcontains $clickedItem) { Clear-Selection; Set-Selection $clickedItem }
                if ($clickedItem.Path -eq "::{645FF040-5081-101B-9F08-00AA002F954E}") {
                    Write-DesktopLog "USER CLICK: Right-clicked Recycle Bin at ($($e.X), $($e.Y)) -> opening context menu" -Level "AUDIT"
                    $script:recycleBinContextMenu.Show($curPos)
                } else {
                    Write-DesktopLog "USER CLICK: Right-clicked icon '$($clickedItem.Text)' at ($($e.X), $($e.Y)) -> opening context menu" -Level "AUDIT"
                    $script:itemContextMenu.Tag = $clickedItem.Path
                    $script:itemContextMenu.Show($curPos)
                }
            } else {
                Clear-Selection
                Write-DesktopLog "USER CLICK: Right-clicked empty desktop at ($($e.X), $($e.Y)) -> opening Desktop context menu" -Level "AUDIT"
                $script:contextMenu.Show($curPos)
            }
            return
        }
        $sender.Invalidate()
    } catch { }
}

$script:mouseMoveHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($script:isLassoing) {
            $script:lassoEnd = $e.Location
            $x = [Math]::Min($script:lassoStart.X, $script:lassoEnd.X)
            $y = [Math]::Min($script:lassoStart.Y, $script:lassoEnd.Y)
            $w = [Math]::Abs($script:lassoEnd.X - $script:lassoStart.X)
            $h = [Math]::Abs($script:lassoEnd.Y - $script:lassoStart.Y)
            $script:lassoRect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)

            $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
            foreach ($item in $script:desktopItems) {
                if ($null -eq $item) { continue }
                $intersects = $script:lassoRect.IntersectsWith($item.Bounds)
                if ($intersects) {
                    Set-Selection $item
                } else {
                    if ($isCtrl) {
                        if ($script:lassoInitialSelection -contains $item) { Set-Selection $item } else { Remove-Selection $item }
                    } else {
                        Remove-Selection $item
                    }
                }
            }
            $sender.Invalidate()
            return
        }

        if ($null -ne $script:dragPanel -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $sp = [System.Windows.Forms.Cursor]::Position
            $dx = $sp.X - $script:dragStartScreen.X; $dy = $sp.Y - $script:dragStartScreen.Y
            if (-not $script:isDragging) { 
                if ([Math]::Abs($dx) -gt 3 -or [Math]::Abs($dy) -gt 3) { 
                    $script:isDragging = $true 
                } 
            }
            if ($script:isDragging) {
                $script:dragDeltaX = $dx
                $script:dragDeltaY = $dy
                $sender.Invalidate()
                return
            }
        }

        $foundHover = $null
        foreach ($item in $script:desktopItems) {
            if ($null -ne $item) {
                $inBounds = $item.Bounds.Contains($e.Location)
                if ($inBounds) { $foundHover = $item; $item.Hovered = $true } else { $item.Hovered = $false }
            }
        }
        if ($foundHover -ne $script:hoverItem) { $script:hoverItem = $foundHover; $sender.Invalidate() }
    } catch { }
}

$script:mouseUpHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($script:isLassoing) {
            $script:isLassoing = $false
            $script:lassoRect = [System.Drawing.Rectangle]::Empty
            Write-DesktopLog "USER DRAG: Completed lasso selection (Total selected: $($script:selectedItems.Count))" -Level "AUDIT"
            $sender.Invalidate()
        } elseif ($null -ne $script:dragPanel) {
            if ($script:isDragging) {
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                $occupiedMap = Get-OccupiedGridMap $script:selectedItems
                
                foreach ($item in $script:selectedItems) {
                    if ($null -eq $item) { continue }
                    $orig = $script:dragOriginalPositions[$item.Path]
                    $rawX = if ($null -ne $orig) { [int]$orig.X + [int]$script:dragDeltaX } else { [int]$item.Bounds.X + [int]$script:dragDeltaX }
                    $rawY = if ($null -ne $orig) { [int]$orig.Y + [int]$script:dragDeltaY } else { [int]$item.Bounds.Y + [int]$script:dragDeltaY }
                    
                    if ($isCtrl -or $settings.AlignToGrid) {
                        $freeSlot = Find-NearestFreeGridSlot $rawX $rawY $occupiedMap
                        $snapX = $freeSlot.X
                        $snapY = $freeSlot.Y
                    } else {
                        $snapX = [Math]::Max(0, $rawX)
                        $snapY = [Math]::Max(0, $rawY)
                    }
                    
                    $item.Bounds = New-Object System.Drawing.Rectangle($snapX, $snapY, $item.Bounds.Width, $item.Bounds.Height)
                    Save-ItemPosition -Path $item.Path -X $snapX -Y $snapY -NoSave
                }
                Save-DesktopSettings
                Write-DesktopLog "USER DRAG: Dropped $($script:selectedItems.Count) item(s) at ($($e.X), $($e.Y)) -> positions updated" -Level "AUDIT"
            } else {
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                if (-not $isCtrl) {
                    $t = $script:dragPanel; Clear-Selection; Set-Selection $t
                }
            }
            try { $sender.Capture = $false } catch {}
            $script:dragPanel = $null; $script:isDragging = $false; $script:dragOriginalPositions.Clear(); Invalidate-AllDesktopForms
        }
    } catch { }
}

$script:mouseWheelHandler = {
    param($sender, $e)
    $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
    if ($isCtrl) {
        if ($e.Delta -gt 0) {
            $settings.IconScale = [Math]::Min(160, [int]$settings.IconScale + 8)
        } elseif ($e.Delta -lt 0) {
            $settings.IconScale = [Math]::Max(32, [int]$settings.IconScale - 8)
        }
        Write-DesktopLog "USER INPUT: Ctrl + MouseWheel adjusted icon scale -> $($settings.IconScale)px" -Level "AUDIT"
        Clear-IconCache
        Save-DesktopSettings
        Refresh-Desktop
    }
}

$script:resizeHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        Apply-Background
        $frm = $sender
        if ($null -ne $script:primaryForm -and $frm -eq $script:primaryForm) {
            foreach ($item in $script:desktopItems) {
                if ($null -ne $item) {
                    $coord = Get-VisibleDesktopCoordinate $item.Bounds.X $item.Bounds.Y $item.Bounds.Width $item.Bounds.Height
                    $item.Bounds = New-Object System.Drawing.Rectangle($coord.X, $coord.Y, $item.Bounds.Width, $item.Bounds.Height)
                }
            }
        }
        $frm.Invalidate()
    } catch { }
}

[CustomDesktopForm]::OnDesktopRightClick = [Action[int, int, IntPtr]]{
    param($screenX, $screenY, $hwnd)
    try {
        $curPos = New-Object System.Drawing.Point($screenX, $screenY)
        $targetForm = $null
        foreach ($f in $script:forms) {
            if ($null -ne $f -and $f.Handle -eq $hwnd) { $targetForm = $f; break }
        }
        if ($null -eq $targetForm) { $targetForm = $script:primaryForm }
        $clientPt = if ($null -ne $targetForm) { $targetForm.PointToClient($curPos) } else { $curPos }

        $clickedItem = $null
        if ($null -ne $targetForm) {
            foreach ($item in $script:desktopItems) {
                if ($null -ne $item -and $item.Bounds.Contains($clientPt)) {
                    $clickedItem = $item
                    break
                }
            }
        }

        if ($null -ne $clickedItem) {
            if ($script:selectedItems -notcontains $clickedItem) { Clear-Selection; Set-Selection $clickedItem }
            if ($clickedItem.Path -eq "::{645FF040-5081-101B-9F08-00AA002F954E}") {
                Write-DesktopLog "USER RIGHT-CLICK: Recycle Bin at ($screenX, $screenY)" -Level "AUDIT"
                $script:recycleBinContextMenu.Show($curPos)
            } else {
                Write-DesktopLog "USER RIGHT-CLICK: Icon '$($clickedItem.Text)' at ($screenX, $screenY)" -Level "AUDIT"
                $script:itemContextMenu.Tag = $clickedItem.Path
                $script:itemContextMenu.Show($curPos)
            }
        } else {
            Clear-Selection
            Write-DesktopLog "USER RIGHT-CLICK: Desktop at ($screenX, $screenY)" -Level "AUDIT"
            $script:contextMenu.Show($curPos)
        }
    } catch { }
}

# ============================================================
# 016 - MULTI-MONITOR FORM MANAGER (DYNAMIC HOT-PLUG SAFE)
# ============================================================

function Sync-MultiMonitorForms {
    try {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        if ($null -eq $screens -or $screens.Count -eq 0) { return }

        if ($null -ne $script:forms -and $screens.Count -eq $script:forms.Count) {
            $allMatched = $true
            for ($i = 0; $i -lt $screens.Count; $i++) {
                $s = $screens[$i]
                $f = $script:forms[$i]
                if ($null -eq $f) { $allMatched = $false; break }
                try { if ($f.IsDisposed) { $allMatched = $false; break } } catch { $allMatched = $false; break }
                try {
                    if ($f.Left -ne $s.WorkingArea.Left -or $f.Top -ne $s.WorkingArea.Top -or $f.Width -ne $s.WorkingArea.Width -or $f.Height -ne $s.WorkingArea.Height) {
                        $f.Left = $s.WorkingArea.Left; $f.Top = $s.WorkingArea.Top
                        $f.Width = $s.WorkingArea.Width; $f.Height = $s.WorkingArea.Height
                    }
                } catch { }
            }
            if ($allMatched) { return }
        }

    [CustomDesktopForm]::DesktopHwnds.Clear()
    $newForms = @()

    for ($i = 0; $i -lt $screens.Count; $i++) {
        $screen = $screens[$i]
        $form = if ($i -lt $script:forms.Count -and $null -ne $script:forms[$i] -and -not $script:forms[$i].IsDisposed) { $script:forms[$i] } else { $null }

        if ($null -eq $form) {
            $form = New-Object CustomDesktopForm
            $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
            $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
            $form.ShowInTaskbar = $false
            $form.KeyPreview = $true
            $form.Text = "Emulated Desktop"
            $form.BackColor = $script:Colors.Background
            Enable-DoubleBuffer $form

            $form.AllowDrop = $true
            $form.Add_DragEnter($script:dragEnterHandler)
            $form.Add_DragOver($script:dragOverHandler)
            $form.Add_DragLeave($script:dragLeaveHandler)
            $form.Add_DragDrop($script:dragDropHandler)
            $form.Add_Paint($script:paintHandler)
            $form.Add_MouseDown($script:mouseDownHandler)
            $form.Add_MouseMove($script:mouseMoveHandler)
            $form.Add_MouseUp($script:mouseUpHandler)
            $form.Add_MouseWheel($script:mouseWheelHandler)
            $form.Add_Resize($script:resizeHandler)
            $form.Add_KeyDown($script:keyDownHandler)
        }

        $form.Left = $screen.WorkingArea.Left
        $form.Top = $screen.WorkingArea.Top
        $form.Width = $screen.WorkingArea.Width
        $form.Height = $screen.WorkingArea.Height
        [void][CustomDesktopForm]::DesktopHwnds.Add($form.Handle)
        $newForms += $form
    }

    if ($script:forms.Count -gt $screens.Count) {
        for ($j = $screens.Count; $j -lt $script:forms.Count; $j++) {
            $extra = $script:forms[$j]
            if ($null -ne $extra -and -not $extra.IsDisposed) {
                try { $extra.Hide(); $extra.Dispose() } catch {}
            }
        }
    }

    $script:forms = $newForms

    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    foreach ($form in $script:forms) {
        if ($form.Left -eq $primaryScreen.WorkingArea.Left -and $form.Top -eq $primaryScreen.WorkingArea.Top) {
            $script:primaryForm = $form
            break
        }
    }
    if ($null -eq $script:primaryForm -and $script:forms.Count -gt 0) { $script:primaryForm = $script:forms[0] }
    foreach ($form in $script:forms) { try { $form.Show() } catch { } }
    } catch { }
}

$script:winDInterceptor = New-Object WinDInterceptor

# ============================================================
# 017 - KEYBOARD SHORTCUTS & NAVIGATION
# ============================================================

function Show-ConfirmExitDialog {
    $uiScale = 1.0; if ($null -ne $settings.UiScale) { $uiScale = [double]$settings.UiScale }
    
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Exit Desktop Emulator"
    $dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $dlg.Width = [int](400 * $uiScale); $dlg.Height = [int](180 * $uiScale)
    $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    $dlg.KeyPreview = $true
    $dlg.TopMost = $true
    Enable-DoubleBuffer $dlg

    $dlg.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#ef4444"), 2)
        try { $e.Graphics.DrawRectangle($pen, 1, 1, $s.Width - 2, $s.Height - 2) } finally { $pen.Dispose() }
    })

    $titleLbl = New-Object System.Windows.Forms.Label
    $titleLbl.Text = "Exit RedSkia Desktop"
    $titleLbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](13 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $titleLbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $titleLbl.AutoSize = $true; $titleLbl.Left = [int](25 * $uiScale); $titleLbl.Top = [int](22 * $uiScale)
    $dlg.Controls.Add($titleLbl)

    $msgLbl = New-Object System.Windows.Forms.Label
    $msgLbl.Text = "Are you sure you want to exit Desktop Emulator?"
    $msgLbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](10 * $uiScale))
    $msgLbl.ForeColor = [System.Drawing.Color]::White
    $msgLbl.AutoSize = $true; $msgLbl.Left = [int](25 * $uiScale); $msgLbl.Top = [int](60 * $uiScale)
    $dlg.Controls.Add($msgLbl)

    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = "Yes (Exit)"
    $btnYes.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $btnYes.Left = [int](85 * $uiScale); $btnYes.Top = [int](115 * $uiScale); $btnYes.Width = [int](105 * $uiScale); $btnYes.Height = [int](34 * $uiScale)
    $btnYes.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnYes.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#dc2626")
    $btnYes.ForeColor = [System.Drawing.Color]::White
    $btnYes.FlatAppearance.BorderSize = 0
    $btnYes.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnYes.Add_Click({ $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Yes; $dlg.Close() })
    $dlg.Controls.Add($btnYes)

    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = "No (Stay)"
    $btnNo.Font = New-Object System.Drawing.Font("Segoe UI", [float](9.5 * $uiScale))
    $btnNo.Left = [int](210 * $uiScale); $btnNo.Top = [int](115 * $uiScale); $btnNo.Width = [int](105 * $uiScale); $btnNo.Height = [int](34 * $uiScale)
    $btnNo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnNo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
    $btnNo.ForeColor = [System.Drawing.Color]::White
    $btnNo.FlatAppearance.BorderSize = 0
    $btnNo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnNo.Add_Click({ $dlg.DialogResult = [System.Windows.Forms.DialogResult]::No; $dlg.Close() })
    $dlg.Controls.Add($btnNo)

    $dlg.Add_KeyDown({
        param($s, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter -or $e.KeyCode -eq [System.Windows.Forms.Keys]::Y) {
            $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Yes
            $dlg.Close()
            $e.Handled = $true
        } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape -or $e.KeyCode -eq [System.Windows.Forms.Keys]::N) {
            $dlg.DialogResult = [System.Windows.Forms.DialogResult]::No
            $dlg.Close()
            $e.Handled = $true
        }
    })

    $owner = if ($null -ne $script:primaryForm -and -not $script:primaryForm.IsDisposed) { $script:primaryForm } else { $null }
    $res = $dlg.ShowDialog($owner)
    $dlg.Dispose()
    return ($res -eq [System.Windows.Forms.DialogResult]::Yes)
}

$script:keyDownHandler = {
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        if ($script:selectedItems.Count -gt 0) {
            Write-DesktopLog "USER KEY: Escape pressed -> cleared selection ($($script:selectedItems.Count) items)" -Level "AUDIT"
            Clear-Selection
            $e.Handled = $true; $e.SuppressKeyPress = $true; return
        }
        $shouldExit = $true
        if ($settings.ConfirmExit) {
            Write-DesktopLog "USER KEY: Escape pressed on desktop -> showing Exit confirmation dialog" -Level "AUDIT"
            $shouldExit = Show-ConfirmExitDialog
        }
        if ($shouldExit) {
            Write-DesktopLog "USER ACTION: Exit confirmed -> closing all desktop emulator forms" -Level "AUDIT"
            foreach ($closeForm in $script:forms) { if ($null -ne $closeForm -and -not $closeForm.IsDisposed) { $closeForm.Close() } }
            $script:appContext.ExitThread()
        } else {
            Write-DesktopLog "USER ACTION: Exit declined by user" -Level "AUDIT"
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F5) { 
        Write-DesktopLog "USER KEY: Pressed F5 -> refreshing desktop" -Level "AUDIT"
        Refresh-Desktop; $e.Handled = $true; $e.SuppressKeyPress = $true; return 
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F8) { 
        Write-DesktopLog "USER KEY: Pressed F8 -> opening Settings" -Level "AUDIT"
        Show-Settings; $e.Handled = $true; $e.SuppressKeyPress = $true; return 
    }
    
    $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
    $isAlt  = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Alt) -eq [System.Windows.Forms.Keys]::Alt)
    $isShift = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift) -eq [System.Windows.Forms.Keys]::Shift)
    
    # Ctrl+P: Settings
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::P) {
        Write-DesktopLog "USER KEY: Pressed Ctrl+P -> opening Settings" -Level "AUDIT"
        Show-Settings
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    # Ctrl+Shift+N: New Folder
    if ($isCtrl -and $isShift -and $e.KeyCode -eq [System.Windows.Forms.Keys]::N) {
        Write-DesktopLog "USER KEY: Pressed Ctrl+Shift+N -> creating new folder" -Level "AUDIT"
        New-DesktopFolder
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    # Ctrl+A: Select All
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::A) {
        $script:selectedItems = @($script:desktopItems)
        foreach ($item in $script:desktopItems) { if ($null -ne $item) { $item.Selected = $true } }
        Write-DesktopLog "USER KEY: Pressed Ctrl+A -> selected all $($script:desktopItems.Count) items" -Level "AUDIT"
        Invalidate-AllDesktopForms
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # Ctrl+X: Cut
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::X) { 
        Write-DesktopLog "USER KEY: Pressed Ctrl+X -> cutting selected items" -Level "AUDIT"
        Cut-SelectedFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return 
    }

    # Ctrl+C: Copy
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::C) { 
        Write-DesktopLog "USER KEY: Pressed Ctrl+C -> copying selected items" -Level "AUDIT"
        Copy-SelectedFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return 
    }

    # Ctrl+V: Paste
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::V) { 
        Write-DesktopLog "USER KEY: Pressed Ctrl+V -> pasting from clipboard" -Level "AUDIT"
        Paste-ClipboardFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return 
    }

    # Alt+Enter: Properties
    if ($isAlt -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        if ($script:selectedItems.Count -gt 0) {
            $p = [string]$script:selectedItems[0].Path
            Write-DesktopLog "USER KEY: Pressed Alt+Enter -> showing properties for '$p'" -Level "AUDIT"
            if (-not [string]::IsNullOrWhiteSpace($p)) { Show-ItemProperties $p }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # Enter: Open selected items
    if (-not $isAlt -and -not $isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        Write-DesktopLog "USER KEY: Pressed Enter -> launching $($script:selectedItems.Count) selected item(s)" -Level "AUDIT"
        foreach ($item in $script:selectedItems) {
            $path = [string]$item.Path
            if (-not [string]::IsNullOrWhiteSpace($path)) { Open-DesktopItem $path }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # F2: Rename
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F2) {
        if ($script:selectedItems.Count -eq 1) { 
            $path = [string]$script:selectedItems[0].Path
            Write-DesktopLog "USER KEY: Pressed F2 -> renaming '$path'" -Level "AUDIT"
            if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) { Rename-DesktopItem $path }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    # Delete / Shift+Delete
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Delete) {
        if ($script:selectedItems.Count -gt 0) { 
            Write-DesktopLog "USER KEY: Pressed Delete -> deleting $($script:selectedItems.Count) item(s)" -Level "AUDIT"
            Delete-DesktopItems 
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::PageUp) {
        $settings.IconScale = [Math]::Min(160, [int]$settings.IconScale + 8)
        Write-DesktopLog "USER KEY: PageUp pressed -> increased icon scale to $($settings.IconScale)px" -Level "AUDIT"
        Clear-IconCache; Save-DesktopSettings; Refresh-Desktop
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::PageDown) {
        $settings.IconScale = [Math]::Max(32, [int]$settings.IconScale - 8)
        Write-DesktopLog "USER KEY: PageDown pressed -> decreased icon scale to $($settings.IconScale)px" -Level "AUDIT"
        Clear-IconCache; Save-DesktopSettings; Refresh-Desktop
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # Arrow Navigation
    if ($e.KeyCode -in @([System.Windows.Forms.Keys]::Left, [System.Windows.Forms.Keys]::Right, [System.Windows.Forms.Keys]::Up, [System.Windows.Forms.Keys]::Down)) {
        if ($script:desktopItems.Count -gt 0) {
            $curr = if ($script:selectedItems.Count -gt 0) { $script:selectedItems[0] } else { $script:desktopItems[0] }
            $bestItem = $null; $bestDist = [double]::MaxValue
            $cx = $curr.Bounds.X + ($curr.Bounds.Width / 2.0); $cy = $curr.Bounds.Y + ($curr.Bounds.Height / 2.0)
            
            foreach ($item in $script:desktopItems) {
                if ($null -eq $item -or $item -eq $curr) { continue }
                $ix = $item.Bounds.X + ($item.Bounds.Width / 2.0); $iy = $item.Bounds.Y + ($item.Bounds.Height / 2.0)
                $dx = $ix - $cx; $dy = $iy - $cy
                
                $isCandidate = $false
                if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Right -and $dx -gt 10) {
                    $dist = ($dx * 1.0) + ([Math]::Abs($dy) * 2.5); $isCandidate = $true
                } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Left -and $dx -lt -10) {
                    $dist = ([Math]::Abs($dx) * 1.0) + ([Math]::Abs($dy) * 2.5); $isCandidate = $true
                } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Down -and $dy -gt 10) {
                    $dist = ([Math]::Abs($dx) * 2.5) + ($dy * 1.0); $isCandidate = $true
                } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Up -and $dy -lt -10) {
                    $dist = ([Math]::Abs($dx) * 2.5) + ([Math]::Abs($dy) * 1.0); $isCandidate = $true
                }
                
                if ($isCandidate -and $dist -lt $bestDist) {
                    $bestDist = $dist; $bestItem = $item
                }
            }
            
            if ($null -ne $bestItem) {
                Write-DesktopLog "USER KEY: Arrow key navigation selected '$($bestItem.Text)'" -Level "AUDIT"
                Clear-Selection; Set-Selection $bestItem
            }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    # Type-to-select
    if (-not $isCtrl -and -not $isAlt -and ($e.KeyValue -ge 48 -and $e.KeyValue -le 90)) {
        $char = [char]$e.KeyValue
        $matched = $null; $startIndex = 0
        if ($script:selectedItems.Count -gt 0) {
            $idx = $script:desktopItems.IndexOf($script:selectedItems[0])
            if ($idx -ge 0) { $startIndex = $idx + 1 }
        }
        for ($i = 0; $i -lt $script:desktopItems.Count; $i++) {
            $checkIdx = ($startIndex + $i) % $script:desktopItems.Count
            $candidate = $script:desktopItems[$checkIdx]
            if ($null -ne $candidate -and $candidate.Text.StartsWith($char, [System.StringComparison]::OrdinalIgnoreCase)) {
                $matched = $candidate; break
            }
        }
        if ($null -ne $matched) {
            Write-DesktopLog "USER KEY: Type-to-select character '$char' focused icon '$($matched.Text)'" -Level "AUDIT"
            Clear-Selection; Set-Selection $matched
            $e.Handled = $true; $e.SuppressKeyPress = $true; return
        }
    }
}

# ============================================================
# 018 - FILE SYSTEM WATCHER & RESOLUTION TIMER
# ============================================================

function Init-FileSystemWatcher {
    if ($script:fsw) { try { $script:fsw.EnableRaisingEvents = $false; $script:fsw.Dispose() } catch {} }
    try {
        $script:fsw = New-Object System.IO.FileSystemWatcher
        $script:fsw.Path = $script:desktopPath
        $script:fsw.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size
        $script:fsw.IncludeSubdirectories = $false
        if ($null -ne $script:primaryForm -and -not $script:primaryForm.IsDisposed) {
            $script:fsw.SynchronizingObject = $script:primaryForm
        }
        $script:fsw.EnableRaisingEvents = $true

        $script:fsw.Add_Created({ 
            param($s, $e)
            if ($e.FullPath -ieq $script:logFile -or $e.Name -match "(?i)^desktop\.log|\.tmp$") { return }
            Write-DesktopLog "FSW EVENT: Created -> '$($e.FullPath)'" -Level "AUDIT"
            $script:refreshPending = $true 
        })
        $script:fsw.Add_Deleted({ 
            param($s, $e)
            if ($e.FullPath -ieq $script:logFile -or $e.Name -match "(?i)^desktop\.log|\.tmp$") { return }
            Write-DesktopLog "FSW EVENT: Deleted -> '$($e.FullPath)'" -Level "AUDIT"
            $script:refreshPending = $true 
        })
        $script:fsw.Add_Renamed({ 
            param($s, $e)
            if ($e.FullPath -ieq $script:logFile -or $e.OldFullPath -ieq $script:logFile -or $e.Name -match "(?i)^desktop\.log|\.tmp$") { return }
            Write-DesktopLog "FSW EVENT: Renamed -> '$($e.OldFullPath)' to '$($e.FullPath)'" -Level "AUDIT"
            $script:refreshPending = $true 
        })
        $script:fsw.Add_Changed({ 
            param($s, $e)
            if ($e.FullPath -ieq $script:logFile -or $e.Name -match "(?i)^desktop\.log|\.tmp$") { return }
            Write-DesktopLog "FSW EVENT: Changed -> '$($e.FullPath)'" -Level "AUDIT"
            $script:refreshPending = $true 
        })
        Write-DesktopLog "FileSystemWatcher active on '$script:desktopPath'"
    } catch { 
        Write-DesktopLog "FileSystemWatcher initialization failed" -Level "ERROR" -Exception $_.Exception
    }
}

$script:refreshTimer.Add_Tick({
    try {
        Sync-MultiMonitorForms
    } catch {}

    try {
        [WinDInterceptor]::EnsureHookActive()
    } catch {}

    try {
        if ($settings.ShowWidgets -and $null -ne $script:primaryForm -and -not $script:primaryForm.IsDisposed -and -not $script:isDragging -and -not $script:isLassoing) {
            $script:primaryForm.Invalidate()
        }
    } catch {}

    if ($script:refreshPending -and -not $script:isDragging -and -not $script:isLassoing -and -not $script:isPasting) {
        $script:refreshPending = $false
        Refresh-Desktop
    }
})

# ============================================================
# 019 - INITIALIZATION & WINFORMS LOOP
# ============================================================

Write-ConsoleStatus "  [1/4] Syncing multi-monitor displays..." "Gray"
Write-DesktopLog "Initializing multi-monitor forms and displays..."
Sync-MultiMonitorForms
Write-ConsoleStatus "        -> Active displays: $($script:forms.Count) [OK]" "Green"
Write-DesktopLog "Displays synced (Active forms: $($script:forms.Count))"

Write-ConsoleStatus "  [2/4] Rendering background canvas & glass HUD..." "Gray"
Create-ContextMenus
Apply-Background
Write-ConsoleStatus "        -> Canvas & context menus initialized [OK]" "Green"

Write-ConsoleStatus "  [3/4] Indexing desktop items & shell icons..." "Gray"
Build-DesktopIcons
Write-ConsoleStatus "        -> Loaded $($script:desktopItems.Count) desktop items [OK]" "Green"

Write-ConsoleStatus "  [4/4] Activating Boss Key & Global Interceptors..." "Gray"
Apply-BossKeySettings
Init-FileSystemWatcher
$script:refreshTimer.Start()
Write-ConsoleStatus "        -> Global low-level hooks engaged [OK]" "Green"

Write-ConsoleStatus ""
Write-ConsoleStatus "  [+] Activating Desktop Surface..." "Gray"
[void][CustomDesktopForm]::ActivateDesktop()

Write-ConsoleStatus "  ================================================================" "DarkRed"
Write-ConsoleStatus "   [OK] RedSkia.dev Desktop Emulator is ACTIVE & RUNNING!" "Green"
Write-ConsoleStatus "  ================================================================" "DarkRed"

Write-DesktopLog "RedSkia.Dev Desktop Emulator running message loop."
[void][NativeWindowDrag]::HideConsole()
[void][CustomDesktopForm]::HideConsole()
[void][CustomDesktopForm]::ActivateDesktop()
if ($null -ne $script:primaryForm -and -not $script:primaryForm.IsDisposed) {
    try {
        [void]$script:primaryForm.BringToFront()
        [void]$script:primaryForm.Focus()
    } catch { }
}

# WinForms Message Pump (Safe ApplicationContext Loop)
try {
    [System.Windows.Forms.Application]::Run($script:appContext)
} catch {
    Write-DesktopLog "Application message pump encountered an error" -Level "ERROR" -Exception $_.Exception
}

# Cleanup
Write-DesktopLog "Initiating graceful desktop shutdown..."
try { Save-AllPositions; Save-DesktopSettings; Dispose-DesktopControls } catch { }
try { [LiveWallpaperEngine]::StopGifAnimation(); Stop-VideoWallpaper } catch { }
if ($script:winDInterceptor) { try { $script:winDInterceptor.Dispose() } catch {} }
if ($script:refreshTimer) { try { $script:refreshTimer.Stop(); $script:refreshTimer.Dispose() } catch {} }
if ($script:fsw) { try { $script:fsw.Dispose() } catch {} }
if ($script:backgroundImage) { try { $script:backgroundImage.Dispose() } catch { } }
foreach ($form in $script:forms) { if ($null -ne $form -and -not $form.IsDisposed) { try { $form.Dispose() } catch { } } }
Clear-IconCache
if ($script:contextMenu) { try { $script:contextMenu.Dispose() } catch { } }
if ($script:itemContextMenu) { try { $script:itemContextMenu.Dispose() } catch { } }
if ($script:recycleBinContextMenu) { try { $script:recycleBinContextMenu.Dispose() } catch { } }

Write-DesktopLog "RedSkia.Dev Desktop Emulator terminated cleanly."
[System.Environment]::Exit(0)
