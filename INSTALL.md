# Install NeverStuck

NeverStuck is installed by your agent. Paste the request from the [README](README.md) into a
session that runs on your own computer; the agent follows the instructions below.

## What gets installed

One folder named `neverstuck` holding exactly three files:

| File in the installed folder | Copied from this repository |
|---|---|
| `SKILL.md` | `adapters/claude-code/SKILL.md` |
| `PROTOCOL.md` | `PROTOCOL.md` |
| `examples/teampoint-laser-pointer.md` | `examples/teampoint-laser-pointer.md` |

`skills/neverstuck/` in this repository holds the same three files. Nothing else is copied: no
scripts, no settings, no other skills.

## Where it goes — one install per agent

| Agent | User-wide folder | Project-only folder | Invoke |
|---|---|---|---|
| Claude Code — terminal, IDE, desktop app's Code tab | `~/.claude/skills/neverstuck/`, or `$CLAUDE_CONFIG_DIR/skills/neverstuck/` when that variable is set | `<project>/.claude/skills/neverstuck/` | `/neverstuck "problem"` |
| Codex — CLI, IDE, app | `~/.agents/skills/neverstuck/` | `<project>/.agents/skills/neverstuck/` | `$neverstuck`, or pick it in `/skills` |
| Another agent that loads Agent Skills (`SKILL.md` folders) | that agent's documented user skills folder | its project skills folder | as that agent documents |

`~` is the home folder of the machine your agent process runs on: `%USERPROFILE%` on native
Windows (in Git Bash use `$USERPROFILE`, not `~` or `$HOME`), the Linux home inside WSL, the
remote home over SSH. "The current project" is the git root of the working folder — without git,
the nearest parent folder holding `.git` — or the working folder itself outside a repository.
Install user-wide unless the user asks for one project.

## Instructions for the installing agent

1. **Where you are.** Work out which agent you are running in and on which operating system,
   and install for that agent only unless the user asks for more. Install on the machine your
   agent process runs on — that is where the skill is loaded. Stop and send the user to a local
   session if you are in a cloud session (`CLAUDE_CODE_REMOTE=true`, a Codex cloud task) or in
   Cowork or claude.ai Chat, which load skills from the account rather than from these folders.
