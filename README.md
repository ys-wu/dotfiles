# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io) and backed up to a
private GitHub repo (`ys-wu/dotfiles`). chezmoi keeps a source copy of each file here
and *applies* it into `$HOME` — no symlinks.

## What's tracked

| File | Purpose |
|------|---------|
| `dot_zshrc` → `~/.zshrc` | Zsh config |
| `dot_p10k.zsh` → `~/.p10k.zsh` | Powerlevel10k prompt |
| `dot_tmux.conf` → `~/.tmux.conf` | tmux config |
| `dot_config/ghostty/config` → `~/.config/ghostty/config` | Ghostty terminal |
| `dot_claude/settings.json` → `~/.claude/settings.json` | Claude Code settings |

chezmoi maps `dot_` prefixes to leading dots. List managed files with `chezmoi managed`.

## What's NOT tracked, and why

Secrets and noisy machine-local state are **excluded** (not encrypted) via `.chezmoiignore`:

- **Secrets** — SSH keys (`.ssh/id_*`, `*.pem`), `.claude.json` (may hold tokens),
  `*.key`, `.aws/credentials`, `.netrc`. These never leave the machine.
- **Noise** — shell history, caches, sockets, and Claude's `cache/`, `sessions/`,
  `projects/`, `history.jsonl`, etc.

`.chezmoiignore` is a guardrail: even an accidental `chezmoi add` of a matched path is refused.
**Habit:** run `chezmoi diff` (or `git diff`) before every push — pushes are manual on purpose,
so this is the review step that keeps secrets out of git history.

## Daily workflow

```bash
chezmoi add ~/.somefile     # track a new file (or pick up edits to a tracked one)
chezmoi cd                  # cd into this source repo (~/.local/share/chezmoi)
chezmoi diff                # review before committing
git add -A && git commit -m "..." && git push
```

No auto-commit / auto-push — pushing is always a deliberate, reviewed step.

## Restore on a new machine

```bash
# 1. install chezmoi (e.g. `brew install chezmoi`)
# 2. pull + apply in one shot:
chezmoi init --apply ys-wu
```

## Auth model (HTTPS + repo-scoped PAT)

This repo authenticates over **HTTPS** using a **fine-grained, repo-scoped Personal
Access Token** (Contents: read/write, scoped to this repo only), stored in the macOS
keychain via the `osxkeychain` credential helper. Not using SSH keys or the `gh` CLI.

### Multiple repo-scoped PATs on one machine

By default git keys credentials by **host** (`github.com`), so one PAT would be reused
for every repo under the account. To allow a **separate repo-scoped PAT per repo**, this
machine has:

```bash
git config --global credential.https://github.com.useHttpPath true
```

Now git keys credentials by full path (`github.com/ys-wu/dotfiles`), so each repo carries
its own PAT. For a new repo: create a PAT scoped to it, then the first `git push` prompts
for username + that repo's PAT (paste the token as the password); subsequent pushes are silent.

## PAT management

- The token lives in the macOS keychain; keep a backup copy in a password manager and
  delete any plaintext copies.
- **Least privilege:** fine-grained, single-repo, minimal permissions.
- **One token per repo/machine** so revocation is surgical.
- **Revoke immediately** if a machine is lost/compromised:
  GitHub → Settings → Developer settings → Fine-grained tokens → Revoke.
- Audit occasionally via the token list's "last used" timestamps.
