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

- **12 personal skills** in `~/.claude/skills/` (symlinked from this repo)
- **3 subagents** in `~/.claude/agents/` (symlinked)
- **Anthropic's official skills** (`anthropics/skills`) auto-cloned to `~/.claude/external/` and symlinked alongside — document handling (PDF, DOCX, XLSX, PPTX), Skill Creator and other reference skills come bundled
- A merged `~/.claude/settings.json` with read-only git/rg/ls permissions pre-allowed
- A scaffolded `~/.claude/state/` for cross-session memory

Existing skills (e.g. `session-start-hook`) and hook entries in `settings.json` are preserved — the installer never overwrites silently. If an anthropic skill name collides with a local one, the local one wins.

## Personal skills

### Workflow & state
| Skill | Use it when |
|---|---|
| `my-preferences` | Auto-discovered. Sets language, recap rules, subagent mindset. |
| `workflow-plan` | Multi-step task — produce a numbered plan in `PLAN.md`. |
| `workflow-execute` | Execute an approved plan step-by-step, log decisions. |
| `session-resume` | Resuming work on a project — reads `STATE.md` + `HANDOFF.md`. |
| `session-handoff` | Closing a long session — snapshot state for next time. |
| `project-bootstrap` | New repo — scaffold project state and templates. |

### Quality & discipline
| Skill | Use it when |
|---|---|
| `debug-protocol` | Bug, error, stack trace — Symptom → Root cause → Fix → Why. |
| `tdd-loop` | New functionality with clear I/O — Red → Green → Refactor. |
| `code-review` | Before commit on non-trivial diff — reuse, simplicity, security, dead code. |
| `verify-before-done` | Before declaring a task complete — checklist of tests/behavior/regressions/pulizia. |

### Git
| Skill | Use it when |
|---|---|
| `git-commit` | Stage is ready — drafts conventional-commit message. |
| `git-pr` | Branch is ready — drafts PR title/body/test-plan (no auto-push). |

## Bundled external skills

The installer automatically clones [`anthropics/skills`](https://github.com/anthropics/skills) (shallow) into `~/.claude/external/anthropics-skills/` and symlinks each contained skill (any directory with a `SKILL.md`) into `~/.claude/skills/`. Re-running `./install.sh` does a `git pull --ff-only` to keep them current. Names that collide with local skills are skipped (local wins, with a warning).

To prune the external clone entirely: `./uninstall.sh --purge-external`.

## Subagents

| Agent | Role |
|---|---|
| `code-explorer` | Read-only mapping of code relevant to a query. |
| `test-runner` | Detect and run the project's test command. |
| `doc-writer` | Draft README/doc sections from a spec. |
| `security-scanner` | Audit a diff for OWASP/secrets/injection vulnerabilities (read-only). |
| `pr-reviewer` | Independent second-opinion on a branch/PR diff — verdict approve/nits/changes (read-only). |
| `dependency-mapper` | Impact analysis before refactor: who imports/calls X, where (read-only). |

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
├── skills/<name>/SKILL.md       # one dir per skill (12 total)
├── agents/<name>.md             # one file per subagent
└── templates/                   # seeds copied by project-bootstrap
```

After install, `~/.claude/` looks like:

```
~/.claude/
├── skills/                       # symlinks (local + anthropic)
├── agents/                       # symlinks
├── external/anthropics-skills/   # git clone, updated on each install.sh
├── state/                        # your cross-session memory (untouched on uninstall)
├── settings.json                 # deep-merged from this repo's fragment
└── backups/                      # first-install backup of settings.json
```

## Requirements

- macOS or Linux (Windows requires WSL — native NTFS symlinks are unreliable)
- `python3`, `git`
- Claude Code CLI

## Uninstall

```bash
~/toolkit/uninstall.sh                  # removes symlinks, restores settings.json backup
~/toolkit/uninstall.sh --purge-external # also removes ~/.claude/external/anthropics-skills/
```

Removes only symlinks pointing into the toolkit or into the anthropic clone. Restores `settings.json` from the most recent backup at `~/.claude/backups/pre-toolkit-*`. `~/.claude/state/` is always preserved.
