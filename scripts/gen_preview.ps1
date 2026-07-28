$Variant = $args[0]
if (-not $Variant) { $Variant = "light" }

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# ---------- canvas / layout ----------
$W = 960; $H = 600
$titleH = 30; $abW = 48; $sideW = 200
$tabsH = 26
$editorX = $abW + $sideW          # 248
$editorY = $titleH + $tabsH       # 56
$statusH = 24
$editorBottom = $H - $statusH

$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
# No AntiAlias — speed over quality for CI environment

# ---------- color helpers ----------
function C($hex) {
    $h = $hex.TrimStart('#')
    if ($h.Length -eq 8) {
        [System.Drawing.Color]::FromArgb(
            [Convert]::ToByte($h.Substring(0,2),16),
            [Convert]::ToByte($h.Substring(2,2),16),
            [Convert]::ToByte($h.Substring(4,2),16),
            [Convert]::ToByte($h.Substring(6,2),16))
    } else {
        [System.Drawing.Color]::FromArgb(
            0xFF,
            [Convert]::ToByte($h.Substring(0,2),16),
            [Convert]::ToByte($h.Substring(2,2),16),
            [Convert]::ToByte($h.Substring(4,2),16))
    }
}
function FillR($x,$y,$w,$h,$col){ $b=New-Object System.Drawing.SolidBrush($col); $g.FillRectangle($b,$x,$y,$w,$h); $b.Dispose() }
function DrawR($x,$y,$w,$h,$col,$lw){ $p=New-Object System.Drawing.Pen($col,$lw); $g.DrawRectangle($p,$x,$y,$w,$h); $p.Dispose() }
function Line($x1,$y1,$x2,$y2,$col,$lw){ $p=New-Object System.Drawing.Pen($col,$lw); $g.DrawLine($p,$x1,$y1,$x2,$y2); $p.Dispose() }
function Text($s,$font,$col,$x,$y){ $b=New-Object System.Drawing.SolidBrush($col); $g.DrawString($s,$font,$b,$x,$y); $b.Dispose() }

# ---------- palette per variant ----------
if ($Variant -eq "dark") {
    $UI = @{
        editorBg="#21271A"; fg="#E6E2CC"; titleBg="#1B2015"; titleFg="#E6E2CC"; titleBorder="#2A3122"
        abBg="#171C12"; abFg="#A8BE84"; abInactive="#6E7A56"; abBorder="#2A3122"; abBadge="#89986D"
        sideBg="#1B2015"; sideFg="#B9C0A4"; sideTitle="#E6E2CC"; sideBorder="#2A3122"
        tabsBg="#1B2015"; tabActiveBg="#21271A"; tabActiveFg="#E6E2CC"; tabInactiveBg="#1B2015"; tabInactiveFg="#8A9372"; tabBorder="#2A3122"; tabActiveBorder="#9CAB84"
        statusBg="#5E6E45"; statusFg="#F1EEDD"; statusBorder="#4A5638"
        lineHi="#2A3122"; selBg="#9CAB8466"; indent="#3A4630"; gutterBg="#21271A"
        listSelBg="#3A4630"; listSelFg="#F1EEDD"
    }
    $S = @{
        comment="#7E8A6A"; string="#D8C9A0"; number="#E0B85E"; keyword="#A8BE84"
        func="#9CC47E"; cls="#A8BE84"; var="#E6E2CC"; prop="#E6E2CC"; punct="#E6E2CC"; fg="#E6E2CC"; lineNo="#5E6A4A"; lineNoActive="#9CAB84"
    }
} else {
    $UI = @{
        editorBg="#F8F6EA"; fg="#3B4129"; titleBg="#E9EDDC"; titleFg="#3B4129"; titleBorder="#DCE3CC"
        abBg="#E9EDDC"; abFg="#68784A"; abInactive="#A9B18E"; abBorder="#DCE3CC"; abBadge="#89986D"
        sideBg="#EEF1E4"; sideFg="#515A3C"; sideTitle="#3B4129"; sideBorder="#DCE3CC"
        tabsBg="#E9EDDC"; tabActiveBg="#F8F6EA"; tabActiveFg="#3B4129"; tabInactiveBg="#E9EDDC"; tabInactiveFg="#8A9372"; tabBorder="#DCE3CC"; tabActiveBorder="#89986D"
        statusBg="#89986D"; statusFg="#F8F6EA"; statusBorder="#7A895F"
        lineHi="#EFF2E4"; selBg="#C5D89D"; indent="#DCE3CC"; gutterBg="#F8F6EA"
        listSelBg="#C5D89D"; listSelFg="#3B4129"
    }
    $S = @{
        comment="#A3A98C"; string="#9A8B65"; number="#C49A4A"; keyword="#68784A"
        func="#75985A"; cls="#68784A"; var="#3B4129"; prop="#3B4129"; punct="#3B4129"; fg="#3B4129"; lineNo="#B7BD9E"; lineNoActive="#89986D"
    }
}

