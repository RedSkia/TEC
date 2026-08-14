@echo off
setlocal EnableExtensions
chcp 65001 >nul

rem ============================================================
rem 001 - CMD BOOTSTRAP
rem ============================================================

set "EMULATED_CMD=%~f0"
set "PSFILE=%TEMP%\EmulatedDesktop_%RANDOM%_%RANDOM%.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
 "$a=Get-Content -LiteralPath $env:EMULATED_CMD;" ^
 "$i=[Array]::IndexOf($a,'#=== POWERSHELL START ===');" ^
 "if($i -lt 0){Write-Host 'ERROR: PowerShell marker not found';exit 1};" ^
 "$a[($i+1)..($a.Length-1)] | Set-Content -LiteralPath $env:PSFILE -Encoding UTF8"

if not exist "%PSFILE%" (
    echo.
    echo ERROR: Could not create PowerShell payload.
    pause
    exit /b 1
)

powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"
set "EXITCODE=%ERRORLEVEL%"

del "%PSFILE%" >nul 2>&1

if not "%EXITCODE%"=="0" (
    echo.
    echo ============================================
    echo Emulated Desktop stopped with error %EXITCODE%
    echo ============================================
    pause
)

exit /b %EXITCODE%


#=== POWERSHELL START ===

# ============================================================
# 002 - ASSEMBLIES & VISUAL STYLES
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# 003 - SETTINGS DIRECTORY
# ============================================================

$settingsDirectory = Join-Path $env:LOCALAPPDATA "EmulatedDesktop"
$settingsFile = Join-Path $settingsDirectory "settings.json"

if (-not (Test-Path -LiteralPath $settingsDirectory)) {
    New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
}

$defaultSettings = [ordered]@{
    BackgroundType  = "Color"
    BackgroundColor = "#0b0f19"
    ImagePath       = ""
    ImageMode       = "Fill"
    IconScale       = 72
    SortBy          = "Name"
    DesktopPath     = Join-Path $env:USERPROFILE "Desktop"
    Positions       = @{}
}

$settings = [ordered]@{
    BackgroundType  = "Color"
    BackgroundColor = "#0b0f19"
    ImagePath       = ""
    ImageMode       = "Fill"
    IconScale       = 72
    SortBy          = "Name"
    DesktopPath     = Join-Path $env:USERPROFILE "Desktop"
    Positions       = @{}
}

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
            if ($null -ne $loaded.IconScale) {
                try { $settings.IconScale = [int]$loaded.IconScale } catch { $settings.IconScale = 72 }
            }
            if ($null -ne $loaded.SortBy) { $settings.SortBy = [string]$loaded.SortBy }
            if ($null -ne $loaded.DesktopPath) { $settings.DesktopPath = [string]$loaded.DesktopPath }
            if ($null -ne $loaded.Positions) {
                foreach ($p in $loaded.Positions.PSObject.Properties) {
                    try { $settings.Positions[$p.Name] = @{ X = [int]$p.Value.X; Y = [int]$p.Value.Y } } catch { }
                }
            }
        }
    } catch { $settings.Positions = @{} }
}

$settings.IconScale = [Math]::Max(48, [Math]::Min(160, [int]$settings.IconScale))
if ([string]::IsNullOrWhiteSpace($settings.SortBy)) { $settings.SortBy = "Name" }
if ([string]::IsNullOrWhiteSpace($settings.BackgroundColor)) { $settings.BackgroundColor = "#0b0f19" }
if ([string]::IsNullOrWhiteSpace($settings.BackgroundType)) { $settings.BackgroundType = "Color" }
if ([string]::IsNullOrWhiteSpace($settings.ImageMode)) { $settings.ImageMode = "Fill" }
if ([string]::IsNullOrWhiteSpace($settings.DesktopPath)) { $settings.DesktopPath = Join-Path $env:USERPROFILE "Desktop" }
try { $settings.DesktopPath = [Environment]::ExpandEnvironmentVariables($settings.DesktopPath) } catch { }

# ============================================================
# 005 - GLOBAL STATE VARIABLES
# ============================================================

$script:forms = @()
$script:primaryForm = $null
$script:settingsForm = $null
$script:backgroundImage = $null
$script:contextMenu = $null
$script:itemContextMenu = $null

$script:desktopItems = @()
$script:hoverItem = $null
$script:desktopFont = $null

$script:dragPanel = $null
$script:dragStartScreen = [System.Drawing.Point]::Empty
$script:dragDeltaX = 0
$script:dragDeltaY = 0
$script:isDragging = $false

$script:setDragStart = [System.Drawing.Point]::Empty
$script:setDragging = $false
$script:dragOriginalPositions = @{}

$script:selectedItems = @()
$script:refreshing = $false

$script:lassoStart = [System.Drawing.Point]::Empty
$script:lassoRect = [System.Drawing.Rectangle]::Empty
$script:isLassoing = $false

$script:lastClickTime = 0
$script:lastClickPanel = $null

$script:cellWidth = 115
$script:cellHeight = 125

$script:fsw = $null
$script:refreshPending = $false
$script:refreshTimer = New-Object System.Windows.Forms.Timer
$script:refreshTimer.Interval = 500

# ============================================================
# 006 - COLORS & THEME
# ============================================================

$script:Colors = @{
    Background  = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    PanelHover  = [System.Drawing.Color]::FromArgb(25, 255, 255, 255)
    Selected    = [System.Drawing.Color]::FromArgb(50, 59, 130, 246)
    Button      = [System.Drawing.ColorTranslator]::FromHtml("#1f2937")
    Text        = [System.Drawing.ColorTranslator]::FromHtml("#f8fafc")
    Muted       = [System.Drawing.ColorTranslator]::FromHtml("#94a3b8")
    Accent      = [System.Drawing.ColorTranslator]::FromHtml("#3b82f6")
    Danger      = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
}

function Clear-Selection {
    foreach ($i in $script:selectedItems) { $i.Selected = $false }
    $script:selectedItems = @()
    if ($null -ne $script:primaryForm) { $script:primaryForm.Invalidate() }
}

function Set-Selection {
    param($Item)
    if ($null -eq $Item) { return }
    if ($script:selectedItems -notcontains $Item) {
        $Item.Selected = $true
        $script:selectedItems += $Item
        if ($null -ne $script:primaryForm) { $script:primaryForm.Invalidate() }
    }
}

function Remove-Selection {
    param($Item)
    if ($null -eq $Item) { return }
    if ($script:selectedItems -contains $Item) {
        $Item.Selected = $false
        $script:selectedItems = @($script:selectedItems | Where-Object { $_ -ne $Item })
        if ($null -ne $script:primaryForm) { $script:primaryForm.Invalidate() }
    }
}

function Get-ColorFromHex {
    param([string]$Hex)
    try {
        if ([string]::IsNullOrWhiteSpace($Hex)) { return $script:Colors.Background }
        return [System.Drawing.ColorTranslator]::FromHtml($Hex)
    } catch { return $script:Colors.Background }
}

function Enable-DoubleBuffer {
    param([System.Windows.Forms.Control]$Control)
    if ($null -eq $Control) { return }
    try {
        $prop = $Control.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($null -ne $prop) { $prop.SetValue($Control, $true, $null) }
    } catch { }
}

# ============================================================
# 007 - DESKTOP PATH VALIDATION
# ============================================================

