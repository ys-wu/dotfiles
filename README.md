# dotfiles

Personal **macOS** dotfiles managed with [chezmoi](https://www.chezmoi.io) and backed up to a
public GitHub repo (`ys-wu/dotfiles`). chezmoi keeps a source copy of each file here
and *applies* it into `$HOME` — no symlinks.

No secrets are tracked here (see [What's NOT tracked](#whats-not-tracked-and-why)) — that's
what makes it safe to keep public.

## What's tracked

| File | Purpose |
|------|---------|
| `dot_zshrc` → `~/.zshrc` | Zsh config |
| `dot_p10k.zsh` → `~/.p10k.zsh` | Powerlevel10k prompt |
| `dot_tmux.conf` → `~/.tmux.conf` | tmux config (prefix `C-b`, vi copy-mode, plugins via TPM) |
| `dot_config/ghostty/config` → `~/.config/ghostty/config` | Ghostty terminal |
| `dot_config/nvim/` → `~/.config/nvim/` | Neovim, configured with [LazyVim](https://www.lazyvim.org) (starter template + `lazy-lock.json` plugin lockfile); tutorial: [LazyVim for Ambitious Devs](https://lazyvim-ambitious-devs.phillips.codes/course/) |
| `dot_claude/settings.json` → `~/.claude/settings.json` | Claude Code settings |
| `dot_gitconfig` → `~/.gitconfig` | Git config (credential helper, `useHttpPath`, default branch) |
| `…/Code/User/settings.json` → VSCode user settings | Editor, integrated-terminal font (Nerd Font), Vim mode (VSCodeVim) |

chezmoi maps `dot_` prefixes to leading dots. List managed files with `chezmoi managed`.

### tmux plugins (chezmoi externals, not `prefix + I`)

`.chezmoiexternal.toml` clones three repos into `~/.tmux/plugins/` on apply, so a fresh
machine needs no TPM bootstrap step:

| Plugin | What it gives you |
|--------|-------------------|
| [tpm](https://github.com/tmux-plugins/tpm) | the plugin loader `~/.tmux.conf` sources on its last line |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | save/restore sessions, windows, panes: `C-b C-s` / `C-b C-r` |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | auto-saves every 15 min and auto-restores when tmux starts |

The repos are clones, not tracked content, so nothing third-party lands in this git repo.
chezmoi re-pulls them at most weekly; force it with `chezmoi apply --refresh-externals`.
Resurrect's snapshots live in `~/.local/share/tmux/resurrect/` and are `.chezmoiignore`d as
machine-local state. Adding a plugin means two edits: a `set -g @plugin` line in
`dot_tmux.conf` **and** a block in `.chezmoiexternal.toml` (keep `tmux-continuum` last in
the plugin list, as it requires).

### Claude Code's `model` key is deliberately absent

`dot_claude/settings.json` has no `"model"` entry (removed in `8e7e22d`): model aliases
change over time and the right choice is per-session, so selection is left to `/model`.

Claude Code rewrites `~/.claude/settings.json` itself, and `/model` persists the choice
there, so the key **will** be present on a machine you've used. That is intentional: the
pin is machine-local state, so it stays in `$HOME` and out of the repo. The cost is a
standing `-  "model": ...` line in `chezmoi diff`. It is expected, not accidental drift,
and there is nothing to fix:

- **Do not** `chezmoi add` the pin back. That re-bakes a model choice into every machine,
  which is exactly what `8e7e22d` undid.
- **Do not** blanket `chezmoi apply`, since it strips the live pin as a side effect. Apply
  specific paths (`chezmoi apply ~/.zshrc`) when other files drift.

Suppressing the line permanently would need a `modify_` script (chezmoi's only
part-of-a-file mechanism), traded away to keep a literal, reviewable settings file.

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
# 1. install chezmoi (e.g. via the standalone installer — no brew needed yet):
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ys-wu
```

On first apply, two scripts bootstrap the machine **before** dotfiles are written:

| Script | Prefix meaning | Does |
|--------|----------------|------|
| `run_once_before_00-install-homebrew.sh` | run once, before | installs Homebrew if missing (`NONINTERACTIVE=1`) |
| `run_onchange_before_10-brew-bundle.sh.tmpl` | re-run on change, before | runs `brew bundle` against `Brewfile` |
| `run_once_after_20-install-claude-code.sh` | run once, after | installs Claude Code via its native installer (see below) |
| `run_once_after_30-macos-defaults.sh` | run once, after | applies macOS `defaults` (disables the press-and-hold accent popup) |

`Brewfile` lists all packages/casks (regenerate with `brew bundle dump --force`). The
bundle script embeds the Brewfile's hash, so it re-runs only when the package list changes.
`00`/`10`/`20` ordering guarantees Homebrew is installed before `brew bundle`, which runs
before the Claude Code install.

### Deliberately *not* in the Brewfile, and why

The deciding factor is **self-updating vs. not**, not "downloaded vs. brew." Apps with their
own auto-updaters keep updating themselves no matter how they were installed, and a brew cask
can then fight the app's built-in updater (brew thinks it's stale; the app already updated).

- **Claude Code** — a `claude-code` cask exists, but Claude Code self-updates and the
  **native installer is the recommended channel**. It's installed by
  `run_once_after_20-install-claude-code.sh` (`curl … claude.ai/install.sh`), kept out of the
  Brewfile on purpose so its updater isn't fought by brew.
- **Chrome, Claude desktop** — available as casks (`google-chrome`, `claude`) but left out;
  they self-update aggressively. Add them only if fresh-machine convenience outweighs the
  brew-vs-self-updater noise. Low stakes either way.

In the Brewfile (low-conflict, no aggressive self-updater, clean from brew): `1password`,
`1password-cli`, `shottr`.

- **uv** has a built-in `uv self update`, but the Homebrew build disables it, so there's no
  updater conflict: upgrade with `brew upgrade uv`. Kept in the Brewfile since it's also the
  Python-version manager here (`uv python install`), i.e. no separate `python`/`pyenv` entry.

> Note: `chezmoi apply` / `chezmoi update` on an existing machine will run the bundle
> script when the Brewfile changes — this is idempotent (brew just installs what's missing).

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

This setting (and `credential.helper`, `init.defaultBranch`) lives in `~/.gitconfig`, which is
tracked here — so `chezmoi init --apply ys-wu` restores this git behavior on a new machine too.
The PAT itself is **not** in `.gitconfig` (it's in the keychain), so nothing secret is committed.

## PAT management

- The token lives in the macOS keychain; keep a backup copy in a password manager and
  delete any plaintext copies.
- **Least privilege:** fine-grained, single-repo, minimal permissions.
- **One token per repo/machine** so revocation is surgical.
- **Revoke immediately** if a machine is lost/compromised:
  GitHub → Settings → Developer settings → Fine-grained tokens → Revoke.
- Audit occasionally via the token list's "last used" timestamps.