# fonts (scaled for 960x600)
$fontUI    = New-Object System.Drawing.Font("Consolas", 11)
$fontTitle = New-Object System.Drawing.Font("Consolas", 11)
$fontHead  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$fontTree  = New-Object System.Drawing.Font("Consolas", 10)
$fontTab   = New-Object System.Drawing.Font("Consolas", 10)
$fontCode  = New-Object System.Drawing.Font("Consolas", 12)
$fontStatus= New-Object System.Drawing.Font("Consolas", 9)
$fontNum   = New-Object System.Drawing.Font("Consolas", 11)

function TokColor($key){ C $S[$key] }

# ---------- background ----------
FillR 0 0 $W $H (C $UI.editorBg)

# ===== TITLE BAR =====
FillR 0 0 $W $titleH (C $UI.titleBg)
Line 0 $titleH $W $titleH (C $UI.titleBorder) 1
# traffic lights
$cy = $titleH/2
$lights = @("#ED6A5E","#F4BF4F","#61C554")
$lx = 16
foreach ($lc in $lights){ FillR ($lx) ($cy-6) 12 12 (C $lc); $lx += 20 }
# title text
Text "app.ts  -  Olive Dream Theme" $fontTitle (C $UI.titleFg) 78 ($cy - 9)

# ===== ACTIVITY BAR =====
FillR 0 $titleH $abW ($H-$titleH) (C $UI.abBg)
Line $abW $titleH $abW ($H-$titleH) (C $UI.abBorder) 1
$abx = $abW/2
$ay = $titleH + 28
# icon 1: files (two squares) - active
$b0=New-Object System.Drawing.SolidBrush((C $UI.abFg))
$g.FillRectangle($b0, $abx-9, $ay-8, 12, 12); $g.FillRectangle($b0, $abx-2, $ay-1, 12, 12); $b0.Dispose()
# icon 2: search (circle + handle)
$b1=New-Object System.Drawing.SolidBrush((C $UI.abInactive)); $p1=New-Object System.Drawing.Pen((C $UI.abInactive),2)
$g.DrawEllipse($p1, $abx-9, $ay+30-8, 14, 14); $g.DrawLine($p1, $abx+3, $ay+30+3, $abx+9, $ay+30+9); $p1.Dispose()
# icon 3: git branch
$p3=New-Object System.Drawing.Pen((C $UI.abInactive),2)
$g.DrawEllipse($p3, $abx-8, $ay+62-8, 7,7); $g.DrawEllipse($p3, $abx+1, $ay+62-8, 7,7); $g.DrawLine($p3, $abx-5, $ay+62-1, $abx-5, $ay+62+8); $g.DrawLine($p3, $abx+4, $ay+62-1, $abx+4, $ay+62+8)
$g.DrawLine($p3, $abx-5, $ay+62+8, $abx+4, $ay+62+8)
$p3.Dispose()
# icon 4: debug (play triangle)
$b4=New-Object System.Drawing.SolidBrush((C $UI.abInactive))
$g.FillPolygon($b4, @([System.Drawing.Point]::new($abx-6,$ay+94-8),[System.Drawing.Point]::new($abx-6,$ay+94+8),[System.Drawing.Point]::new($abx+8,$ay+94)))
$b4.Dispose()
# icon 5: extensions (4 squares)
$b5=New-Object System.Drawing.SolidBrush((C $UI.abInactive))
$g.FillRectangle($b5, $abx-9, $ay+126-8, 8,8); $g.FillRectangle($b5, $abx+1, $ay+126-8, 8,8)
$g.FillRectangle($b5, $abx-9, $ay+126+2, 8,8); $g.FillRectangle($b5, $abx+1, $ay+126+2, 8,8)
$b5.Dispose()

