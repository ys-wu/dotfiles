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
| `dot_config/private_karabiner/karabiner.json` → `~/.config/karabiner/karabiner.json` | Karabiner-Elements (dual-purpose Caps Lock, see below) |
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

### Caps Lock: tap for Escape, hold for Control

`dot_config/private_karabiner/karabiner.json` defines one complex modification. Tapped,
Caps Lock posts `escape`; held, it acts as `left_control`. Caps-locking itself is given up,
which is the point.

Why Karabiner and not macOS System Settings: the built-in *Modifier Keys* panel can only
map Caps Lock to Control *permanently*, with no tap behavior. Only a Karabiner complex
modification can make one key dual-purpose.

How the rule works, key by key:

- `to` + `"lazy": true` holds the Control keydown back until another key is pressed, so a
  bare Caps Lock tap never leaks a stray Control to the frontmost app.
- `to_if_held_down` re-posts Control after the threshold, which is what makes Control-click
  and Control-scroll work (lazy alone would wait forever for a keypress that never comes).
- Both thresholds are 200 ms: press-and-release under 200 ms is Escape, anything longer is
  Control. Karabiner's own default for `to_if_alone` is 1000 ms, which is long enough that
  a deliberate hold still fires Escape on release. Tune both numbers together, and keep
  them equal, so the tap/hold boundary stays a single point in time.
- `"modifiers": { "optional": ["any"] }` keeps the rule live while other modifiers are
  already down, so `⌘⇧`-plus-Caps-Lock still yields Control.

The config is minimal on purpose: Karabiner fills in every key it does not find (profiles,
devices, function-key rows, `simple_modifications`) *in memory*, and verifiably does not
write those defaults back, so only the rule that matters is tracked. Changing something in
the GUI does rewrite the file in full, expanded form, which would show up as a large
`chezmoi diff`. Prefer editing this file over clicking in the GUI; if you do use the GUI
and want to keep the result, `chezmoi add ~/.config/karabiner/karabiner.json` and review
the diff before committing. Karabiner watches the file and reloads on save, so a
`chezmoi apply` takes effect immediately, with no restart.

The source dir is `private_karabiner`, i.e. mode `0700`, because Karabiner chmods
`~/.config/karabiner` to `0700` on first launch. Without the `private_` attribute, chezmoi
would want it `0755` and every `chezmoi diff` would carry a permanent mode-change hunk.

`automatic_backups/` (Karabiner's own snapshot of each GUI change) is `.chezmoiignore`d as
machine-local state. `assets/` (created on first launch, for downloaded rule files) is
left unmanaged.

Validate an edit before applying it, with Karabiner's own linter:

```bash
KCLI='/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'
"$KCLI" --list-profile-names   # non-zero if ~/.config/karabiner/karabiner.json won't parse
```

**First run on a new machine** needs three GUI approvals that no config file can grant, in
this order. Running `open -a Karabiner-Elements` is the least painful route: its settings
window guides each step with a button that opens the right pane.

1. System Settings → General → Login Items & Extensions → **Driver Extensions**, enable
   *Karabiner-VirtualHIDDevice*.
2. Privacy & Security → **Accessibility** → allow `Karabiner-Elements` and
   `Karabiner-Core-Service`.
3. Privacy & Security → **Input Monitoring** → same two (v16 names it Core Service, older
   docs say `karabiner_grabber`).

Also set System Settings → Keyboard → Keyboard Shortcuts → **Modifier Keys** → Caps Lock
back to `Caps Lock` if it has been remapped. A macOS-level Caps Lock → Escape remap looks
like a *partly* working setup (tap gives Escape, hold gives Escape too) and is easy to
mistake for a broken Karabiner rule, since macOS has no notion of tap vs hold. That pane is
**per keyboard**: work through every device in its "Select keyboard" dropdown, not just the
one it happens to open on. Audit them all at once instead:

```bash
defaults -currentHost read -g | grep -A20 modifiermapping
```

Each device gets its own block. `Src` 30064771129 (`0x700000039`) is Caps Lock; if its
`Dst` is 30064771113 (`0x700000029`, Escape) rather than itself, that device is remapped.
Stale blocks for keyboards that are no longer attached are normal and harmless, and one
keyboard can appear twice if it connects both over Bluetooth and via a USB receiver.

`keyboard_type_v2` is set in the tracked config on purpose. Karabiner refuses to finish
setup until a keyboard type is chosen, and choosing it in the GUI rewrites `karabiner.json`
in expanded form; setting it in the file clears the same flag with no click. It applies to
Karabiner's single *virtual* keyboard (every physical keyboard funnels into it), so it is
profile-wide with no per-device override. It does not affect the Caps Lock rule: Caps Lock
is usage `0x39` on ANSI, ISO, and JIS alike. Only genuinely layout-specific keys care
(`non_us_backslash` on ISO; `kana`/`eisuu`/`yen` on JIS), and for those the tools are
separate profiles or `device_if` conditions.

Diagnose all of the above in one shot, rather than guessing which step is outstanding:

```bash
"$KCLI" --show-settings-window-guidance
```

`current_setup` names the step still blocking; `accessibility_process_trusted` and
`iohid_listen_event_allowed` must both be `true` before any rule fires; and
`karabiner_json_parse_error_message` is empty when this repo's config is valid, which
separates a permissions problem from a config problem. Before the driver is approved,
`--list-connected-devices` hangs rather than returning an error.

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
`1password-cli`, `shottr`, `karabiner-elements`.

- **Karabiner-Elements** self-updates, and the cask is marked `auto_updates`, so
  `brew upgrade` deliberately skips it (`--greedy` would override, don't bother). It is in
  the Brewfile anyway, as the exception that proves the rule: it installs a *system driver
  extension* via a `.pkg`, which is the one install worth automating on a fresh machine
  even though the approval that follows is manual regardless. brew does the first install;
  the app handles upgrades from then on. Because it is a `.pkg`, `brew bundle` will prompt
  for a sudo password on a fresh machine, so that run cannot be fully unattended.

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