$desktopPath = [string]$settings.DesktopPath
if (-not (Test-Path -LiteralPath $desktopPath)) {
    $fallback = Join-Path $env:USERPROFILE "Desktop"
    if (Test-Path -LiteralPath $fallback) { $desktopPath = $fallback; $settings.DesktopPath = $fallback }
}
$script:desktopPath = $desktopPath

# ============================================================
# 008 - SAVE SETTINGS
# ============================================================

function Save-DesktopSettings {
    try {
        $object = [ordered]@{
            BackgroundType  = [string]$settings.BackgroundType
            BackgroundColor = [string]$settings.BackgroundColor
            ImagePath       = [string]$settings.ImagePath
            ImageMode       = [string]$settings.ImageMode
            IconScale       = [int]$settings.IconScale
            SortBy          = [string]$settings.SortBy
            DesktopPath     = [string]$settings.DesktopPath
            Positions       = $settings.Positions
        }
        $json = $object | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($settingsFile, $json, [System.Text.UTF8Encoding]::new($false))
    } catch { }
}

# ============================================================
# 009 - BACKGROUND IMAGE & PAINTING
# ============================================================

function Load-BackgroundImage {
    if ($script:backgroundImage) { try { $script:backgroundImage.Dispose() } catch { }; $script:backgroundImage = $null }
    if ($settings.BackgroundType -ne "Image" -or [string]::IsNullOrWhiteSpace($settings.ImagePath) -or -not (Test-Path -LiteralPath $settings.ImagePath)) { return }
    try {
        $source = [System.Drawing.Image]::FromFile($settings.ImagePath)
        $script:backgroundImage = New-Object System.Drawing.Bitmap($source)
        $source.Dispose()
    } catch { $script:backgroundImage = $null }
}

function Apply-Background {
    foreach ($form in $script:forms) {
        if ($null -eq $form -or $form.IsDisposed -or $form.ClientSize.Width -le 0 -or $form.ClientSize.Height -le 0) { continue }
        
        try {
            $bmp = New-Object System.Drawing.Bitmap($form.ClientSize.Width, $form.ClientSize.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            
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
                } catch { }
            }
        }
            $g.Dispose()
            
            $oldImage = $form.BackgroundImage
            $form.BackgroundImage = $bmp
            if ($null -ne $oldImage) { $oldImage.Dispose() }
        } catch { }
    }
}

function Paint-DesktopBackground {
    param([System.Windows.Forms.PaintEventArgs]$Event)
    if ($null -eq $Event -or $null -eq $script:desktopFont) { return }

    try {
        $g = $Event.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

        # 1. Draw Lasso Selection
        if ($script:isLassoing -and $script:lassoRect.Width -gt 0 -and $script:lassoRect.Height -gt 0) {
            $fillBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 59, 130, 246))
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 59, 130, 246), 1)
            try {
                $g.FillRectangle($fillBrush, $script:lassoRect)
                $g.DrawRectangle($pen, $script:lassoRect)
            } finally { $fillBrush.Dispose(); $pen.Dispose() }
        }

        $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
        $cWidth = [int]$script:cellWidth; $cHeight = [int]$script:cellHeight

        # 2. Draw OCD Grid (if dragging with CTRL)
        if ($script:isDragging -and $isCtrl -and $cWidth -gt 0 -and $cHeight -gt 0) {
            $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1)
            $gridPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $w = [int]$script:primaryForm.ClientSize.Width
            $h = [int]$script:primaryForm.ClientSize.Height
            for ($x = 14; $x -lt $w; $x += $cWidth) { $g.DrawLine($gridPen, $x, 0, $x, $h) }
            for ($y = 14; $y -lt $h; $y += $cHeight) { $g.DrawLine($gridPen, 0, $y, $w, $y) }
            $gridPen.Dispose()
            
            $slotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 59, 130, 246))
            foreach ($item in $script:selectedItems) {
                $orig = $script:dragOriginalPositions[$item.Path]; if ($null -eq $orig) { continue }
                $nx = [int]$orig.X + [int]$script:dragDeltaX; $ny = [int]$orig.Y + [int]$script:dragDeltaY
                $col = [int][Math]::Round(($nx - 14) / [double]$cWidth); $row = [int][Math]::Round(($ny - 14) / [double]$cHeight)
                $slotX = 14 + ($col * $cWidth); $slotY = 14 + ($row * $cHeight)
                
                $slotRect = New-Object System.Drawing.Rectangle($slotX, $slotY, $cWidth, $cHeight)
                $g.FillRectangle($slotBrush, $slotRect)
            }
            $slotBrush.Dispose()
        }

        # 3. Draw Desktop Items (Direct rendering - No Panels!)
        $hoverBrush = $null; $selBrush = $null; $textBrush = $null; $sf = $null
        try {
            $hoverBrush = New-Object System.Drawing.SolidBrush($script:Colors.PanelHover)
            $selBrush = New-Object System.Drawing.SolidBrush($script:Colors.Selected)
            $textBrush = New-Object System.Drawing.SolidBrush($script:Colors.Text)
            $sf = New-Object System.Drawing.StringFormat
            $sf.Alignment = [System.Drawing.StringAlignment]::Center
            $sf.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
            $sf.FormatFlags = [System.Drawing.StringFormatFlags]::LineLimit
            $iconSize = [int]$settings.IconScale
            $labelHeight = [int]($script:desktopFont.Size * 4.5)

            foreach ($item in $script:desktopItems) {
                if ($script:isDragging -and $item.Selected) { continue }
                
                if ($item.Selected) { $g.FillRectangle($selBrush, $item.Bounds) }
                elseif ($item -eq $script:hoverItem) { $g.FillRectangle($hoverBrush, $item.Bounds) }
                
                $iBoundsW = [int]$item.Bounds.Width; $iBoundsX = [int]$item.Bounds.X; $iBoundsY = [int]$item.Bounds.Y
                if ($null -ne $item.Icon) {
                    $ix = $iBoundsX + [int](($iBoundsW - $iconSize) / 2)
                    $iy = $iBoundsY + 6
                    $g.DrawImage($item.Icon, $ix, $iy, $iconSize, $iconSize)
                }
                
                $tx = $iBoundsX + 2; $ty = $iBoundsY + $iconSize + 10
                $tRect = New-Object System.Drawing.RectangleF([float]$tx, [float]$ty, [float]($iBoundsW - 4), [float]$labelHeight)
                $g.DrawString($item.Name, $script:desktopFont, $textBrush, $tRect, $sf)
            }

            # 4. Draw Drag Ghosts
            if ($script:isDragging -and $script:selectedItems.Count -gt 0) {
                $colorMatrix = $null; $imageAttrs = $null; $ghostTextBrush = $null
                try {
                    $colorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
                    $colorMatrix.Matrix33 = 0.7
                    $imageAttrs = New-Object System.Drawing.Imaging.ImageAttributes
                    $imageAttrs.SetColorMatrix($colorMatrix)
                    $ghostTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
                    
                    foreach ($item in $script:selectedItems) {
                        $orig = $script:dragOriginalPositions[$item.Path]
                        if ($null -eq $orig) { continue }
                        
                        $nx = [int]$orig.X + [int]$script:dragDeltaX; $ny = [int]$orig.Y + [int]$script:dragDeltaY
                        $iBoundsW = [int]$item.Bounds.Width
                        
                        if ($isCtrl -and $cWidth -gt 0 -and $cHeight -gt 0) {
                            $col = [int][Math]::Round(($nx - 14) / [double]$cWidth); $row = [int][Math]::Round(($ny - 14) / [double]$cHeight)
                            $nx = 14 + ($col * $cWidth); $ny = 14 + ($row * $cHeight)
                        }
                        
                        if ($null -ne $item.Icon) {
                            $ix = $nx + [int](($iBoundsW - $iconSize) / 2)
                            $iy = $ny + 6
                            $rect = New-Object System.Drawing.Rectangle($ix, $iy, $iconSize, $iconSize)
                            $g.DrawImage($item.Icon, $rect, 0, 0, [int]$item.Icon.Width, [int]$item.Icon.Height, [System.Drawing.GraphicsUnit]::Pixel, $imageAttrs)
                        }
                        
                        $tx = $nx + 2; $ty = $ny + $iconSize + 10
                        $tRect = New-Object System.Drawing.RectangleF([float]$tx, [float]$ty, [float]($iBoundsW - 4), [float]$labelHeight)
                        $g.DrawString($item.Name, $script:desktopFont, $ghostTextBrush, $tRect, $sf)
                    }
                } finally { if ($null -ne $imageAttrs) { $imageAttrs.Dispose() }; if ($null -ne $ghostTextBrush) { $ghostTextBrush.Dispose() } }
            }
        } finally { if ($null -ne $hoverBrush) { $hoverBrush.Dispose() }; if ($null -ne $selBrush) { $selBrush.Dispose() }; if ($null -ne $textBrush) { $textBrush.Dispose() }; if ($null -ne $sf) { $sf.Dispose() } }
    } catch { }
}