# ===== SIDEBAR =====
$sx = $abW
FillR $sx $titleH $sideW ($H-$titleH) (C $UI.sideBg)
Line ($sx+$sideW) $titleH ($sx+$sideW) ($H-$titleH) (C $UI.sideBorder) 1
$padding = $sx + 16
# header
Text "EXPLORER" $fontHead (C $UI.sideTitle) $padding ($titleH + 12)
$y = $titleH + 44
# project node
Text "OLIVE DREAM" $fontHead (C $UI.sideFg) ($padding+14) $y
$y += 26
# file tree
$tree = @(
    @{t="src"; d=$true; sel=$false},
    @{t="app.ts"; d=$false; sel=$true},
    @{t="theme.ts"; d=$false; sel=$false},
    @{t="utils.ts"; d=$false; sel=$false},
    @{t="index.html"; d=$false; sel=$false},
    @{t="styles.css"; d=$false; sel=$false},
    @{t="README.md"; d=$false; sel=$false},
    @{t="package.json"; d=$false; sel=$false}
)
foreach ($n in $tree) {
    $ix = $padding + 14
    $ty = $y
    if ($n.d) {
        # folder triangle
        $bf=New-Object System.Drawing.SolidBrush((C $UI.sideFg))
        $g.FillPolygon($bf, @([System.Drawing.Point]::new($ix,$ty+4),[System.Drawing.Point]::new($ix+7,$ty+4),[System.Drawing.Point]::new($ix+3,$ty+9)))
        $bf.Dispose()
        $tx = $ix + 16
        if ($n.sel){ FillR ($sx+4) ($ty-3) ($sideW-8) 22 (C $UI.listSelBg) }
        Text $n.t $fontTree (C $UI.sideTitle) $tx $ty
    } else {
        $ix2 = $ix + 16
        if ($n.sel){ FillR ($sx+4) ($ty-3) ($sideW-8) 22 (C $UI.listSelBg) }
        # file dot
        $bf=New-Object System.Drawing.SolidBrush((C $UI.sideFg))
        $g.FillRectangle($bf, $ix2, $ty+5, 8, 9); $bf.Dispose()
        $tx = $ix2 + 16
        $col = if ($n.sel) { C $UI.listSelFg } else { C $UI.sideFg }
        Text $n.t $fontTree $col $tx $ty
    }
    $y += 24
}

# ===== TABS STRIP =====
FillR $editorX $titleH ($W-$editorX) $tabsH (C $UI.tabsBg)
Line $editorX ($titleH+$tabsH) ($W-$editorX) ($titleH+$tabsH) (C $UI.tabBorder) 1
# active tab
$tabW = 150
FillR $editorX $titleH $tabW $tabsH (C $UI.tabActiveBg)
FillR $editorX $titleH $tabW 2 (C $UI.tabActiveBorder)
Text "app.ts" $fontTab (C $UI.tabActiveFg) ($editorX+14) ($titleH+7)
# inactive tab
FillR ($editorX+$tabW) $titleH $tabW $tabsH (C $UI.tabInactiveBg)
Text "theme.ts" $fontTab (C $UI.tabInactiveFg) ($editorX+$tabW+14) ($titleH+7)

# ===== EDITOR =====
FillR $editorX $editorY ($W-$editorX) ($editorBottom-$editorY) (C $UI.editorBg)
# gutter separator (subtle)
FillR ($editorX+48) $editorY 1 ($editorBottom-$editorY) (C $UI.indent)

# line highlight + selection on line 12
$lineH = 23
$codeTop = $editorY + 12
$activeLineIdx = 11   # 0-based line 12
$hlY = $codeTop + $activeLineIdx*$lineH - 4
FillR $editorX $hlY ($W-$editorX) $lineH (C $UI.lineHi)
# selection highlight on "theme" word of line 12 (approx region)
$selX = $editorX + 48 + 14*11   # crude
FillR $($editorX+48+[math]::Round(14*11)) $hlY $([math]::Round(14*5)) $lineH (C $UI.selBg)

