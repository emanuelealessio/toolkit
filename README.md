# toolkit

Personal Claude Code toolkit — generic skills, agents and settings that travel with you across machines and projects.

Clone, install, and Claude Code is set up exactly how you like it.

## Quickstart

```bash
git clone https://github.com/emanuelealessio/toolkit.git ~/toolkit
cd ~/toolkit
./install.sh
```

Re-running `./install.sh` is idempotent. Use `./install.sh --verify` to check status. Use `./uninstall.sh` to remove (state is preserved).

After install, `git pull` in `~/toolkit` propagates updates instantly — skills are symlinked, not copied.

## What it gives you

- **9 skills** in `~/.claude/skills/` (symlinked)
- **3 subagents** in `~/.claude/agents/` (symlinked)
- A merged `~/.claude/settings.json` with read-only git/rg/ls permissions pre-allowed
- A scaffolded `~/.claude/state/` for cross-session memory

Existing skills (e.g. `session-start-hook`) and hook entries in `settings.json` are preserved — the installer never overwrites silently.

## Skills

| Skill | Use it when |
|---|---|
| `my-preferences` | Auto-discovered. Sets language, recap rules, subagent mindset. |
| `workflow-plan` | Multi-step task — produce a numbered plan in `PLAN.md`. |
| `workflow-execute` | Execute an approved plan step-by-step, log decisions. |
| `session-resume` | Resuming work on a project — reads `STATE.md` + `HANDOFF.md`. |
| `session-handoff` | Closing a long session — snapshot state for next time. |
| `debug-protocol` | Bug, error, stack trace — Symptom → Root cause → Fix → Why. |
| `git-commit` | Stage is ready — drafts conventional-commit message. |
| `git-pr` | Branch is ready — drafts PR title/body/test-plan (no auto-push). |
| `project-bootstrap` | New repo — scaffold project state and templates. |

## Subagents

| Agent | Role |
|---|---|
| `code-explorer` | Read-only mapping of code relevant to a query. |
| `test-runner` | Detect and run the project's test command. |
| `doc-writer` | Draft README/doc sections from a spec. |

## Shared state

```
~/.claude/state/
├── identity.md                  # global preferences (lingua, recap, mindset)
└── projects/<slug>/             # per-project artifacts, slug from git remote or cwd
    ├── PROJECT.md
    ├── STATE.md
    ├── PLAN.md
    ├── DECISIONS.md
    └── HANDOFF.md
```

Everything lives outside your project repos. Nothing pollutes the codebases you work on.

Slug detection: `git remote get-url origin` → basename without `.git`. Fallback: `basename $(git rev-parse --show-toplevel)` → `$PWD` basename.

## Layout

```
toolkit/
├── install.sh / uninstall.sh
├── lib/merge-settings.py
├── settings/settings.fragment.json
├── skills/<name>/SKILL.md       # one dir per skill
├── agents/<name>.md             # one file per subagent
└── templates/                   # seeds copied by project-bootstrap
```

## Requirements

- macOS or Linux (Windows requires WSL — native NTFS symlinks are unreliable)
- `python3`, `git`
- Claude Code CLI

## Uninstall

```bash
~/toolkit/uninstall.sh
```

Removes only symlinks pointing into the toolkit. Restores `settings.json` from the most recent backup at `~/.claude/backups/pre-toolkit-*`. `~/.claude/state/` is preserved.