# ============================================================
# 010 - WINDOWS ICON ENGINE (JUMBO)
# ============================================================

Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public static class ShellIcons
{
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

    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SHGetFileInfo(string pszPath, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbSizeFileInfo, uint uFlags);
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool DestroyIcon(IntPtr hIcon);
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern bool SHObjectProperties(IntPtr hwnd, int shopObjectType, string pszObjectName, string pszPropertyPage);
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
                    IntPtr hIcon = IntPtr.Zero;
                    iml.GetIcon(shinfo.iIcon, ILD_TRANSPARENT, ref hIcon);
                    if (hIcon != IntPtr.Zero) {
                        try { 
                            using (Icon icon = Icon.FromHandle(hIcon)) {
                                Bitmap tmp = icon.ToBitmap();
                                Bitmap finalBmp = new Bitmap(tmp);
                                tmp.Dispose();
                                return finalBmp;
                            } 
                        }
                        finally { DestroyIcon(hIcon); }
                    }
                }
            }
        } catch { }
        return null;
    }
}
public class DarkColorTable : System.Windows.Forms.ProfessionalColorTable {
    public override System.Drawing.Color MenuItemSelected { get { return System.Drawing.ColorTranslator.FromHtml("#334155"); } }
    public override System.Drawing.Color MenuItemBorder { get { return System.Drawing.Color.Transparent; } }
    public override System.Drawing.Color ToolStripDropDownBackground { get { return System.Drawing.ColorTranslator.FromHtml("#0f172a"); } }
    public override System.Drawing.Color ImageMarginGradientBegin { get { return System.Drawing.ColorTranslator.FromHtml("#0f172a"); } }
    public override System.Drawing.Color ImageMarginGradientMiddle { get { return System.Drawing.ColorTranslator.FromHtml("#0f172a"); } }
    public override System.Drawing.Color ImageMarginGradientEnd { get { return System.Drawing.ColorTranslator.FromHtml("#0f172a"); } }
    public override System.Drawing.Color MenuBorder { get { return System.Drawing.ColorTranslator.FromHtml("#334155"); } }
    public override System.Drawing.Color SeparatorDark { get { return System.Drawing.ColorTranslator.FromHtml("#334155"); } }
    public override System.Drawing.Color SeparatorLight { get { return System.Drawing.Color.Transparent; } }
}
public class DarkMenuRenderer : System.Windows.Forms.ToolStripProfessionalRenderer {
    public DarkMenuRenderer() : base(new DarkColorTable()) { }
}
'@ -ReferencedAssemblies @("System.Drawing", "System.Windows.Forms")

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
    return $scaled
}

# ============================================================
# 011 - DESKTOP INTERACTION ACTIONS
# ============================================================

function Dispose-DesktopControls {
    foreach ($item in $script:desktopItems) { if ($null -ne $item.Icon) { try { $item.Icon.Dispose() } catch {} } }
    $script:desktopItems = @()
    if ($null -ne $script:desktopFont) { try { $script:desktopFont.Dispose() } catch {}; $script:desktopFont = $null }
}

function Open-DesktopItem {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Path
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        try { Invoke-Item -LiteralPath $Path -ErrorAction SilentlyContinue } catch { }
    }
}

function Get-SavedPosition {
    param([string]$Path)
    if ($settings.Positions.ContainsKey($Path)) { try { return New-Object System.Drawing.Point([int]$settings.Positions[$Path].X, [int]$settings.Positions[$Path].Y) } catch { } }
    return $null
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

function Change-IconScale {
    param([int]$Delta)
    $newSize = [int]$settings.IconScale + $Delta
    $newSize = [Math]::Max(48, [Math]::Min(256, $newSize))
    if ($newSize -eq $settings.IconScale) { return }
    Save-AllPositions; $settings.IconScale = $newSize; Save-DesktopSettings; Refresh-Desktop
}

function Rename-DesktopItem {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
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
            $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1); $pen.Dispose()
        })

        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Rename Item"; $label.Left = 20; $label.Top = 20; $label.AutoSize = $true
        $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $label.ForeColor = $script:Colors.Text
        $dialog.Controls.Add($label)

        $box = New-Object System.Windows.Forms.TextBox
        $box.Left = 20; $box.Top = 60; $box.Width = 410; $box.Height = 28
        $box.Font = New-Object System.Drawing.Font("Segoe UI", 11); $box.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272a"); $box.ForeColor = $script:Colors.Text
        $box.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $box.Text = $item.Name
        $dialog.Controls.Add($box)

        $ok = New-Object System.Windows.Forms.Button
        $ok.Text = "Save"; $ok.Left = 220; $ok.Top = 120; $ok.Width = 100; $ok.Height = 35
        $ok.BackColor = $script:Colors.Accent; $ok.ForeColor = $script:Colors.Text; $ok.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $ok.FlatAppearance.BorderSize = 0
        $ok.Cursor = [System.Windows.Forms.Cursors]::Hand
        $ok.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563eb") }); $ok.Add_MouseLeave({ $this.BackColor = $script:Colors.Accent })
        $dialog.Controls.Add($ok)
        
        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = "Cancel"; $cancel.Left = 330; $cancel.Top = 120; $cancel.Width = 100; $cancel.Height = 35
        $cancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3f3f46"); $cancel.ForeColor = $script:Colors.Text; $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $cancel.FlatAppearance.BorderSize = 0
        $cancel.Cursor = [System.Windows.Forms.Cursors]::Hand
        $cancel.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#52525b") }); $cancel.Add_MouseLeave({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3f3f46") })
        $dialog.Controls.Add($cancel)

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
                # FileSystemWatcher will trigger the refresh automatically
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
    if ($script:selectedItems.Count -eq 0) { return }
    try {
        $count = $script:selectedItems.Count
        $msg = if ($count -eq 1) { "Move this item to the Recycle Bin?" } else { "Move these $count items to the Recycle Bin?" }
        $result = [System.Windows.Forms.MessageBox]::Show($msg, "Delete", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        
        $shell = New-Object -ComObject Shell.Application
        foreach ($item in $script:selectedItems) {
            $path = [string]$item.Path
            if (-not (Test-Path -LiteralPath $path)) { continue }
            $folder = $shell.Namespace((Split-Path -Parent $path)); $shellItem = $folder.ParseName((Split-Path -Leaf $path))
            if ($null -ne $shellItem) { $shellItem.InvokeVerb("delete") }
            if ($settings.Positions.ContainsKey($path)) { $settings.Positions.Remove($path) }
        }
        Save-DesktopSettings; Clear-Selection
    } catch { }
}