2. **Find existing installs for this agent** before writing anything:
   - Claude Code: the user-wide folder from the table; `.claude/skills/neverstuck/` in the
     current project; and the plugin, counted only if it is enabled here — `claude plugin list`
     shows `neverstuck@neverstuck` enabled, or, without the CLI,
     `<config>/plugins/installed_plugins.json` has a `neverstuck@neverstuck` entry with
     `"scope": "user"` or a `projectPath` equal to the current project (`<config>` is
     `$CLAUDE_CONFIG_DIR`, else `~/.claude`). An entry for another project is not an install
     here: mention it and carry on. Under WSL, a `claude` that resolves into `/mnt/c` is the
     Windows CLI: never run it — use the file check, and ask the user to run any plugin command
     in their WSL Claude Code session.
   - Codex: `~/.agents/skills/neverstuck/`; the older `$CODEX_HOME/skills/neverstuck/`
     (`~/.codex/skills/neverstuck/` when `CODEX_HOME` is unset); and `.agents/skills/neverstuck/`
     or `.codex/skills/neverstuck/` in the current project.

   Count installs with these rules:
   - Only a folder whose `SKILL.md` has `name: neverstuck` counts.
   - Installs for the other agent are not duplicates; leave them alone.
   - Paths that resolve to the same folder are one install — for example when the current
     project is your home folder, or when one path is a link to another (see "Links and shared
     folders").
   - The repository's own copies are not installs. If the current project is a NeverStuck
     checkout (`PROTOCOL.md` and `adapters/claude-code/SKILL.md` at its root), leave its
     `.claude/skills/neverstuck/`, `.agents/skills/neverstuck/` and `skills/neverstuck/` out,
     never change or delete them, and install user-wide. Never write through an install path
     that resolves into a NeverStuck checkout either: tell the user, and offer to replace it with
     a real install.

   Then:
   - Nothing found: continue with step 3.
   - One folder install: update it in place with steps 3–6. If the only Codex install is in the
     older `$CODEX_HOME/skills`, install in `~/.agents/skills/neverstuck/` instead, verify it, and
     then remove the old folder as described under "Uninstalling".
   - One plugin install: run `claude plugin marketplace update neverstuck`, then
     `claude plugin update neverstuck@neverstuck`; skip steps 3–5, confirm the version with
     `claude plugin list`, and go to step 6.
   - More than one: tell the user what you found and ask which to keep, remove the others as
     described under "Uninstalling", then update the one kept.
3. **Get the files.** If the current project is a NeverStuck checkout, or the user points you at
   one, ask whether to install its working tree (with local changes) or the latest GitHub commit.
   For the working tree, copy from it as it is — never clone it or delete it — and report its
   HEAD and whether `git status --porcelain -- PROTOCOL.md adapters/claude-code/SKILL.md
   examples/teampoint-laser-pointer.md` shows changes; without git, read `.git/HEAD` and say you
   could not check. Otherwise clone with
   `git clone --depth 1 https://github.com/chldbwnstm/NeverStuck` into a temporary folder and
   note `git rev-parse HEAD`. Without git, read the latest commit SHA from
   `https://api.github.com/repos/chldbwnstm/NeverStuck/commits/master` and download the three
   files from `https://raw.githubusercontent.com/chldbwnstm/NeverStuck/<sha>/<path>` into a
   temporary folder; if the API refuses, use `master` in place of the SHA and report the commit as
   unknown.
4. **Copy.** Before copying into an existing folder, list anything in it besides the three files
   and ask whether to remove it. Create the target folder and its `examples/` subfolder and copy
   the three files in, as listed under "What gets installed". From a clone or the user's
   checkout, `./install.sh claude` or `./install.sh codex` (macOS, Linux) and
   `.\install.ps1 -Target claude` or `.\install.ps1 -Target codex` (Windows) do this copy for the
   user-wide folder only. If PowerShell refuses to run the script, copy by hand; do not change or
   bypass the execution policy.
5. **Verify** before reporting success: the folder holds the three files, plus any files the user
   chose to keep (name them in the report); each is identical to its source; `PROTOCOL.md` starts
   with `# NeverStuck Protocol`; the `SKILL.md` front matter has `name: neverstuck`. Then delete
   the temporary folder you made — in PowerShell, `Remove-Item -LiteralPath <folder> -Recurse
   -Force`, because git's pack files are read-only — and never a checkout the user gave you.
6. **Report** where NeverStuck was installed, from which commit, and how to invoke it. Claude Code
   picks up a new skill in the current session (run `/reload-skills` if the skills folder itself
   was just created), and Codex detects skill changes automatically; if it does not show up, a new
   session or an app restart is enough. A plugin update needs a restart when the version changed;
   new content reaches plugin users only with a version bump. Report your file check, and tell the
   user how to do the in-app check: type `/` and look for `/neverstuck` (Claude Code), or open
   `/skills` (Codex). Inside a NeverStuck checkout the repository's own copy loads too, so that
   check belongs in a session outside the checkout.

## Links and shared folders

Old `npx skills` installs link `~/.claude/skills/neverstuck` and `~/.codex/skills/neverstuck` to
`~/.agents/skills/neverstuck`, so one folder can serve both agents.

- To see where a path leads: in PowerShell, `Get-Item -LiteralPath <path> -Force` and its
  `LinkType` and `Target`; in bash, `realpath <path>`. On Windows, compare paths
  case-insensitively.
- Updating through a link updates the folder it points to. If that folder also serves the other
  agent, say so in the report, and keep the link unless the user asks to separate them.
- Before deleting a folder, check whether the other agent's paths link to it. If one does, tell
  the user the folder is shared and ask whether to keep it and remove only this agent's link, or
  to replace the other agent's link with a real copy first.
- Remove a link without touching its target: in PowerShell,
  `(Get-Item -LiteralPath <link> -Force).Delete()` or `cmd /c rmdir "<link>"` (no `/s`); in bash,
  `rm <link>` — no `-r`, no trailing slash. A plain `Remove-Item` on a junction stops at a
  confirmation prompt an agent shell cannot answer, and `rm -rf <link>/` empties the target.

## Updating and uninstalling

Updating is the same request: step 2 finds the install, and steps 3–6 — for the plugin, the two
plugin commands — refresh it.

To uninstall, run step 2's search for this agent and remove what the user chooses, asking first
if there is more than one install. Remove links before folders (see "Links and shared folders"),
and before deleting a folder, list anything in it besides the three files. A project copy tracked
by git is shared with collaborators: tell the user, delete it only if they agree, and leave the
commit to them. For the plugin, run `claude plugin uninstall neverstuck@neverstuck` — adding
`--scope <scope>`, from that project, when `claude plugin list` shows project or local scope —
and then `claude plugin marketplace remove neverstuck`. Search again, report any leftover link,
including a broken one, and confirm that only the installs the user chose to keep remain. Tell
the user to start a new session.

Do not install NeverStuck twice for the same agent (for example a user-wide folder and the
plugin, or user-wide and project folders), do not touch other skills or settings, and do not
write the install into a cloud environment instead of the machine your agent runs on.