# code token model
$lines = @(
    @( @{t='// Olive Dream - calm, focused coding'; c='comment'} ),
    @(),
    @( @{t='import';c='keyword'}, @{t=' ';c='fg'}, @{t='{';c='punct'}, @{t=' createTheme';c='func'}, @{t=' }';c='punct'}, @{t=' from';c='keyword'}, @{t=' ';c='fg'}, @{t='"./theme"';c='string'}, @{t=';';c='punct'} ),
    @(),
    @( @{t='const';c='keyword'}, @{t=' palette';c='var'}, @{t=' = ';c='punct'}, @{t='{';c='punct'} ),
    @( @{t='  cream: ';c='prop'}, @{t='"#F8F6EA"';c='string'}, @{t=',';c='punct'} ),
    @( @{t='  sage:  ';c='prop'}, @{t='"#9CAB84"';c='string'}, @{t=',';c='punct'} ),
    @( @{t='  olive: ';c='prop'}, @{t='"#89986D"';c='string'} ),
    @( @{t='};';c='punct'} ),
    @(),
    @( @{t='function';c='keyword'}, @{t=' applyTheme';c='func'}, @{t='(';c='punct'}, @{t='name';c='var'}, @{t=': ';c='punct'}, @{t='string';c='cls'}, @{t=')';c='punct'}, @{t=': ';c='punct'}, @{t='void';c='keyword'}, @{t=' {';c='punct'} ),
    @( @{t='  const';c='keyword'}, @{t=' theme';c='var'}, @{t=' = ';c='punct'}, @{t='createTheme';c='func'}, @{t='(';c='punct'}, @{t='name';c='var'}, @{t=');';c='punct'} ),
    @( @{t='  console';c='var'}, @{t='.';c='punct'}, @{t='log';c='func'}, @{t='(';c='punct'}, @{t='"Applied: "';c='string'}, @{t=' + ';c='punct'}, @{t='theme';c='var'}, @{t='.';c='punct'}, @{t='name';c='prop'}, @{t=');';c='punct'} ),
    @( @{t='  return';c='keyword'}, @{t=' theme';c='var'}, @{t=';';c='punct'} ),
    @( @{t='}';c='punct'} )
)

# measure monospace advance
$charW = $g.MeasureString('0', $fontCode).Width
$codeX = $editorX + 56
$yy = $codeTop
$ln = 1
foreach ($line in $lines) {
    # line number
    $numStr = [string]$ln
    $nw = $g.MeasureString($numStr, $fontNum).Width
    $numCol = if ($ln -eq 12) { C $S.lineNoActive } else { C $S.lineNo }
    Text $numStr $fontNum $numCol ($editorX+44 - $nw) ($yy-1)
    # tokens
    $xx = $codeX
    foreach ($tok in $line) {
        if ($tok.t.Length -gt 0) {
            Text $tok.t $fontCode (TokColor $tok.c) $xx $yy
            $xx += [math]::Round($charW * $tok.t.Length)
        }
    }
    $yy += $lineH
    $ln++
}

# indent guides (faint) for indented region
$guideX1 = $codeX + [math]::Round($charW*2)
$guideX2 = $codeX + [math]::Round($charW*4)
$gdTop = $codeTop + 4*$lineH   # lines 5..8 region
$gdBot = $codeTop + 8*$lineH
$pInd=New-Object System.Drawing.Pen((C $UI.indent),1)
$g.DrawLine($pInd, $guideX1, $gdTop, $guideX1, $gdBot)
$g.DrawLine($pInd, $guideX2, $gdTop, $guideX2, $gdBot)
$pInd.Dispose()

# ===== STATUS BAR =====
FillR 0 $editorBottom $W $statusH (C $UI.statusBg)
Line 0 $editorBottom $W $editorBottom (C $UI.statusBorder) 1
$sbY = $editorBottom + 7
# left: branch
$bdot=New-Object System.Drawing.SolidBrush((C $UI.statusFg))
$g.FillEllipse($bdot, 16, $sbY-1, 9, 9); $bdot.Dispose()
Text "main" $fontStatus (C $UI.statusFg) 32 $sbY
# right items
$rightItems = @("Spaces: 2", "Ln 12, Col 4", "TypeScript", "UTF-8")
$rx = $W - 16
foreach ($ri in $rightItems) {
    $rw = $g.MeasureString($ri, $fontStatus).Width
    $rx -= $rw
    Text $ri $fontStatus (C $UI.statusFg) $rx $sbY
    $rx -= 28
}

# ---------- save ----------
$outDir = Join-Path $PSScriptRoot "..\screenshots"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$outFile = Join-Path $outDir ("olive-dream-" + $Variant + ".png")
$bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$g.Dispose()
Write-Host ("Saved: " + $outFile)
