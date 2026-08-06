#Requires -Version 5.1
<#
NeverStuck installer (Windows).
  .\install.ps1                # install user-global for Claude Code + Codex
  .\install.ps1 -Target claude # Claude Code only  (~/.claude/skills/neverstuck)
  .\install.ps1 -Target codex  # Codex only        (~/.agents/skills/neverstuck)
  .\install.ps1 -Sync          # maintainers: refresh in-repo skill copies from canonical sources
Remote one-liner (requires git):
  iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1 | iex
#>
param(
  [ValidateSet('all', 'claude', 'codex')] [string]$Target = 'all',
  [switch]$Sync
)
$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$cleanup = $null
if (-not $repoRoot -or -not (Test-Path (Join-Path $repoRoot 'PROTOCOL.md'))) {
  # Remote mode: not running from a checkout - clone to temp.
  if ($env:NEVERSTUCK_REPO) { $repoUrl = $env:NEVERSTUCK_REPO }
  else { $repoUrl = 'https://github.com/chldbwnstm/NeverStuck.git' }
  $tmp = Join-Path $env:TEMP ("neverstuck-install-" + [guid]::NewGuid().ToString('N'))
  Write-Host "Cloning $repoUrl ..."
  git clone --depth 1 $repoUrl $tmp | Out-Null
  $repoRoot = $tmp
  $cleanup = $tmp
}

function Install-NeverStuck([string]$dest) {
  New-Item -ItemType Directory -Force $dest | Out-Null
  Copy-Item (Join-Path $repoRoot 'adapters\claude-code\SKILL.md') (Join-Path $dest 'SKILL.md') -Force
  Copy-Item (Join-Path $repoRoot 'PROTOCOL.md') (Join-Path $dest 'PROTOCOL.md') -Force
  New-Item -ItemType Directory -Force (Join-Path $dest 'examples') | Out-Null
  Copy-Item (Join-Path $repoRoot 'examples\teampoint-laser-pointer.md') (Join-Path $dest 'examples\teampoint-laser-pointer.md') -Force
  Write-Host "  installed -> $dest"
}

if ($Sync) {
  Write-Host "Syncing in-repo skill copies from canonical sources (PROTOCOL.md, adapters/claude-code/SKILL.md):"
  foreach ($rel in @('.claude\skills\neverstuck', '.agents\skills\neverstuck', 'skills\neverstuck')) {
    Install-NeverStuck (Join-Path $repoRoot $rel)
  }
}
else {
  Write-Host "Installing NeverStuck user-global:"
  if ($Target -eq 'all' -or $Target -eq 'claude') { Install-NeverStuck (Join-Path $HOME '.claude\skills\neverstuck') }
  if ($Target -eq 'all' -or $Target -eq 'codex') { Install-NeverStuck (Join-Path $HOME '.agents\skills\neverstuck') }
  Write-Host ""
  Write-Host "Done. Claude Code: /neverstuck   |   Codex: `$neverstuck (or /skills)"
  Write-Host "Restart the agent or start a new session to pick up the skill."
}

if ($cleanup) { Remove-Item -Recurse -Force $cleanup }