function Show-ItemProperties {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    try {
        $hwnd = if ($null -ne $script:primaryForm) { $script:primaryForm.Handle } else { [IntPtr]::Zero }
        [ShellIcons]::SHObjectProperties($hwnd, 2, $Path, $null) | Out-Null
    } catch { }
}

function New-DesktopFolder {
    try {
        $number = 0
        do { if ($number -eq 0) { $name = "New Folder" } else { $name = "New Folder ($number)" }; $path = Join-Path $script:desktopPath $name; $number++ } while (Test-Path -LiteralPath $path)
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    } catch { }
}

function New-DesktopTextFile {
    try {
        $number = 0
        do { if ($number -eq 0) { $name = "New Text Document.txt" } else { $name = "New Text Document ($number).txt" }; $path = Join-Path $script:desktopPath $name; $number++ } while (Test-Path -LiteralPath $path)
        [System.IO.File]::WriteAllText($path, "")
    } catch { }
}

# ============================================================
# 012 - CONTEXT MENUS
# ============================================================

function Create-ContextMenus {
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    $menu.ForeColor = $script:Colors.Text
    $menu.ShowImageMargin = $false; $menu.ShowCheckMargin = $false
    $menu.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    try { $menu.Renderer = New-Object DarkMenuRenderer } catch { }

    function Add-MenuItem($M, $Txt, $Key, $Act) {
        $i = if ($M -is [System.Windows.Forms.ToolStripMenuItem]) { $M.DropDownItems.Add($Txt) } else { $M.Items.Add($Txt) }
        if ($null -ne $Key) { $i.ShortcutKeyDisplayString = $Key; $i.ShowShortcutKeys = $true }
        if ($null -ne $Act) { $i.Add_Click($Act) }
        return $i
    }

    $sortMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Sort by")
    Add-MenuItem $sortMenu "Name" $null { $settings.SortBy = "Name"; $settings.Positions = @{}; Save-DesktopSettings; Refresh-Desktop } | Out-Null
    Add-MenuItem $sortMenu "Size" $null { $settings.SortBy = "Size"; $settings.Positions = @{}; Save-DesktopSettings; Refresh-Desktop } | Out-Null
    Add-MenuItem $sortMenu "Date modified" $null { $settings.SortBy = "Date"; $settings.Positions = @{}; Save-DesktopSettings; Refresh-Desktop } | Out-Null
    [void]$menu.Items.Add($sortMenu)

    Add-MenuItem $menu "Refresh" "F5" { Refresh-Desktop } | Out-Null
    Add-MenuItem $menu "Snap to Grid (Auto Arrange)" $null { 
        $occupied = @{}
        $rows = [Math]::Max(1, [int][Math]::Floor(($script:primaryForm.ClientSize.Height - 14) / $script:cellHeight))
        foreach ($item in $script:desktopItems) {
            if ($null -eq $item) { continue }
            $col = [int][Math]::Max(0, [Math]::Round(($item.Bounds.X - 14) / [double]$script:cellWidth))
            $row = [int][Math]::Max(0, [Math]::Round(($item.Bounds.Y - 14) / [double]$script:cellHeight))
            
            while ($occupied.ContainsKey("$col,$row")) {
                $row++
                if ($row -ge $rows) { $row = 0; $col++ }
            }
            $occupied["$col,$row"] = $true
            
            $nx = 14 + ($col * $script:cellWidth); $ny = 14 + ($row * $script:cellHeight)
            Save-ItemPosition -Path $item.Path -X $nx -Y $ny -NoSave
        }
        Save-DesktopSettings; Refresh-Desktop 
    } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $menu "New Folder" $null { New-DesktopFolder } | Out-Null
    Add-MenuItem $menu "New Text Document" $null { New-DesktopTextFile } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $menu "Paste" "Ctrl+V" { Paste-ClipboardFiles } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $menu "Increase Icon Size" "PgUp" { Change-IconScale 8 } | Out-Null
    Add-MenuItem $menu "Decrease Icon Size" "PgDn" { Change-IconScale -8 } | Out-Null
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $menu "Personalize" $null { Show-Settings } | Out-Null
    $script:contextMenu = $menu

    $itemMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $itemMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0f172a")
    $itemMenu.ForeColor = $script:Colors.Text
    $itemMenu.ShowImageMargin = $false; $itemMenu.ShowCheckMargin = $false
    $itemMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    try { $itemMenu.Renderer = New-Object DarkMenuRenderer } catch { }

    Add-MenuItem $itemMenu "Open" $null { 
        foreach ($item in $script:selectedItems) { 
            $path = [string]$item.Path; if (-not [string]::IsNullOrWhiteSpace($path)) { Open-DesktopItem $path }
        } 
    } | Out-Null
    Add-MenuItem $itemMenu "Edit" $null { 
        foreach ($item in $script:selectedItems) { 
            $path = [string]$item.Path; if (-not [string]::IsNullOrWhiteSpace($path) -and -not (Get-Item -LiteralPath $path).PSIsContainer) { try { Start-Process "notepad.exe" -ArgumentList "`"$path`"" -ErrorAction SilentlyContinue } catch { } }
        } 
    } | Out-Null
    [void]$itemMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    Add-MenuItem $itemMenu "Copy" "Ctrl+C" { Copy-SelectedFiles } | Out-Null
    Add-MenuItem $itemMenu "Compress to ZIP file" $null {
        if ($script:selectedItems.Count -eq 0) { return }
        try {
            $paths = @()
            foreach ($item in $script:selectedItems) {
                if (-not [string]::IsNullOrWhiteSpace($item.Path)) { $paths += $item.Path }
            }
            if ($paths.Count -gt 0) {
                $baseName = if ($paths.Count -eq 1) { [System.IO.Path]::GetFileNameWithoutExtension($paths[0]) } else { "Archive" }
                $zipPath = Join-Path $script:desktopPath "$baseName.zip"
                $i = 1; while (Test-Path -LiteralPath $zipPath) { $zipPath = Join-Path $script:desktopPath "$baseName ($i).zip"; $i++ }
                Compress-Archive -LiteralPath $paths -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue
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
    Add-MenuItem $itemMenu "Properties" $null { $p = [string]$itemMenu.Tag; if (-not [string]::IsNullOrWhiteSpace($p)) { Show-ItemProperties $p } } | Out-Null
    $script:itemContextMenu = $itemMenu
}

function Show-ItemContextMenu {
    param([string]$Path, [System.Drawing.Point]$ScreenPoint)
    if ($null -eq $script:itemContextMenu) { return }
    $script:itemContextMenu.Tag = $Path; try { $script:itemContextMenu.Show($ScreenPoint) } catch { }
}

function Copy-SelectedFiles {
    if ($script:selectedItems.Count -eq 0) { return }
    try {
        $paths = New-Object System.Collections.Specialized.StringCollection
        foreach ($item in $script:selectedItems) {
            $path = [string]$item.Path
            if (-not [string]::IsNullOrWhiteSpace($path)) { [void]$paths.Add($path) }
        }
        if ($paths.Count -gt 0) { [System.Windows.Forms.Clipboard]::SetFileDropList($paths) }
    } catch { }
}

function Paste-ClipboardFiles {
    try {
        if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
            $list = [System.Windows.Forms.Clipboard]::GetFileDropList()
            foreach ($file in $list) {
                try { Copy-Item -LiteralPath $file -Destination $script:desktopPath -Recurse -ErrorAction SilentlyContinue } catch {}
            }
        }
    } catch { }
}

# ============================================================
# 013 - REFRESH & SETTINGS UI
# ============================================================

function Refresh-Desktop {
    if ($script:refreshing) { return }
    if ($null -eq $script:primaryForm -or $script:primaryForm.IsDisposed) { return }
    Build-DesktopIcons
}

function Reset-DesktopSettings {
    try { if (Test-Path -LiteralPath $settingsFile) { Remove-Item -LiteralPath $settingsFile -Force -ErrorAction SilentlyContinue } } catch { }
    $settings.BackgroundType  = $defaultSettings.BackgroundType; $settings.BackgroundColor = $defaultSettings.BackgroundColor
    $settings.ImagePath       = $defaultSettings.ImagePath; $settings.ImageMode       = $defaultSettings.ImageMode
    $settings.IconScale       = $defaultSettings.IconScale; $settings.DesktopPath     = Join-Path $env:USERPROFILE "Desktop"
    $settings.SortBy          = $defaultSettings.SortBy
    $settings.Positions       = @{}
    Clear-Selection; $script:desktopPath = $settings.DesktopPath; Save-DesktopSettings; Load-BackgroundImage
    Apply-Background
    Refresh-Desktop
}

function Show-Settings {
    if ($script:settingsForm -and -not $script:settingsForm.IsDisposed) { $script:settingsForm.Activate(); return }
    $sf = New-Object System.Windows.Forms.Form
    $script:settingsForm = $sf; $sf.Text = "Personalization"; $sf.Width = 600; $sf.Height = 780
    $sf.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen; $sf.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $sf.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19")
    Enable-DoubleBuffer $sf
    $sf.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#1e293b"), 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1); $pen.Dispose()
    })

    $header = New-Object System.Windows.Forms.Panel
    $header.Left = 0; $header.Top = 0; $header.Width = 600; $header.Height = 100
    $header.BackColor = [System.Drawing.Color]::Transparent; $sf.Controls.Add($header)
    $header.Cursor = [System.Windows.Forms.Cursors]::SizeAll
    $dragDown = { param($s,$e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $script:setDragStart = $e.Location; $script:setDragging = $true } }
    $dragUp = { param($s,$e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $script:setDragging = $false } }
    $dragMove = { param($s,$e) if ($script:setDragging) { $sf.Left += $e.X - $script:setDragStart.X; $sf.Top += $e.Y - $script:setDragStart.Y } }
    
    $header.Add_MouseDown($dragDown); $header.Add_MouseUp($dragUp); $header.Add_MouseMove($dragMove)
    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Personalization"; $title.Left = 25; $title.Top = 25; $title.AutoSize = $true; $title.ForeColor = $script:Colors.Text
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $title.Cursor = [System.Windows.Forms.Cursors]::SizeAll; $title.Add_MouseDown($dragDown); $title.Add_MouseUp($dragUp); $title.Add_MouseMove($dragMove)
    $header.Controls.Add($title)
    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = "Customize your emulated desktop appearance and behavior"; $subtitle.Left = 30; $subtitle.Top = 68; $subtitle.AutoSize = $true
    $subtitle.ForeColor = $script:Colors.Muted; $subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $subtitle.Cursor = [System.Windows.Forms.Cursors]::SizeAll; $subtitle.Add_MouseDown($dragDown); $subtitle.Add_MouseUp($dragUp); $subtitle.Add_MouseMove($dragMove)
    $header.Controls.Add($subtitle)

    function Add-Card($Top, $Title, $Height) {
        $c = New-Object System.Windows.Forms.Panel; $c.Left = 30; $c.Top = $Top; $c.Width = 524; $c.Height = $Height
        $c.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827"); $sf.Controls.Add($c)
        $l = New-Object System.Windows.Forms.Label; $l.Text = $Title; $l.Left = 20; $l.Top = 15; $l.AutoSize = $true
        $l.ForeColor = $script:Colors.Accent; $l.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $c.Controls.Add($l)
        return $c
    }
    function Add-Btn($P, $L, $T, $W, $Txt, $Act) {
        $b = New-Object System.Windows.Forms.Button; $b.Text = $Txt; $b.Left = $L; $b.Top = $T; $b.Width = $W; $b.Height = 36
        $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f2937"); $b.ForeColor = $script:Colors.Text
        $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $b.FlatAppearance.BorderSize = 1; $b.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
        $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        $b.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151") })
        $b.Add_MouseLeave({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f2937") })
        $b.Add_Click($Act); $P.Controls.Add($b); return $b
    }

    # Card 1: Background
    $cardBg = Add-Card 110 "BACKGROUND" 195
    $radioColor = New-Object System.Windows.Forms.RadioButton; $radioColor.Text = "Solid color"; $radioColor.Left = 20; $radioColor.Top = 45; $radioColor.AutoSize = $true
    $radioColor.ForeColor = $script:Colors.Text; $radioColor.Checked = ($settings.BackgroundType -eq "Color"); $cardBg.Controls.Add($radioColor)
    $radioImage = New-Object System.Windows.Forms.RadioButton; $radioImage.Text = "Image"; $radioImage.Left = 140; $radioImage.Top = 45; $radioImage.AutoSize = $true
    $radioImage.ForeColor = $script:Colors.Text; $radioImage.Checked = ($settings.BackgroundType -eq "Image"); $cardBg.Controls.Add($radioImage)

    $colorButton = Add-Btn $cardBg 20 80 150 "Choose Color" {
        $dialog = New-Object System.Windows.Forms.ColorDialog; $dialog.FullOpen = $true; $dialog.Color = Get-ColorFromHex $settings.BackgroundColor
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $settings.BackgroundColor = [System.Drawing.ColorTranslator]::ToHtml($dialog.Color); $radioColor.Checked = $true }
        $dialog.Dispose()
    }
    $imageButton = Add-Btn $cardBg 185 80 150 "Choose Image" {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog; $dialog.Filter = "Images|*.png;*.jpg;*.jpeg;*.bmp;*.gif|All files|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $settings.ImagePath = $dialog.FileName; $radioImage.Checked = $true; $currentLabel.Text = $dialog.FileName }
        $dialog.Dispose()
    }

    $modeLabel = New-Object System.Windows.Forms.Label; $modeLabel.Text = "Image mode"; $modeLabel.Left = 20; $modeLabel.Top = 135; $modeLabel.AutoSize = $true; $modeLabel.ForeColor = $script:Colors.Muted; $cardBg.Controls.Add($modeLabel)
    $modeCombo = New-Object System.Windows.Forms.ComboBox; foreach ($mode in @("Fill", "Fit", "Stretch", "Center", "Tile")) { [void]$modeCombo.Items.Add($mode) }
    $modeCombo.Left = 105; $modeCombo.Top = 132; $modeCombo.Width = 230; $modeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList; $modeCombo.SelectedItem = $settings.ImageMode
    if ($modeCombo.SelectedIndex -lt 0) { $modeCombo.SelectedIndex = 0 }; $cardBg.Controls.Add($modeCombo)

    $currentLabel = New-Object System.Windows.Forms.Label
    $currentLabel.Text = if ([string]::IsNullOrWhiteSpace($settings.ImagePath)) { "No image selected" } else { $settings.ImagePath }
    $currentLabel.Left = 20; $currentLabel.Top = 165; $currentLabel.Width = 490; $currentLabel.Height = 20; $currentLabel.ForeColor = $script:Colors.Muted; $currentLabel.AutoEllipsis = $true; $cardBg.Controls.Add($currentLabel)

    # Card 2: Desktop Folder
    $cardFolder = Add-Card 320 "DESKTOP FOLDER" 95
    $pathBox = New-Object System.Windows.Forms.TextBox; $pathBox.Left = 20; $pathBox.Top = 45; $pathBox.Width = 370; $pathBox.Height = 25
    $pathBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0b0f19"); $pathBox.ForeColor = $script:Colors.Text
    $pathBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $pathBox.Text = [string]$settings.DesktopPath; $cardFolder.Controls.Add($pathBox)
    $browsePathButton = Add-Btn $cardFolder 405 40 100 "Browse..." {
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ((Test-Path -LiteralPath $pathBox.Text)) { $folderDialog.SelectedPath = $pathBox.Text }
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $pathBox.Text = $folderDialog.SelectedPath }
        $folderDialog.Dispose()
    }

    # Card 3: Icon Size
    $cardIcons = Add-Card 430 "ICON SETTINGS" 95
    $iconSlider = New-Object System.Windows.Forms.TrackBar; $iconSlider.Left = 15; $iconSlider.Top = 40; $iconSlider.Width = 380
    $iconSlider.Minimum = 48; $iconSlider.Maximum = 256; $iconSlider.TickFrequency = 16; $iconSlider.Value = [int]$settings.IconScale; $cardIcons.Controls.Add($iconSlider)
    $iconSizeLabel = New-Object System.Windows.Forms.Label; $iconSizeLabel.Text = "$($iconSlider.Value) px"; $iconSizeLabel.Left = 410; $iconSizeLabel.Top = 45; $iconSizeLabel.Width = 80
    $iconSizeLabel.ForeColor = $script:Colors.Text; $cardIcons.Controls.Add($iconSizeLabel)
    $iconSlider.Add_Scroll({ $iconSizeLabel.Text = "$($iconSlider.Value) px" })

    # Bottom Buttons
    $reset = New-Object System.Windows.Forms.Button; $reset.Text = "Restore Defaults"; $reset.Left = 30; $reset.Top = 680; $reset.Width = 140; $reset.Height = 40
    $reset.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827"); $reset.ForeColor = $script:Colors.Danger; $reset.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $reset.FlatAppearance.BorderSize = 1; $reset.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $reset.Cursor = [System.Windows.Forms.Cursors]::Hand
    $reset.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#7f1d1d"); $this.ForeColor = [System.Drawing.Color]::White })
    $reset.Add_MouseLeave({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827"); $this.ForeColor = $script:Colors.Danger })
    $reset.Add_Click({ if ([System.Windows.Forms.MessageBox]::Show("Restore defaults?", "Reset", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question) -eq [System.Windows.Forms.DialogResult]::Yes) { Reset-DesktopSettings; $sf.Close() } }); $sf.Controls.Add($reset)
    
    $cancel = New-Object System.Windows.Forms.Button; $cancel.Text = "Cancel"; $cancel.Left = 294; $cancel.Top = 680; $cancel.Width = 120; $cancel.Height = 40
    $cancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f2937"); $cancel.ForeColor = $script:Colors.Text; $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $cancel.FlatAppearance.BorderSize = 0
    $cancel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cancel.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151") })
    $cancel.Add_MouseLeave({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1f2937") })
    $cancel.Add_Click({ $sf.Close() }); $sf.Controls.Add($cancel)
    $sf.CancelButton = $cancel
    
    $apply = New-Object System.Windows.Forms.Button; $apply.Text = "Apply Changes"; $apply.Left = 424; $apply.Top = 680; $apply.Width = 130; $apply.Height = 40
    $apply.BackColor = $script:Colors.Accent; $apply.ForeColor = $script:Colors.Text; $apply.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $apply.FlatAppearance.BorderSize = 0
    $apply.Cursor = [System.Windows.Forms.Cursors]::Hand
    $apply.Add_MouseEnter({ $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563eb") })
    $apply.Add_MouseLeave({ $this.BackColor = $script:Colors.Accent })
    $apply.Add_Click({
        $settings.BackgroundType = if ($radioImage.Checked) { "Image" } else { "Color" }
        if ($null -ne $modeCombo.SelectedItem) { $settings.ImageMode = [string]$modeCombo.SelectedItem }
        $settings.IconScale = [int]$iconSlider.Value
        $newPath = $pathBox.Text.Trim()
        if (-not [string]::IsNullOrWhiteSpace($newPath)) {
            try { $newPath = [Environment]::ExpandEnvironmentVariables($newPath) } catch { }
            if (-not (Test-Path -LiteralPath $newPath)) {
                [System.Windows.Forms.MessageBox]::Show("The specified desktop folder does not exist.", "Invalid Path", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
                return
            }
            $settings.DesktopPath = $newPath; $script:desktopPath = $newPath; $desktopPath = $newPath
        }
        Save-AllPositions; Save-DesktopSettings; Load-BackgroundImage; Apply-Background; Refresh-Desktop; $sf.Close()
        Init-FileSystemWatcher
    }); $sf.Controls.Add($apply); $sf.AcceptButton = $apply

    [void]$sf.ShowDialog(); $script:settingsForm = $null; try { $sf.Dispose() } catch { }
}

# ============================================================
# 014 - RENDER ICONS (AND DRAG LOGIC)
# ============================================================

function Build-DesktopIcons {
    if ($null -eq $script:primaryForm -or $script:primaryForm.IsDisposed -or $script:refreshing) { return }
    $script:refreshing = $true
    try {
        Dispose-DesktopControls
        
        $usePath = $script:desktopPath
        $items = @()
        try {
            $items = @(Get-ChildItem -LiteralPath $usePath -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "desktop.ini" })
            if ($settings.SortBy -eq "Size") {
                $items = @($items | Sort-Object @{Expression={-not $_.PSIsContainer}}, Length, Name)
            } elseif ($settings.SortBy -eq "Date") {
                $items = @($items | Sort-Object @{Expression={-not $_.PSIsContainer}}, LastWriteTime -Descending)
            } else {
                $items = @($items | Sort-Object @{Expression={-not $_.PSIsContainer}}, Name)
            }
        } catch { }

        $iconSize = [int]$settings.IconScale
        # Scale text size based on icon size
        $fontSize = [Math]::Max(8.0, [Math]::Min(16.0, [Math]::Round(7.0 + ($iconSize / 24.0), 1)))
        $script:desktopFont = New-Object System.Drawing.Font("Segoe UI", [float]$fontSize)
        $labelHeight = [int]($fontSize * 4.5)
        
        $script:cellWidth  = [int]($iconSize + ($fontSize * 3.5))
        $script:cellHeight = [int]($iconSize + $labelHeight + 15)
        
        $index = 0
        
        $occupiedSlots = @{}
        foreach ($item in $items) {
            $saved = Get-SavedPosition $item.FullName
            if ($null -ne $saved) {
                $col = [int][Math]::Round(($saved.X - 14) / $script:cellWidth)
                $row = [int][Math]::Round(($saved.Y - 14) / $script:cellHeight)
                $occupiedSlots["$col,$row"] = $true
            }
        }
        $rows = [Math]::Max(1, [int][Math]::Floor(($script:primaryForm.ClientSize.Height - 14) / $script:cellHeight))

        foreach ($item in $items) {
            try {
                $path = [string]$item.FullName; $name = [string]$item.Name
                $w = [int]$script:cellWidth - 10; $h = [int]$script:cellHeight
                
                $maxX = [Math]::Max(0, $script:primaryForm.ClientSize.Width  - $w - 4)
                $maxY = [Math]::Max(0, $script:primaryForm.ClientSize.Height - $h)

                $saved = Get-SavedPosition $path
                if ($null -ne $saved) {
                    $px = [Math]::Max(0, [Math]::Min($maxX, [int]$saved.X))
                    $py = [Math]::Max(0, [Math]::Min($maxY, [int]$saved.Y))
                } else {
                    $slotCol = 0; $slotRow = 0
                    while ($occupiedSlots.ContainsKey("$slotCol,$slotRow")) {
                        $slotRow++
                        if ($slotRow -ge $rows) { $slotRow = 0; $slotCol++ }
                    }
                    $occupiedSlots["$slotCol,$slotRow"] = $true
                    $px = 14 + ($slotCol * $script:cellWidth); $py = 14 + ($slotRow * $script:cellHeight)
                    Save-ItemPosition -Path $path -X $px -Y $py -NoSave
                }

                $bitmap = Get-DesktopIcon -Item $item -Size $iconSize
                
                $dItem = New-Object PSObject -Property @{
                    Path = $path
                    Name = $name
                    Bounds = New-Object System.Drawing.Rectangle($px, $py, $w, $h)
                    Icon = $bitmap
                    Selected = $false
                }
                $script:desktopItems += $dItem
                $index++
            } catch { }
        }
        
        # Restore selection
        $newSelected = @()
        foreach ($sel in $script:selectedItems) {
            $match = $script:desktopItems | Where-Object { $_.Path -eq $sel.Path } | Select-Object -First 1
            if ($null -ne $match) { $match.Selected = $true; $newSelected += $match }
        }
        $script:selectedItems = $newSelected
        
        $script:primaryForm.Invalidate()
    } finally { $script:refreshing = $false }
}

# ============================================================
# 015 - CREATE FORMS, LASSO & RESIZE EVENTS
# ============================================================

$script:dragEnterHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy }
    } catch {}
}

$script:dragDropHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
            $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
            if ($null -eq $files) { return }
            $dropPoint = $sender.PointToClient((New-Object System.Drawing.Point($e.X, $e.Y)))
            foreach ($f in $files) { 
                try { 
                    $leaf = Split-Path -Leaf $f
                    $dest = Join-Path $script:desktopPath $leaf
                    Copy-Item -LiteralPath $f -Destination $dest -Recurse -ErrorAction Stop 
                    Save-ItemPosition -Path $dest -X $dropPoint.X -Y $dropPoint.Y
                    $dropPoint.X += 40; $dropPoint.Y += 40
                } catch {} 
            }
        }
    } catch {}
}

$script:paintHandler = { param($sender, $e); Paint-DesktopBackground $e }

$script:mouseDownHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        $sender.Focus()
        $clickedItem = $null
        foreach ($item in $script:desktopItems) { if ($item.Bounds.Contains($e.Location)) { $clickedItem = $item; break } }
        
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
                
                if ($isCtrl) { if ($script:selectedItems -contains $clickedItem) { Remove-Selection $clickedItem; return } else { Set-Selection $clickedItem } }
                else { if ($script:selectedItems -notcontains $clickedItem) { Clear-Selection; Set-Selection $clickedItem } }
                
                $script:dragStartScreen = [System.Windows.Forms.Cursor]::Position
                $script:dragDeltaX = 0; $script:dragDeltaY = 0; $script:isDragging = $false
                $script:dragOriginalPositions.Clear()
                foreach ($p in $script:selectedItems) { $script:dragOriginalPositions[$p.Path] = $p.Bounds.Location }
                $script:dragPanel = $clickedItem; $sender.Capture = $true
            } else {
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                if (-not $isCtrl) { Clear-Selection }
                $script:lassoStart = $e.Location; $script:isLassoing = $true; $script:lassoRect = [System.Drawing.Rectangle]::Empty
            }
        } elseif ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            if ($null -ne $clickedItem) {
                if ($script:selectedItems -notcontains $clickedItem) { Clear-Selection; Set-Selection $clickedItem }
                $script:itemContextMenu.Tag = $clickedItem.Path; $script:itemContextMenu.Show($sender, $e.Location)
            } else { $script:contextMenu.Show($sender, $e.Location) }
        }
    } catch { }
}

$script:mouseMoveHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        $newHover = $null
        foreach ($item in $script:desktopItems) { if ($item.Bounds.Contains($e.Location)) { $newHover = $item; break } }
        if ($script:hoverItem -ne $newHover) { $script:hoverItem = $newHover; $sender.Invalidate() }
        
        if ($script:isLassoing) {
            $x = [Math]::Min($script:lassoStart.X, $e.X); $y = [Math]::Min($script:lassoStart.Y, $e.Y)
            $w = [Math]::Abs($script:lassoStart.X - $e.X); $h = [Math]::Abs($script:lassoStart.Y - $e.Y)
            $script:lassoRect = New-Object System.Drawing.Rectangle($x, $y, $w, $h); $sender.Invalidate()
        } elseif ($null -ne $script:dragPanel -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $sp = [System.Windows.Forms.Cursor]::Position
            $dx = $sp.X - $script:dragStartScreen.X; $dy = $sp.Y - $script:dragStartScreen.Y
            if (-not $script:isDragging) { if ([Math]::Abs($dx) -gt 5 -or [Math]::Abs($dy) -gt 5) { $script:isDragging = $true } }
            if ($script:isDragging) { $script:dragDeltaX = $dx; $script:dragDeltaY = $dy; $sender.Invalidate() }
        }
    } catch { }
}

$script:mouseUpHandler = {
    param($sender, $e)
    if ($null -eq $sender -or $null -eq $e) { return }
    try {
        if ($script:isLassoing) {
            $script:isLassoing = $false
            if ($script:lassoRect.Width -gt 5 -and $script:lassoRect.Height -gt 5) { foreach ($item in $script:desktopItems) { if ($item.Bounds.IntersectsWith($script:lassoRect)) { Set-Selection $item } } }
            $script:lassoRect = [System.Drawing.Rectangle]::Empty; $sender.Invalidate()
        } elseif ($null -ne $script:dragPanel) {
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
                if ($script:isDragging) {
                    $mx = $sender.ClientSize.Width; $my = $sender.ClientSize.Height
                    foreach ($item in $script:selectedItems) {
                        $orig = $script:dragOriginalPositions[$item.Path]; if ($null -eq $orig) { continue }
                        $nx = $orig.X + $script:dragDeltaX; $ny = $orig.Y + $script:dragDeltaY
                        if ($isCtrl -and $script:cellWidth -gt 0 -and $script:cellHeight -gt 0) {
                            $col = [int][Math]::Round(($nx - 14) / $script:cellWidth); $row = [int][Math]::Round(($ny - 14) / $script:cellHeight)
                            $nx = 14 + ($col * $script:cellWidth); $ny = 14 + ($row * $script:cellHeight)
                        }
                        if ($nx -lt 0) { $nx = 0 }; if ($ny -lt 0) { $ny = 0 }
                        $maxPx = [Math]::Max(0, $mx - $item.Bounds.Width); $maxPy = [Math]::Max(0, $my - $item.Bounds.Height)
                        if ($nx -gt $maxPx) { $nx = $maxPx }; if ($ny -gt $maxPy) { $ny = $maxPy }
                        $item.Bounds = New-Object System.Drawing.Rectangle($nx, $ny, $item.Bounds.Width, $item.Bounds.Height)
                        Save-ItemPosition -Path $item.Path -X $nx -Y $ny
                    }
                } else { if (-not $isCtrl) { $t = $script:dragPanel; Clear-Selection; Set-Selection $t } }
            }
            try { $sender.Capture = $false } catch {}
            $script:dragPanel = $null; $script:isDragging = $false; $script:dragOriginalPositions.Clear(); $sender.Invalidate()
        }
    } catch { }
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
                    $mx = [Math]::Max(0, $frm.ClientSize.Width - $item.Bounds.Width)
                    $my = [Math]::Max(0, $frm.ClientSize.Height - $item.Bounds.Height)
                    $nx = $item.Bounds.X; $ny = $item.Bounds.Y
                    if ($nx -gt $mx) { $nx = $mx }
                    if ($ny -gt $my) { $ny = $my }
                    $item.Bounds = New-Object System.Drawing.Rectangle($nx, $ny, $item.Bounds.Width, $item.Bounds.Height)
                }
            }
        }
        $frm.Invalidate()
    } catch { }
}

$screens = [System.Windows.Forms.Screen]::AllScreens
foreach ($screen in $screens) {
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.Left = $screen.WorkingArea.Left; $form.Top = $screen.WorkingArea.Top
    $form.Width = $screen.WorkingArea.Width; $form.Height = $screen.WorkingArea.Height
    $form.ShowInTaskbar = $false; $form.KeyPreview = $true; $form.Text = "Emulated Desktop"; $form.BackColor = $script:Colors.Background
    Enable-DoubleBuffer $form
    
    $form.AllowDrop = $true
    $form.Add_DragEnter($script:dragEnterHandler)
    $form.Add_DragDrop($script:dragDropHandler)
    $form.Add_Paint($script:paintHandler)
    $form.Add_MouseDown($script:mouseDownHandler)
    $form.Add_MouseMove($script:mouseMoveHandler)
    $form.Add_MouseUp($script:mouseUpHandler)
    $form.Add_Resize($script:resizeHandler)
    
    $script:forms += $form
}

$primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
foreach ($form in $script:forms) { if ($form.Left -eq $primaryScreen.WorkingArea.Left -and $form.Top -eq $primaryScreen.WorkingArea.Top) { $script:primaryForm = $form; break } }
if ($null -eq $script:primaryForm) { $script:primaryForm = $script:forms[0] }

# ============================================================
# 016 - KEYBOARD & FILE SYSTEM WATCHER
# ============================================================

$script:keyDownHandler = {
    param($sender,$e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        foreach ($closeForm in $script:forms) { if ($null -ne $closeForm -and -not $closeForm.IsDisposed) { $closeForm.Close() } }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F5) { Refresh-Desktop; $e.Handled = $true; $e.SuppressKeyPress = $true; return }
    
    $isCtrl = (([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control)
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::C) { Copy-SelectedFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return }
    if ($isCtrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::V) { Paste-ClipboardFiles; $e.Handled = $true; $e.SuppressKeyPress = $true; return }
    
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F2) {
        if ($script:selectedItems.Count -eq 1) { 
            $path = [string]$script:selectedItems[0].Path; if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) { Rename-DesktopItem $path }
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Delete) {
        if ($script:selectedItems.Count -gt 0) { Delete-DesktopItems }
        $e.Handled = $true; $e.SuppressKeyPress = $true; return
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::PageUp) { Change-IconScale 8; $e.Handled = $true; $e.SuppressKeyPress = $true; return }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::PageDown) { Change-IconScale -8; $e.Handled = $true; $e.SuppressKeyPress = $true; return }
}

foreach ($form in $script:forms) {
    $form.Add_KeyDown($script:keyDownHandler)
}

function Init-FileSystemWatcher {
    if ($script:fsw) { try { $script:fsw.EnableRaisingEvents = $false; $script:fsw.Dispose() } catch {} }
    $script:fsw = New-Object System.IO.FileSystemWatcher
    $script:fsw.Path = $script:desktopPath
    $script:fsw.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size
    if ($null -ne $script:primaryForm) { $script:fsw.SynchronizingObject = $script:primaryForm }
    $script:fsw.EnableRaisingEvents = $true
    
    $handler = { $script:refreshPending = $true }
    $script:fsw.Add_Created($handler)
    $script:fsw.Add_Deleted($handler)
    $script:fsw.Add_Renamed($handler)
    $script:fsw.Add_Changed($handler)
}

$script:refreshTimer.Add_Tick({
    try {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        if ($screens.Count -eq $script:forms.Count) {
            $resized = $false
            for ($i = 0; $i -lt $screens.Count; $i++) {
                $s = $screens[$i]
                $f = $script:forms[$i]
                if ($f.Left -ne $s.WorkingArea.Left -or $f.Top -ne $s.WorkingArea.Top -or $f.Width -ne $s.WorkingArea.Width -or $f.Height -ne $s.WorkingArea.Height) {
                    $f.Left = $s.WorkingArea.Left; $f.Top = $s.WorkingArea.Top
                    $f.Width = $s.WorkingArea.Width; $f.Height = $s.WorkingArea.Height
                    $resized = $true
                }
            }
            if ($resized) { $script:refreshPending = $true }
        }
    } catch {}

    if ($script:refreshPending -and -not $script:isDragging -and -not $script:isLassoing) {
        $script:refreshPending = $false
        Refresh-Desktop
    }
})

Create-ContextMenus
Load-BackgroundImage
Apply-Background
foreach ($form in $script:forms) { try { $form.Show() } catch { } }

try { $script:primaryForm.PerformLayout(); $script:primaryForm.Update() } catch { }
Build-DesktopIcons
Init-FileSystemWatcher
$script:refreshTimer.Start()

# ============================================================
# 018 - MAIN LOOP & CLEANUP
# ============================================================

try { [System.Windows.Forms.Application]::Run($script:primaryForm) } catch { }

try { Save-AllPositions; Save-DesktopSettings; Dispose-DesktopControls } catch { }
if ($script:refreshTimer) { try { $script:refreshTimer.Stop(); $script:refreshTimer.Dispose() } catch {} }
if ($script:fsw) { try { $script:fsw.Dispose() } catch {} }
if ($script:backgroundImage) { try { $script:backgroundImage.Dispose() } catch { } }
foreach ($form in $script:forms) { if ($null -ne $form -and -not $form.IsDisposed) { try { $form.Dispose() } catch { } } }
if ($script:contextMenu) { try { $script:contextMenu.Dispose() } catch { } }
if ($script:itemContextMenu) { try { $script:itemContextMenu.Dispose() } catch { } }
exit 0
