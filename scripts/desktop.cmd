@echo off
setlocal EnableExtensions
chcp 65001 >nul

rem ============================================================
rem 001 - CMD BOOTSTRAP (100%% HIDDEN SPAWN & AUTO-CLOSE CMD)
rem ============================================================

set "EMULATED_CMD=%~f0"
set "PSFILE=%TEMP%\EmulatedDesktop_%RANDOM%_%RANDOM%.ps1"
set "VBSFILE=%TEMP%\EmulatedDesktop_%RANDOM%_%RANDOM%.vbs"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
 "$a=Get-Content -LiteralPath $env:EMULATED_CMD;" ^
 "$i=[Array]::IndexOf($a,'#=== POWERSHELL START ===');" ^
 "if($i -lt 0){exit 1};" ^
 "$a[($i+1)..($a.Length-1)] | Set-Content -LiteralPath $env:PSFILE -Encoding UTF8"

if not exist "%PSFILE%" exit /b 1

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo WshShell.Run "powershell.exe -WindowStyle Hidden -STA -NoProfile -ExecutionPolicy Bypass -File """ ^& "%PSFILE%" ^& """", 0, False
echo Set WshShell = Nothing
) > "%VBSFILE%"

start "" wscript.exe "%VBSFILE%"

timeout /t 1 /nobreak >nul 2>&1
if exist "%VBSFILE%" del /f /q "%VBSFILE%" >nul 2>&1
exit /b 0


#=== POWERSHELL START ===

# ============================================================
# 002 - ASSEMBLIES & VISUAL STYLES
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# 003 - SETTINGS DIRECTORY & PERSISTENCE
# ============================================================

$settingsDirectory = Join-Path $env:LOCALAPPDATA "EmulatedDesktop"
$settingsFile = Join-Path $settingsDirectory "settings.json"

if (-not (Test-Path -LiteralPath $settingsDirectory)) {
    New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
}

function Get-DefaultSettings {
    return [ordered]@{
        BackgroundType   = "Color"
        BackgroundColor  = "#0b0f19"
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
        Positions        = @{}
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
if ([string]::IsNullOrWhiteSpace($settings.BackgroundColor)) { $settings.BackgroundColor = "#0b0f19" }
if ([string]::IsNullOrWhiteSpace($settings.BackgroundType)) { $settings.BackgroundType = "Color" }
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
$script:refreshTimer.Interval = 400

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
            BackgroundType   = [string]$settings.BackgroundType
            BackgroundColor  = [string]$settings.BackgroundColor
            ImagePath        = [string]$settings.ImagePath
            ImageMode        = [string]$settings.ImageMode
            WallpaperDimming = [int]$settings.WallpaperDimming
            IconScale        = [int]$settings.IconScale
            UiScale          = [double]$settings.UiScale
            SortBy           = [string]$settings.SortBy
            AutoArrange      = [bool]$settings.AutoArrange
            AlignToGrid      = [bool]$settings.AlignToGrid
            ShowDesktopIcons = [bool]$settings.ShowDesktopIcons
            ShowRecycleBin   = [bool]$settings.ShowRecycleBin
            DesktopPath      = [string]$settings.DesktopPath
            Positions        = $settings.Positions
        }
        $json = $object | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($settingsFile, $json, [System.Text.UTF8Encoding]::new($false))
    } catch { }
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

    public static void DragWindow(IntPtr hWnd) {
        try {
            ReleaseCapture();
            SendMessage(hWnd, WM_NCLBUTTONDOWN, (IntPtr)HTCAPTION, IntPtr.Zero);
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

    [DllImport("kernel32.dll")]
    private static extern bool FreeConsole();

    public static HashSet<IntPtr> DesktopHwnds = new HashSet<IntPtr>();

    public static void HideConsole() {
        try {
            FreeConsole();
            IntPtr hWnd = GetConsoleWindow();
            if (hWnd != IntPtr.Zero) {
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

    protected override void WndProc(ref Message m) {
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

public class WinDInterceptor : IDisposable {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int VK_D = 0x44;
    private const int VK_M = 0x4D;
    private const int VK_LWIN = 0x5B;
    private const int VK_RWIN = 0x5C;
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
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern IntPtr GetShellWindow();

    private IntPtr _hookId = IntPtr.Zero;
    private LowLevelKeyboardProc _proc;
    private GCHandle _procHandle;
    private static List<IntPtr> _minimizedByWinD = new List<IntPtr>();

    public WinDInterceptor() {
        try {
            _proc = HookCallback;
            _procHandle = GCHandle.Alloc(_proc);
            using (Process curProcess = Process.GetCurrentProcess())
            using (ProcessModule curModule = curProcess.MainModule) {
                _hookId = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
            }
        } catch { }
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        try {
            if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN)) {
                KBDLLHOOKSTRUCT kb = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
                if (kb.vkCode == VK_D || kb.vkCode == VK_M) {
                    bool winDown = ((GetAsyncKeyState(VK_LWIN) & 0x8000) != 0) || ((GetAsyncKeyState(VK_RWIN) & 0x8000) != 0);
                    if (winDown) {
                        ToggleDesktop();
                        return (IntPtr)1;
                    }
                }
            }
        } catch { }
        return CallNextHookEx(_hookId, nCode, wParam, lParam);
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
                _minimizedByWinD.Clear();
            } else {
                EnumWindows((hWnd, lParam) => {
                    if (hWnd != shellHwnd && !CustomDesktopForm.DesktopHwnds.Contains(hWnd) && IsWindowVisible(hWnd) && !IsIconic(hWnd)) {
                        ShowWindowAsync(hWnd, SW_MINIMIZE);
                        _minimizedByWinD.Add(hWnd);
                    }
                    return true;
                }, IntPtr.Zero);
            }
        } catch { }
    }

    public void Dispose() {
        try {
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
        [PreserveSig] int Copy(int iDst, IImageList punkSrc, int iSrc, int uFlags);
        [PreserveSig] int Merge(int i1, IImageList punk2, int i2, int dx, int dy, ref Guid riid, ref IntPtr ppv);
        [PreserveSig] int Clone(ref Guid riid, ref IntPtr ppv);
        [PreserveSig] int GetImageRect(int i, IntPtr prc);
        [PreserveSig] int GetIconSize(ref int cx, ref int cy);
        [PreserveSig] int SetIconSize(int cx, int cy);
        [PreserveSig] int GetImageCount(ref int pi);
        [PreserveSig] int SetImageCount(int uNewCount);
        [PreserveSig] int SetBkColor(int clrBk, ref int pclr);
        [PreserveSig] int GetBkColor(ref int pclr);
        [PreserveSig] int BeginDrag(int iTrack, int dxHotspot, int dyHotspot);
        [PreserveSig] int EndDrag();
        [PreserveSig] int DragEnter(IntPtr hwndLock, int x, int y);
        [PreserveSig] int DragLeave(IntPtr hwndLock);
        [PreserveSig] int DragMove(int x, int y);
        [PreserveSig] int SetDragCursorImage(ref IImageList punk, int iDrag, int dxHotspot, int dyHotspot);
        [PreserveSig] int DragShowNolock(int fShow);
        [PreserveSig] int GetDragImage(IntPtr ppt, IntPtr pptHotspot, ref Guid riid, ref IntPtr ppv);
        [PreserveSig] int GetItemFlags(int i, ref int dwFlags);
        [PreserveSig] int GetOverlayImage(int iOverlay, ref int piIndex);
    };

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
                    Guid iidImageList = new Guid("46EB5926-582E-4017-9FDF-E8998DAA0950");
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
                                        using (Bitmap tmp = icon.ToBitmap()) {
                                            return new Bitmap(tmp);
                                        }
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
                Guid iidImageList = new Guid("46EB5926-582E-4017-9FDF-E8998DAA0950");
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
                                    using (Bitmap tmp = icon.ToBitmap()) {
                                        return new Bitmap(tmp);
                                    }
                                } 
                            }
                            finally { DestroyIcon(hIcon); }
                        }
                    }
                    finally { Marshal.ReleaseComObject(iml); }
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
'@ -ReferencedAssemblies @("System.Drawing", "System.Windows.Forms")

# Hide console window immediately on startup
[CustomDesktopForm]::HideConsole()

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

# ============================================================
# 010 - BACKGROUND RENDERING & PAINT ENGINE (DIRECT ZERO FLICKER)
# ============================================================

function Load-BackgroundImage {
    if ($null -ne $script:backgroundImage) { 
        try { $script:backgroundImage.Dispose() } catch { }
        $script:backgroundImage = $null 
    }
    if ($settings.BackgroundType -ne "Image" -or [string]::IsNullOrWhiteSpace($settings.ImagePath) -or -not (Test-Path -LiteralPath $settings.ImagePath)) { return }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($settings.ImagePath)
        $ms = New-Object System.IO.MemoryStream($bytes, 0, $bytes.Length)
        $source = [System.Drawing.Image]::FromStream($ms)
        try { 
            $script:backgroundImage = New-Object System.Drawing.Bitmap($source) 
        } finally { 
            $source.Dispose()
            $ms.Dispose()
        }
    } catch { 
        $script:backgroundImage = $null 
    }
}

function Apply-Background {
    Load-BackgroundImage
    foreach ($form in $script:forms) {
        if ($null -eq $form -or $form.IsDisposed -or $form.ClientSize.Width -le 0 -or $form.ClientSize.Height -le 0) { continue }
        
        try {
            $bmp = New-Object System.Drawing.Bitmap($form.ClientSize.Width, $form.ClientSize.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $g.Clear((Get-ColorFromHex $settings.BackgroundColor))
            
                if ($settings.BackgroundType -eq "Image" -and $null -ne $script:backgroundImage) {
                    $image = $script:backgroundImage
                    if ($image.Width -gt 0 -and $image.Height -gt 0) {
                        $width = $bmp.Width; $height = $bmp.Height
                        try {
                            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                            $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            
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
                            
                            $dimVal = [Math]::Max(0, [Math]::Min(90, [int]$settings.WallpaperDimming))
                            if ($dimVal -gt 0) {
                                $alpha = [int](255 * ($dimVal / 100.0))
                                $dimBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 0, 0, 0))
                                try {
                                    $g.FillRectangle($dimBrush, 0, 0, $width, $height)
                                } finally { $dimBrush.Dispose() }
                            }
                        } catch { }
                    }
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
                $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1)
                $gridPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                try {
                    $sInfo = Get-ScreenGridBounds (Get-ScreenForPoint $Sender.Left $Sender.Top)
                    for ($c = 0; $c -le $sInfo.Cols; $c++) {
                        $gx = $sInfo.Margin + ($c * $cWidth)
                        $g.DrawLine($gridPen, $gx, 0, $gx, $Sender.ClientSize.Height)
                    }
                    for ($r = 0; $r -le $sInfo.Rows; $r++) {
                        $gy = $sInfo.Margin + ($r * $cHeight)
                        $g.DrawLine($gridPen, 0, $gy, $Sender.ClientSize.Width, $gy)
                    }
                } finally { $gridPen.Dispose() }
            }

            # 4. Drag Ghost Preview (Adaptive screen-aware snap preview)
            if ($script:isDragging -and $script:selectedItems.Count -gt 0) {
                $ghostSelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(85, 59, 130, 246))
                $ghostBorderPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#3b82f6"), 1)
                
                try {
                    foreach ($sel in $script:selectedItems) {
                        if ($null -eq $sel) { continue }
                        $orig = $script:dragOriginalPositions[$sel.Path]
                        $rawX = if ($null -ne $orig) { [int]$orig.X + [int]$script:dragDeltaX } else { [int]$sel.Bounds.X + [int]$script:dragDeltaX }
                        $rawY = if ($null -ne $orig) { [int]$orig.Y + [int]$script:dragDeltaY } else { [int]$sel.Bounds.Y + [int]$script:dragDeltaY }
                        
                        if ($isCtrl -or $settings.AlignToGrid) {
                            $targetScreen = Get-ScreenForPoint $rawX $rawY
                            $sInfo = Get-ScreenGridBounds $targetScreen
                            $relX = $rawX - $sInfo.Left - $sInfo.Margin
                            $relY = $rawY - $sInfo.Top - $sInfo.Margin
                            $col = [int][Math]::Max(0, [Math]::Min($sInfo.Cols - 1, [Math]::Round($relX / [double]$cWidth)))
                            $row = [int][Math]::Max(0, [Math]::Min($sInfo.Rows - 1, [Math]::Round($relY / [double]$cHeight)))
                            $rawX = $sInfo.Left + $sInfo.Margin + ($col * $cWidth)
                            $rawY = $sInfo.Top + $sInfo.Margin + ($row * $cHeight)
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
        try { Start-Process "explorer.exe" -ArgumentList "shell:RecycleBinFolder" -ErrorAction SilentlyContinue } catch {}
        return
    }
    if (-not (Test-Path -LiteralPath $Path)) { return }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Path
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        try { Invoke-Item -LiteralPath $Path -ErrorAction SilentlyContinue } catch { }
    }
}

function Save-ItemPosition {
    param([string]$Path, [int]$X, [int]$Y, [switch]$NoSave)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $settings.Positions[$Path] = @{ X = $X; Y = $Y }
    if (-not $NoSave) { Save-DesktopSettings }
}

function Save-AllPositions {
    foreach ($item in $script:desktopItems) {
        if ($null -eq $item) { continue }
        Save-ItemPosition -Path $item.Path -X $item.Bounds.X -Y $item.Bounds.Y -NoSave
    }
    Save-DesktopSettings
}

function Rename-DesktopItem {
    param([string]$Path)
    if ($Path -eq "::{645FF040-5081-101B-9F08-00AA002F954E}" -or -not (Test-Path -LiteralPath $Path)) { return }
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
            } catch { [System.Windows.Forms.MessageBox]::Show("Could not rename the item.", "Rename", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null }
        })
        $cancel.Add_Click({ $dialog.Close() })
        
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
        $msg = if ($count -eq 1) { "Move this item to the Recycle Bin?" } else { "Move these $count items to the Recycle Bin?" }
        $result = [System.Windows.Forms.MessageBox]::Show($msg, "Delete", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        
        $shell = New-Object -ComObject Shell.Application
        try {
            foreach ($item in $realItems) {
                $path = [string]$item.Path
                if (-not (Test-Path -LiteralPath $path)) { continue }
                $folder = $shell.Namespace((Split-Path -Parent $path)); $shellItem = $folder.ParseName((Split-Path -Leaf $path))
                if ($null -ne $shellItem) { $shellItem.InvokeVerb("delete") }
                if ($settings.Positions.ContainsKey($path)) { $settings.Positions.Remove($path) }
            }
        } finally {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        Save-DesktopSettings; Clear-Selection; Refresh-Desktop
    } catch { }
}

function Show-ItemProperties {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    try {
        $owner = if ($null -ne $script:primaryForm) { $script:primaryForm.Handle } else { [IntPtr]::Zero }
        [ShellIcons]::ShowProperties($Path, $owner)
    } catch { }
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
        if ($paths.Count -gt 0) { [System.Windows.Forms.Clipboard]::SetFileDropList($paths) }
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
        if ($paths.Count -gt 0) { [System.Windows.Forms.Clipboard]::SetFileDropList($paths) }
        Invalidate-AllDesktopForms
    } catch { }
}

function Paste-ClipboardFiles {
    $now = [Environment]::TickCount
    if ($script:isPasting -or [Math]::Abs($now - $script:lastPasteTime) -lt 250) { return }
    $script:lastPasteTime = $now
    $script:isPasting = $true
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
        Refresh-Desktop
    } catch { }
}

function New-DesktopTextFile {
    try {
        $number = 0
        do { if ($number -eq 0) { $name = "New Text Document.txt" } else { $name = "New Text Document ($number).txt" }; $path = Join-Path $script:desktopPath $name; $number++ } while (Test-Path -LiteralPath $path)
        [System.IO.File]::WriteAllText($path, "")
        Refresh-Desktop
    } catch { }
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

    Add-MenuItem $viewMenu "Large icons" $null { $settings.IconScale = 96; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop } ($settings.IconScale -ge 96) | Out-Null
    Add-MenuItem $viewMenu "Medium icons" $null { $settings.IconScale = 72; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop } ($settings.IconScale -ge 64 -and $settings.IconScale -lt 96) | Out-Null
    Add-MenuItem $viewMenu "Small icons" $null { $settings.IconScale = 48; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop } ($settings.IconScale -lt 64) | Out-Null
    [void]$viewMenu.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $viewMenu "Auto arrange icons" $null { 
        $settings.AutoArrange = $false
        $settings.Positions = @{}
        Save-DesktopSettings; Refresh-Desktop 
    } | Out-Null
    
    Add-MenuItem $viewMenu "Align icons to grid" $null { 
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
    Add-MenuItem $viewMenu "Show desktop icons" $null { $settings.ShowDesktopIcons = -not $settings.ShowDesktopIcons; Save-DesktopSettings; Refresh-Desktop } ($settings.ShowDesktopIcons) | Out-Null
    Add-MenuItem $viewMenu "Show Recycle Bin" $null { $settings.ShowRecycleBin = -not $settings.ShowRecycleBin; Save-DesktopSettings; Refresh-Desktop } ($settings.ShowRecycleBin) | Out-Null
    [void]$menu.Items.Add($viewMenu)

    # Sort By Submenu
    $sortMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Sort by")
    $sortMenu.ForeColor = [System.Drawing.Color]::White
    $sortMenu.DropDown.ShowImageMargin = $true; $sortMenu.DropDown.ShowCheckMargin = $false
    try { $sortMenu.DropDown.Renderer = New-Object DarkMenuRenderer } catch {}

    Add-MenuItem $sortMenu "Name" $null { $settings.SortBy = "Name"; $settings.Positions = @{}; Save-DesktopSettings; Refresh-Desktop } ($settings.SortBy -eq "Name") | Out-Null
    Add-MenuItem $sortMenu "Size" $null { $settings.SortBy = "Size"; $settings.Positions = @{}; Save-DesktopSettings; Refresh-Desktop } ($settings.SortBy -eq "Size") | Out-Null
    Add-MenuItem $sortMenu "Date modified" $null { $settings.SortBy = "Date"; $settings.Positions = @{}; Save-DesktopSettings; Refresh-Desktop } ($settings.SortBy -eq "Date") | Out-Null
    [void]$menu.Items.Add($sortMenu)

    Add-MenuItem $menu "Refresh" "F5" { Refresh-Desktop } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $menu "Paste" "Ctrl+V" { Paste-ClipboardFiles } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $newMenu = New-Object System.Windows.Forms.ToolStripMenuItem("New")
    $newMenu.ForeColor = [System.Drawing.Color]::White
    $newMenu.DropDown.ShowImageMargin = $false; $newMenu.DropDown.ShowCheckMargin = $false
    try { $newMenu.DropDown.Renderer = New-Object DarkMenuRenderer } catch {}

    Add-MenuItem $newMenu "Folder" "Ctrl+Shift+N" { New-DesktopFolder } | Out-Null
    Add-MenuItem $newMenu "Text Document" $null { New-DesktopTextFile } | Out-Null
    [void]$menu.Items.Add($newMenu)
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    Add-MenuItem $menu "Personalize" $null { Show-Settings } | Out-Null
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
        foreach ($item in $script:selectedItems) { 
            $path = [string]$item.Path; if (-not [string]::IsNullOrWhiteSpace($path)) { Open-DesktopItem $path }
        } 
    } | Out-Null
    Add-MenuItem $itemMenu "Edit" $null { 
        foreach ($item in $script:selectedItems) { 
            $path = [string]$item.Path; if (-not [string]::IsNullOrWhiteSpace($path) -and -not (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue).PSIsContainer) { try { Start-Process "notepad.exe" -ArgumentList "`"$path`"" -ErrorAction SilentlyContinue } catch { } }
        } 
    } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $itemMenu "Cut" "Ctrl+X" { Cut-SelectedFiles } | Out-Null
    Add-MenuItem $itemMenu "Copy" "Ctrl+C" { Copy-SelectedFiles } | Out-Null
    Add-MenuItem $itemMenu "Compress to ZIP file" $null {
        $real = @($script:selectedItems | Where-Object { $_.Path -ne "::{645FF040-5081-101B-9F08-00AA002F954E}" })
        if ($real.Count -eq 0) { return }
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
                Refresh-Desktop
            }
        } catch { }
    } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $itemMenu "Rename" "F2" { 
        if ($script:selectedItems.Count -eq 1) { 
            $p = [string]$script:selectedItems[0].Path; if (-not [string]::IsNullOrWhiteSpace($p)) { Rename-DesktopItem $p }
        }
    } | Out-Null
    Add-MenuItem $itemMenu "Delete" "Del" { Delete-DesktopItems } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    
    Add-MenuItem $itemMenu "Properties" "Alt+Enter" { 
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

    Add-MenuItem $rbMenu "Open" "Enter" { Open-DesktopItem "shell:RecycleBinFolder" } | Out-Null
    Add-MenuItem $rbMenu "Empty Recycle Bin" $null { 
        $owner = if ($null -ne $script:primaryForm) { $script:primaryForm.Handle } else { [IntPtr]::Zero }
        [CustomDesktopForm]::EmptyRecycleBin($owner)
        Refresh-Desktop
    } | Out-Null
    [void]$rbMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $rbMenu "Properties" "Alt+Enter" { Show-ItemProperties "::{645FF040-5081-101B-9F08-00AA002F954E}" } | Out-Null
    $script:recycleBinContextMenu = $rbMenu
}

# ============================================================
# 013 - REFRESH & RICH PERSONALIZATION SETTINGS UI (MODERN SCROLLBAR)
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
    if ($null -ne $script:settingsForm -and -not $script:settingsForm.IsDisposed) {
        $script:settingsForm.BringToFront(); return
    }

    $uiScale = 1.0; if ($null -ne $settings.UiScale) { $uiScale = [double]$settings.UiScale }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Personalization & Settings"
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.Width = [int](560 * $uiScale); $form.Height = [int](720 * $uiScale)
    $form.BackColor = $script:Colors.Background
    Enable-DoubleBuffer $form

    $form.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1e293b"), 1)
        try { $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1) } finally { $pen.Dispose() }
    })

    # Header Bar
    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = [System.Windows.Forms.DockStyle]::Top
    $header.Height = [int](65 * $uiScale)
    $header.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    
    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Personalization"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", [float](14 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::White
    $title.AutoSize = $true
    $title.Left = [int](20 * $uiScale); $title.Top = [int](18 * $uiScale)
    $header.Controls.Add($title)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "X"
    $closeBtn.Font = New-Object System.Drawing.Font("Segoe UI", [float](10 * $uiScale), [System.Drawing.FontStyle]::Bold)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeBtn.FlatAppearance.BorderSize = 0
    $closeBtn.Width = [int](40 * $uiScale); $closeBtn.Height = [int](40 * $uiScale)
    $closeBtn.Left = $form.Width - [int](50 * $uiScale); $closeBtn.Top = [int](12 * $uiScale)
    $closeBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $closeBtn.Add_Click({ $form.Close() })
    $header.Controls.Add($closeBtn)

    Enable-FormDragging $form @($header, $title)
    $form.Controls.Add($header)

    # Modern Outer Container Panel (Zero Win95 Scrollbars)
    $body = New-Object System.Windows.Forms.Panel
    $body.Dock = [System.Windows.Forms.DockStyle]::Fill
    $body.BackColor = $script:Colors.Background
    $body.AutoScroll = $false
    Enable-DoubleBuffer $body
    $form.Controls.Add($body)
    $body.BringToFront()

    # Inner Movable Content Panel
    $content = New-Object System.Windows.Forms.Panel
    $content.Left = 0; $content.Top = 0; $content.Width = $body.Width - [int](14 * $uiScale)
    $content.BackColor = $script:Colors.Background
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
    $script:currY = [int](15 * $uiScale)

    function Add-SettingsCard([string]$CardTitle, [int]$CardHeight) {
        $c = New-Object System.Windows.Forms.Panel
        $c.Left = [int](15 * $uiScale); $c.Top = $script:currY; $c.Width = $cardW; $c.Height = [int]($CardHeight * $uiScale)
        $c.BackColor = $script:Colors.Card
        Enable-DoubleBuffer $c
        $c.Add_Paint({
            param($s, $e)
            $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1f2937"), 1)
            try { $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1) } finally { $pen.Dispose() }
        })
        
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $CardTitle; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", [float](10 * $uiScale), [System.Drawing.FontStyle]::Bold)
        $lbl.ForeColor = [System.Drawing.Color]::White; $lbl.AutoSize = $true
        $lbl.Left = [int](15 * $uiScale); $lbl.Top = [int](12 * $uiScale)
        $c.Controls.Add($lbl)
        $content.Controls.Add($c)
        $script:currY += [int](($CardHeight + 15) * $uiScale)
        return $c
    }

    # Card 1: Background & Wallpaper Engine
    $cardBg = Add-SettingsCard "Desktop Background & Wallpaper" 295
    $rbColor = New-Object System.Windows.Forms.RadioButton; $rbColor.Text = "Solid Color"; $rbColor.Left = [int](15 * $uiScale); $rbColor.Top = [int](42 * $uiScale); $rbColor.AutoSize = $true; $rbColor.ForeColor = [System.Drawing.Color]::White
    $rbImage = New-Object System.Windows.Forms.RadioButton; $rbImage.Text = "Image / Wallpaper"; $rbImage.Left = [int](130 * $uiScale); $rbImage.Top = [int](42 * $uiScale); $rbImage.AutoSize = $true; $rbImage.ForeColor = [System.Drawing.Color]::White
    if ($settings.BackgroundType -eq "Image") { $rbImage.Checked = $true } else { $rbColor.Checked = $true }
    $cardBg.Controls.Add($rbColor); $cardBg.Controls.Add($rbImage)

    # Color swatches
    $swatches = @("#0b0f19", "#0f172a", "#18181b", "#1e1b4b", "#064e3b", "#4c0519", "#000000")
    $swatchX = [int](15 * $uiScale)
    foreach ($colHex in $swatches) {
        $sw = New-Object System.Windows.Forms.Panel
        $sw.Left = $swatchX; $sw.Top = [int](72 * $uiScale); $sw.Width = [int](26 * $uiScale); $sw.Height = [int](26 * $uiScale)
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
        $swatchX += [int](32 * $uiScale)
    }

    $colorBtn = New-Object System.Windows.Forms.Button
    $colorBtn.Text = "Pick Custom Color..."
    $colorBtn.Left = [int](15 * $uiScale); $colorBtn.Top = [int](110 * $uiScale); $colorBtn.Width = [int](170 * $uiScale); $colorBtn.Height = [int](32 * $uiScale)
    $colorBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $colorBtn.FlatAppearance.BorderSize = 0
    $colorBtn.BackColor = $script:Colors.InputBg; $colorBtn.ForeColor = [System.Drawing.Color]::White; $colorBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
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
    $browseBtn.Text = "Browse Wallpaper..."
    $browseBtn.Left = [int](200 * $uiScale); $browseBtn.Top = [int](110 * $uiScale); $browseBtn.Width = [int](160 * $uiScale); $browseBtn.Height = [int](32 * $uiScale)
    $browseBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $browseBtn.FlatAppearance.BorderSize = 0
    $browseBtn.BackColor = $script:Colors.InputBg; $browseBtn.ForeColor = [System.Drawing.Color]::White; $browseBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $browseBtn.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Image Files|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.jfif|All Files|*.*"
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
    $fitLbl = New-Object System.Windows.Forms.Label; $fitLbl.Text = "Image Fit Mode:"; $fitLbl.Left = [int](15 * $uiScale); $fitLbl.Top = [int](158 * $uiScale); $fitLbl.AutoSize = $true; $fitLbl.ForeColor = [System.Drawing.Color]::White
    $cardBg.Controls.Add($fitLbl)

    $fitCombo = New-Object System.Windows.Forms.ComboBox
    $fitCombo.Left = [int](130 * $uiScale); $fitCombo.Top = [int](153 * $uiScale); $fitCombo.Width = [int](140 * $uiScale)
    $fitCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $fitCombo.BackColor = $script:Colors.InputBg; $fitCombo.ForeColor = [System.Drawing.Color]::White
    [void]$fitCombo.Items.AddRange(@("Fill", "Fit", "Stretch", "Tile", "Center"))
    $fitCombo.SelectedItem = $settings.ImageMode
    $fitCombo.Add_SelectedIndexChanged({
        $settings.ImageMode = [string]$fitCombo.SelectedItem
        Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms
    })
    $cardBg.Controls.Add($fitCombo)

    # Wallpaper Dimming Slider & Presets
    $dimLbl = New-Object System.Windows.Forms.Label; $dimLbl.Text = "Wallpaper Dimming: $($settings.WallpaperDimming)%"; $dimLbl.Left = [int](15 * $uiScale); $dimLbl.Top = [int](198 * $uiScale); $dimLbl.AutoSize = $true; $dimLbl.ForeColor = [System.Drawing.Color]::White
    $cardBg.Controls.Add($dimLbl)

    $dimTrack = New-Object System.Windows.Forms.TrackBar
    $dimTrack.Minimum = 0; $dimTrack.Maximum = 80; $dimTrack.Value = [Math]::Max(0, [Math]::Min(80, [int]$settings.WallpaperDimming))
    $dimTrack.Left = [int](180 * $uiScale); $dimTrack.Top = [int](192 * $uiScale); $dimTrack.Width = [int](280 * $uiScale)
    $dimTrack.TickFrequency = 10
    $cardBg.Controls.Add($dimTrack)

    $dimTrack.Add_Scroll({
        $dimLbl.Text = "Wallpaper Dimming: $($dimTrack.Value)%"
        $settings.WallpaperDimming = $dimTrack.Value
        Save-DesktopSettings
        Apply-Background
        Invalidate-AllDesktopForms
    })

    $d0 = New-Object System.Windows.Forms.Button; $d0.Text = "None (0%)"; $d0.Left = [int](15 * $uiScale); $d0.Top = [int](242 * $uiScale); $d0.Width = [int](105 * $uiScale); $d0.Height = [int](26 * $uiScale); $d0.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d0.BackColor = $script:Colors.InputBg; $d0.ForeColor = [System.Drawing.Color]::White; $d0.FlatAppearance.BorderSize = 0; $d0.Cursor = [System.Windows.Forms.Cursors]::Hand
    $d20 = New-Object System.Windows.Forms.Button; $d20.Text = "Light (20%)"; $d20.Left = [int](130 * $uiScale); $d20.Top = [int](242 * $uiScale); $d20.Width = [int](105 * $uiScale); $d20.Height = [int](26 * $uiScale); $d20.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d20.BackColor = $script:Colors.InputBg; $d20.ForeColor = [System.Drawing.Color]::White; $d20.FlatAppearance.BorderSize = 0; $d20.Cursor = [System.Windows.Forms.Cursors]::Hand
    $d40 = New-Object System.Windows.Forms.Button; $d40.Text = "Medium (40%)"; $d40.Left = [int](245 * $uiScale); $d40.Top = [int](242 * $uiScale); $d40.Width = [int](105 * $uiScale); $d40.Height = [int](26 * $uiScale); $d40.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d40.BackColor = $script:Colors.InputBg; $d40.ForeColor = [System.Drawing.Color]::White; $d40.FlatAppearance.BorderSize = 0; $d40.Cursor = [System.Windows.Forms.Cursors]::Hand
    $d60 = New-Object System.Windows.Forms.Button; $d60.Text = "Dark (60%)"; $d60.Left = [int](360 * $uiScale); $d60.Top = [int](242 * $uiScale); $d60.Width = [int](110 * $uiScale); $d60.Height = [int](26 * $uiScale); $d60.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $d60.BackColor = $script:Colors.InputBg; $d60.ForeColor = [System.Drawing.Color]::White; $d60.FlatAppearance.BorderSize = 0; $d60.Cursor = [System.Windows.Forms.Cursors]::Hand

    $d0.Add_Click({ $dimTrack.Value = 0; $dimLbl.Text = "Wallpaper Dimming: 0%"; $settings.WallpaperDimming = 0; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })
    $d20.Add_Click({ $dimTrack.Value = 20; $dimLbl.Text = "Wallpaper Dimming: 20%"; $settings.WallpaperDimming = 20; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })
    $d40.Add_Click({ $dimTrack.Value = 40; $dimLbl.Text = "Wallpaper Dimming: 40%"; $settings.WallpaperDimming = 40; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })
    $d60.Add_Click({ $dimTrack.Value = 60; $dimLbl.Text = "Wallpaper Dimming: 60%"; $settings.WallpaperDimming = 60; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms })

    $cardBg.Controls.Add($d0); $cardBg.Controls.Add($d20); $cardBg.Controls.Add($d40); $cardBg.Controls.Add($d60)

    $rbColor.Add_CheckedChanged({ if ($rbColor.Checked) { $settings.BackgroundType = "Color"; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms } })
    $rbImage.Add_CheckedChanged({ if ($rbImage.Checked) { $settings.BackgroundType = "Image"; Save-DesktopSettings; Apply-Background; Invalidate-AllDesktopForms } })

    # Card 2: Desktop Path & Explorer
    $cardPath = Add-SettingsCard "Desktop Folder Location" 105
    $pathBox = New-Object System.Windows.Forms.TextBox
    $pathBox.Left = [int](15 * $uiScale); $pathBox.Top = [int](45 * $uiScale); $pathBox.Width = [int](340 * $uiScale); $pathBox.Height = [int](28 * $uiScale)
    $pathBox.BackColor = $script:Colors.InputBg; $pathBox.ForeColor = [System.Drawing.Color]::White; $pathBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pathBox.Text = $script:desktopPath
    $cardPath.Controls.Add($pathBox)

    $pathBtn = New-Object System.Windows.Forms.Button
    $pathBtn.Text = "Browse..."
    $pathBtn.Left = [int](365 * $uiScale); $pathBtn.Top = [int](45 * $uiScale); $pathBtn.Width = [int](115 * $uiScale); $pathBtn.Height = [int](28 * $uiScale)
    $pathBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $pathBtn.FlatAppearance.BorderSize = 0
    $pathBtn.BackColor = $script:Colors.InputBg; $pathBtn.ForeColor = [System.Drawing.Color]::White; $pathBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
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
    $cardScale = Add-SettingsCard "Independent Icon & UI Scaling" 255
    
    $iconLbl = New-Object System.Windows.Forms.Label; $iconLbl.Text = "Icon Size: $($settings.IconScale)px"; $iconLbl.Left = [int](15 * $uiScale); $iconLbl.Top = [int](38 * $uiScale); $iconLbl.AutoSize = $true; $iconLbl.ForeColor = [System.Drawing.Color]::White
    $cardScale.Controls.Add($iconLbl)

    $track = New-Object System.Windows.Forms.TrackBar
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

    $p1 = New-Object System.Windows.Forms.Button; $p1.Text = "Small (48px)"; $p1.Left = [int](15 * $uiScale); $p1.Top = [int](78 * $uiScale); $p1.Width = [int](105 * $uiScale); $p1.Height = [int](26 * $uiScale); $p1.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p1.BackColor = $script:Colors.InputBg; $p1.ForeColor = [System.Drawing.Color]::White; $p1.FlatAppearance.BorderSize = 0; $p1.Cursor = [System.Windows.Forms.Cursors]::Hand
    $p2 = New-Object System.Windows.Forms.Button; $p2.Text = "Medium (72px)"; $p2.Left = [int](130 * $uiScale); $p2.Top = [int](78 * $uiScale); $p2.Width = [int](105 * $uiScale); $p2.Height = [int](26 * $uiScale); $p2.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p2.BackColor = $script:Colors.InputBg; $p2.ForeColor = [System.Drawing.Color]::White; $p2.FlatAppearance.BorderSize = 0; $p2.Cursor = [System.Windows.Forms.Cursors]::Hand
    $p3 = New-Object System.Windows.Forms.Button; $p3.Text = "Large (96px)"; $p3.Left = [int](245 * $uiScale); $p3.Top = [int](78 * $uiScale); $p3.Width = [int](105 * $uiScale); $p3.Height = [int](26 * $uiScale); $p3.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p3.BackColor = $script:Colors.InputBg; $p3.ForeColor = [System.Drawing.Color]::White; $p3.FlatAppearance.BorderSize = 0; $p3.Cursor = [System.Windows.Forms.Cursors]::Hand
    $p4 = New-Object System.Windows.Forms.Button; $p4.Text = "X-Large (128px)"; $p4.Left = [int](360 * $uiScale); $p4.Top = [int](78 * $uiScale); $p4.Width = [int](110 * $uiScale); $p4.Height = [int](26 * $uiScale); $p4.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $p4.BackColor = $script:Colors.InputBg; $p4.ForeColor = [System.Drawing.Color]::White; $p4.FlatAppearance.BorderSize = 0; $p4.Cursor = [System.Windows.Forms.Cursors]::Hand

    $p1.Add_Click({ $track.Value = 48; $iconLbl.Text = "Icon Size: 48px"; $settings.IconScale = 48; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $p2.Add_Click({ $track.Value = 72; $iconLbl.Text = "Icon Size: 72px"; $settings.IconScale = 72; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $p3.Add_Click({ $track.Value = 96; $iconLbl.Text = "Icon Size: 96px"; $settings.IconScale = 96; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $p4.Add_Click({ $track.Value = 128; $iconLbl.Text = "Icon Size: 128px"; $settings.IconScale = 128; Clear-IconCache; Save-DesktopSettings; Refresh-Desktop })
    $cardScale.Controls.Add($p1); $cardScale.Controls.Add($p2); $cardScale.Controls.Add($p3); $cardScale.Controls.Add($p4)

    # 2. UI / Font / Spacing Scale Slider
    $uiPct = [int]([double]$settings.UiScale * 100)
    $uiLbl = New-Object System.Windows.Forms.Label; $uiLbl.Text = "UI & Font Scale: $uiPct%"; $uiLbl.Left = [int](15 * $uiScale); $uiLbl.Top = [int](130 * $uiScale); $uiLbl.AutoSize = $true; $uiLbl.ForeColor = [System.Drawing.Color]::White
    $cardScale.Controls.Add($uiLbl)

    $uiTrack = New-Object System.Windows.Forms.TrackBar
    $uiTrack.Minimum = 70; $uiTrack.Maximum = 180; $uiTrack.Value = [Math]::Max(70, [Math]::Min(180, $uiPct))
    $uiTrack.Left = [int](150 * $uiScale); $uiTrack.Top = [int](124 * $uiScale); $uiTrack.Width = [int](320 * $uiScale)
    $uiTrack.TickFrequency = 10
    $cardScale.Controls.Add($uiTrack)

    $uiTrack.Add_Scroll({
        $uiLbl.Text = "UI & Font Scale: $($uiTrack.Value)%"
        $settings.UiScale = [double]($uiTrack.Value / 100.0)
        Save-DesktopSettings; Refresh-Desktop
    })

    $u1 = New-Object System.Windows.Forms.Button; $u1.Text = "Compact (80%)"; $u1.Left = [int](15 * $uiScale); $u1.Top = [int](170 * $uiScale); $u1.Width = [int](105 * $uiScale); $u1.Height = [int](26 * $uiScale); $u1.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u1.BackColor = $script:Colors.InputBg; $u1.ForeColor = [System.Drawing.Color]::White; $u1.FlatAppearance.BorderSize = 0; $u1.Cursor = [System.Windows.Forms.Cursors]::Hand
    $u2 = New-Object System.Windows.Forms.Button; $u2.Text = "Standard (100%)"; $u2.Left = [int](130 * $uiScale); $u2.Top = [int](170 * $uiScale); $u2.Width = [int](105 * $uiScale); $u2.Height = [int](26 * $uiScale); $u2.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u2.BackColor = $script:Colors.InputBg; $u2.ForeColor = [System.Drawing.Color]::White; $u2.FlatAppearance.BorderSize = 0; $u2.Cursor = [System.Windows.Forms.Cursors]::Hand
    $u3 = New-Object System.Windows.Forms.Button; $u3.Text = "Spacious (125%)"; $u3.Left = [int](245 * $uiScale); $u3.Top = [int](170 * $uiScale); $u3.Width = [int](105 * $uiScale); $u3.Height = [int](26 * $uiScale); $u3.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u3.BackColor = $script:Colors.InputBg; $u3.ForeColor = [System.Drawing.Color]::White; $u3.FlatAppearance.BorderSize = 0; $u3.Cursor = [System.Windows.Forms.Cursors]::Hand
    $u4 = New-Object System.Windows.Forms.Button; $u4.Text = "Large (150%)"; $u4.Left = [int](360 * $uiScale); $u4.Top = [int](170 * $uiScale); $u4.Width = [int](110 * $uiScale); $u4.Height = [int](26 * $uiScale); $u4.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $u4.BackColor = $script:Colors.InputBg; $u4.ForeColor = [System.Drawing.Color]::White; $u4.FlatAppearance.BorderSize = 0; $u4.Cursor = [System.Windows.Forms.Cursors]::Hand

    $u1.Add_Click({ $uiTrack.Value = 80; $uiLbl.Text = "UI & Font Scale: 80%"; $settings.UiScale = 0.8; Save-DesktopSettings; Refresh-Desktop })
    $u2.Add_Click({ $uiTrack.Value = 100; $uiLbl.Text = "UI & Font Scale: 100%"; $settings.UiScale = 1.0; Save-DesktopSettings; Refresh-Desktop })
    $u3.Add_Click({ $uiTrack.Value = 125; $uiLbl.Text = "UI & Font Scale: 125%"; $settings.UiScale = 1.25; Save-DesktopSettings; Refresh-Desktop })
    $u4.Add_Click({ $uiTrack.Value = 150; $uiLbl.Text = "UI & Font Scale: 150%"; $settings.UiScale = 1.5; Save-DesktopSettings; Refresh-Desktop })
    $cardScale.Controls.Add($u1); $cardScale.Controls.Add($u2); $cardScale.Controls.Add($u3); $cardScale.Controls.Add($u4)

    # Card 4: Layout & Grid Behavior
    $cardLayout = Add-SettingsCard "Layout & Icon Arrangement" 145
    $chkAuto = New-Object System.Windows.Forms.CheckBox; $chkAuto.Text = "Auto Arrange Icons"; $chkAuto.Left = [int](15 * $uiScale); $chkAuto.Top = [int](45 * $uiScale); $chkAuto.AutoSize = $true; $chkAuto.Checked = [bool]$settings.AutoArrange; $chkAuto.ForeColor = [System.Drawing.Color]::White
    $chkGrid = New-Object System.Windows.Forms.CheckBox; $chkGrid.Text = "Align to Grid"; $chkGrid.Left = [int](180 * $uiScale); $chkGrid.Top = [int](45 * $uiScale); $chkGrid.AutoSize = $true; $chkGrid.Checked = [bool]$settings.AlignToGrid; $chkGrid.ForeColor = [System.Drawing.Color]::White
    $chkShow = New-Object System.Windows.Forms.CheckBox; $chkShow.Text = "Show Desktop Icons"; $chkShow.Left = [int](320 * $uiScale); $chkShow.Top = [int](45 * $uiScale); $chkShow.AutoSize = $true; $chkShow.Checked = [bool]$settings.ShowDesktopIcons; $chkShow.ForeColor = [System.Drawing.Color]::White
    
    $chkRecycle = New-Object System.Windows.Forms.CheckBox; $chkRecycle.Text = "Show Recycle Bin"; $chkRecycle.Left = [int](15 * $uiScale); $chkRecycle.Top = [int](80 * $uiScale); $chkRecycle.AutoSize = $true; $chkRecycle.Checked = [bool]$settings.ShowRecycleBin; $chkRecycle.ForeColor = [System.Drawing.Color]::White

    $chkAuto.Add_CheckedChanged({ $settings.AutoArrange = $chkAuto.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkGrid.Add_CheckedChanged({ $settings.AlignToGrid = $chkGrid.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkShow.Add_CheckedChanged({ $settings.ShowDesktopIcons = $chkShow.Checked; Save-DesktopSettings; Refresh-Desktop })
    $chkRecycle.Add_CheckedChanged({ $settings.ShowRecycleBin = $chkRecycle.Checked; Save-DesktopSettings; Refresh-Desktop })
    $cardLayout.Controls.Add($chkAuto); $cardLayout.Controls.Add($chkGrid); $cardLayout.Controls.Add($chkShow); $cardLayout.Controls.Add($chkRecycle)

    # Reset Defaults Button
    $resetBtn = New-Object System.Windows.Forms.Button
    $resetBtn.Text = "Reset All Settings to Defaults"
    $resetBtn.Left = [int](15 * $uiScale); $resetBtn.Top = $script:currY; $resetBtn.Width = $cardW; $resetBtn.Height = [int](38 * $uiScale)
    $resetBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $resetBtn.FlatAppearance.BorderSize = 0
    $resetBtn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
    $resetBtn.ForeColor = [System.Drawing.Color]::White; $resetBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $resetBtn.Add_Click({
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
    $form.Add_MouseWheel($wheelScroll)
    $body.Add_MouseWheel($wheelScroll)
    $content.Add_MouseWheel($wheelScroll)

    $script:settingsForm = $form
    [void]$form.ShowDialog()
    $form.Dispose()
    $script:settingsForm = $null
    [CustomDesktopForm]::ActivateDesktop()
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
                    Open-DesktopItem $clickedItem.Path
                    foreach ($p in $script:selectedItems) { if ($p.Path -ne $clickedItem.Path) { Open-DesktopItem $p.Path } }
                    Clear-Selection; return
                }
                $script:lastClickTime = $now; $script:lastClickPanel = $clickedItem
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                
                if ($isCtrl) {
                    if ($script:selectedItems -contains $clickedItem) { Remove-Selection $clickedItem; return }
                    else { Set-Selection $clickedItem }
                } else {
                    if ($script:selectedItems -notcontains $clickedItem) {
                        Clear-Selection; Set-Selection $clickedItem
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
            }
        } elseif ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            if ($null -ne $clickedItem) {
                if ($script:selectedItems -notcontains $clickedItem) { Clear-Selection; Set-Selection $clickedItem }
                if ($clickedItem.Path -eq "::{645FF040-5081-101B-9F08-00AA002F954E}") {
                    $script:recycleBinContextMenu.Show($sender, $e.Location)
                } else {
                    $script:itemContextMenu.Tag = $clickedItem.Path
                    $script:itemContextMenu.Show($sender, $e.Location)
                }
            } else {
                Clear-Selection
                $script:contextMenu.Show($sender, $e.Location)
            }
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
            if (-not $script:isDragging) { if ([Math]::Abs($dx) -gt 4 -or [Math]::Abs($dy) -gt 4) { $script:isDragging = $true } }
            if ($script:isDragging) {
                $script:dragDeltaX = $dx
                $script:dragDeltaY = $dy
                Invalidate-AllDesktopForms
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

# ============================================================
# 016 - MULTI-MONITOR FORM MANAGER (DYNAMIC HOT-PLUG SAFE)
# ============================================================

function Sync-MultiMonitorForms {
    $screens = [System.Windows.Forms.Screen]::AllScreens
    
    if ($screens.Count -eq $script:forms.Count) {
        $allMatched = $true
        for ($i = 0; $i -lt $screens.Count; $i++) {
            $s = $screens[$i]
            $f = $script:forms[$i]
            if ($null -eq $f -or $f.IsDisposed) { $allMatched = $false; break }
            if ($f.Left -ne $s.WorkingArea.Left -or $f.Top -ne $s.WorkingArea.Top -or $f.Width -ne $s.WorkingArea.Width -or $f.Height -ne $s.WorkingArea.Height) {
                $f.Left = $s.WorkingArea.Left; $f.Top = $s.WorkingArea.Top
                $f.Width = $s.WorkingArea.Width; $f.Height = $s.WorkingArea.Height
            }
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
}

$script:winDInterceptor = New-Object WinDInterceptor

# ============================================================
# 017 - KEYBOARD SHORTCUTS & NAVIGATION
# ============================================================

$script:keyDownHandler = {
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        if ($script:selectedItems.Count -gt 0) {
            Clear-Selection
            $e.Handled = $true; $e.SuppressKeyPress = $true; return
        }
        foreach ($closeForm in $script:forms) { if ($null -ne $closeForm -and -not $closeForm.IsDisposed) { $closeForm.Close() } }
        $script:appContext.ExitThread()
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F5) { Refresh-Desktop; $e.Handled = $true; $e.SuppressKeyPress = $true; return }
    
    $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
    $isAlt  = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Alt) -eq [System.Windows.Forms.Keys]::Alt)
    $isShift = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift) -eq [System.Windows.Forms.Keys]::Shift)
    
    # Ctrl+Shift+N: New Folder
    if ($isCtrl -and $isShift -and $e.KeyCode -eq [System.Windows.Forms.Keys]::N) {
        New-DesktopFolder
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    # Ctrl+A: Select All
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::A) {
        $script:selectedItems = @($script:desktopItems)
        foreach ($item in $script:desktopItems) { if ($null -ne $item) { $item.Selected = $true } }
        Invalidate-AllDesktopForms
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # Ctrl+X: Cut
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::X) { Cut-SelectedFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return }

    # Ctrl+C: Copy
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::C) { Copy-SelectedFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return }

    # Ctrl+V: Paste
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::V) { Paste-ClipboardFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return }

    # Alt+Enter: Properties
    if ($isAlt -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        if ($script:selectedItems.Count -gt 0) {
            $p = [string]$script:selectedItems[0].Path
            if (-not [string]::IsNullOrWhiteSpace($p)) { Show-ItemProperties $p }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # Enter: Open selected items
    if (-not $isAlt -and -not $isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        foreach ($item in $script:selectedItems) {
            $path = [string]$item.Path
            if (-not [string]::IsNullOrWhiteSpace($path)) { Open-DesktopItem $path }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    
    # F2: Rename
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F2) {
        if ($script:selectedItems.Count -eq 1) { 
            $path = [string]$script:selectedItems[0].Path; if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) { Rename-DesktopItem $path }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    # Delete / Shift+Delete
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Delete) {
        if ($script:selectedItems.Count -gt 0) { Delete-DesktopItems }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }

    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::PageUp) {
        $settings.IconScale = [Math]::Min(160, [int]$settings.IconScale + 8)
        Clear-IconCache; Save-DesktopSettings; Refresh-Desktop
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::PageDown) {
        $settings.IconScale = [Math]::Max(32, [int]$settings.IconScale - 8)
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

        $script:fsw.Add_Created({ $script:refreshPending = $true })
        $script:fsw.Add_Deleted({ $script:refreshPending = $true })
        $script:fsw.Add_Renamed({ $script:refreshPending = $true })
        $script:fsw.Add_Changed({ $script:refreshPending = $true })
    } catch {}
}

$script:refreshTimer.Add_Tick({
    try {
        Sync-MultiMonitorForms
    } catch {}

    if ($script:refreshPending -and -not $script:isDragging -and -not $script:isLassoing -and -not $script:isPasting) {
        $script:refreshPending = $false
        Refresh-Desktop
    }
})

# ============================================================
# 019 - INITIALIZATION & WINFORMS LOOP
# ============================================================

Sync-MultiMonitorForms
Create-ContextMenus
Apply-Background
Build-DesktopIcons
Init-FileSystemWatcher
$script:refreshTimer.Start()

[CustomDesktopForm]::ActivateDesktop()

# WinForms Message Pump (Safe ApplicationContext Loop)
try { [System.Windows.Forms.Application]::Run($script:appContext) } catch { }

# Cleanup
try { Save-AllPositions; Save-DesktopSettings; Dispose-DesktopControls } catch { }
if ($script:winDInterceptor) { try { $script:winDInterceptor.Dispose() } catch {} }
if ($script:refreshTimer) { try { $script:refreshTimer.Stop(); $script:refreshTimer.Dispose() } catch {} }
if ($script:fsw) { try { $script:fsw.Dispose() } catch {} }
if ($script:backgroundImage) { try { $script:backgroundImage.Dispose() } catch { } }
foreach ($form in $script:forms) { if ($null -ne $form -and -not $form.IsDisposed) { try { $form.Dispose() } catch { } } }
Clear-IconCache
if ($script:contextMenu) { try { $script:contextMenu.Dispose() } catch { } }
if ($script:itemContextMenu) { try { $script:itemContextMenu.Dispose() } catch { } }
if ($script:recycleBinContextMenu) { try { $script:recycleBinContextMenu.Dispose() } catch { } }

# Self-delete temporary payload file
try {
    $currentScript = $MyInvocation.MyCommand.Definition
    if ($currentScript -and (Test-Path -LiteralPath $currentScript)) {
        Remove-Item -LiteralPath $currentScript -Force -ErrorAction SilentlyContinue
    }
} catch { }

[System.Environment]::Exit(0)
