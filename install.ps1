# Installs the visual-audit skill on Windows.
#   irm https://raw.githubusercontent.com/hoseinnp/visual-audit/main/install.ps1 | iex
# Options (download the script first, then run it):
#   .\install.ps1 -Project       install into .\.claude\skills of the current folder
#   .\install.ps1 -Dir <path>    install into <path>\visual-audit
#   .\install.ps1 -Uninstall     remove it again (combine with -Project or -Dir)
param(
    [switch]$Project,
    [string]$Dir,
    [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'

$raw = if ($env:VISUAL_AUDIT_RAW) { $env:VISUAL_AUDIT_RAW } else { 'https://raw.githubusercontent.com/hoseinnp/visual-audit/main' }
$base = if ($Dir) { $Dir } elseif ($Project) { Join-Path (Get-Location) '.claude\skills' } else { Join-Path $HOME '.claude\skills' }
$target = Join-Path $base 'visual-audit'
$file = Join-Path $target 'SKILL.md'

if ($Uninstall) {
    if (Test-Path $file) {
        Remove-Item $file
        if (-not (Get-ChildItem $target -Force)) { Remove-Item $target }
        Write-Host "Removed $target"
    } else {
        Write-Host "Not installed in $target"
    }
    return
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$text = if ($raw -match '^https?://') {
    (Invoke-WebRequest -UseBasicParsing "$raw/skills/visual-audit/SKILL.md").Content
} else {
    Get-Content -Raw -Encoding UTF8 (Join-Path $raw 'skills\visual-audit\SKILL.md')
}
if ($text -is [byte[]]) { $text = [Text.Encoding]::UTF8.GetString($text) }
# Refuse anything that is not the skill file, so a bad download never lands in the skills folder.
if ($text -notmatch '(?m)^name: visual-audit\r?$') { throw 'Download did not look like the skill file; nothing installed.' }

New-Item -ItemType Directory -Force $target | Out-Null
[IO.File]::WriteAllText($file, $text, (New-Object Text.UTF8Encoding $false))
Write-Host "Installed visual-audit to $target"
Write-Host 'Start a new session, then run /visual-audit or ask for a visual audit.'
