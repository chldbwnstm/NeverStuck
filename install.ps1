#Requires -Version 5.1
<#
NeverStuck installer (Windows).
  .\install.ps1                # install user-global for Claude Code + Codex
  .\install.ps1 -Target claude # Claude Code only  ($env:CLAUDE_CONFIG_DIR or ~/.claude, then \skills\neverstuck)
  .\install.ps1 -Target codex  # Codex only        (~/.agents/skills/neverstuck)
  .\install.ps1 -Sync          # maintainers: refresh in-repo skill copies from canonical sources
Remote one-liners (require git):
  iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1 | iex
  & ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1).Content)) -Target codex
#>
param(
  [ValidateSet('all', 'claude', 'codex')] [string]$Target = 'all',
  [switch]$Sync
)

# Child scope: under `iwr | iex` nothing below (preferences, variables, functions) leaks into
# the caller's session; only the -Target/-Sync parameters above live in the caller's scope.
& {
  $ErrorActionPreference = 'Stop'

  $repoRoot = $PSScriptRoot
  $cleanup = $null
  try {
    # -LiteralPath throughout: a checkout path may contain [ ], which -Path treats as wildcards.
    if (-not $repoRoot -or -not (Test-Path -LiteralPath (Join-Path $repoRoot 'PROTOCOL.md')) -or
        -not (Test-Path -LiteralPath (Join-Path $repoRoot 'adapters\claude-code\SKILL.md'))) {
      if ($Sync) { throw "-Sync refreshes the copies inside a NeverStuck checkout; run .\install.ps1 -Sync from the repo." }
      # Remote mode: not running from a checkout - clone to temp.
      if ($env:NEVERSTUCK_REPO) { $repoUrl = $env:NEVERSTUCK_REPO }
      else { $repoUrl = 'https://github.com/chldbwnstm/NeverStuck.git' }
      if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git was not found on PATH; the remote install needs git (or run .\install.ps1 from a clone). Nothing was installed."
      }
      $tmp = Join-Path $env:TEMP ("neverstuck-install-" + [guid]::NewGuid().ToString('N'))
      Write-Host "Cloning $repoUrl ..."
      $cleanup = $tmp
      # git reports progress on stderr, which hosts such as the ISE turn into errors under
      # 'Stop'; relax the preference for this one call and check the exit code instead.
      $ErrorActionPreference = 'Continue'
      git clone --quiet --depth 1 $repoUrl $tmp
      $code = $LASTEXITCODE
      $ErrorActionPreference = 'Stop'
      if ($code -ne 0) { throw "git clone of $repoUrl failed (exit code $code); nothing was installed." }
      $repoRoot = $tmp
    }

    function Install-NeverStuck([string]$dest) {
      New-Item -ItemType Directory -Force $dest | Out-Null
      Copy-Item -LiteralPath (Join-Path $repoRoot 'adapters\claude-code\SKILL.md') -Destination (Join-Path $dest 'SKILL.md') -Force
      Copy-Item -LiteralPath (Join-Path $repoRoot 'PROTOCOL.md') -Destination (Join-Path $dest 'PROTOCOL.md') -Force
      New-Item -ItemType Directory -Force (Join-Path $dest 'examples') | Out-Null
      Copy-Item -LiteralPath (Join-Path $repoRoot 'examples\teampoint-laser-pointer.md') -Destination (Join-Path $dest 'examples\teampoint-laser-pointer.md') -Force
      Write-Host "  installed -> $dest"
    }

    if ($Sync) {
      Write-Host "Syncing in-repo skill copies from canonical sources (PROTOCOL.md, adapters/claude-code/SKILL.md, examples/teampoint-laser-pointer.md):"
      foreach ($rel in @('.claude\skills\neverstuck', '.agents\skills\neverstuck', 'skills\neverstuck')) {
        # Rebuild each copy from scratch so a stray extra file shows up as a change.
        $copy = Join-Path $repoRoot $rel
        if (Test-Path -LiteralPath $copy) { Remove-Item -LiteralPath $copy -Recurse -Force }
        Install-NeverStuck $copy
      }
      Write-Host "Reminder: when the skill changes, bump `"version`" in .claude-plugin/plugin.json - plugin users only receive a new version."
    }
    else {
      if ($env:CLAUDE_CONFIG_DIR) { $claudeHome = $env:CLAUDE_CONFIG_DIR }
      else { $claudeHome = Join-Path $HOME '.claude' }
      Write-Host "Installing NeverStuck user-global:"
      if ($Target -eq 'all' -or $Target -eq 'claude') { Install-NeverStuck (Join-Path $claudeHome 'skills\neverstuck') }
      if ($Target -eq 'all' -or $Target -eq 'codex') { Install-NeverStuck (Join-Path $HOME '.agents\skills\neverstuck') }
      Write-Host ""
      Write-Host "Done. Claude Code: /neverstuck   |   Codex: `$neverstuck (or /skills)"
      Write-Host "Restart the agent or start a new session to pick up the skill."
    }
  }
  finally {
    if ($cleanup -and (Test-Path -LiteralPath $cleanup)) { Remove-Item -LiteralPath $cleanup -Recurse -Force }
  }
}
