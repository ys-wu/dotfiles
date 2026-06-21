# GitHub auth: tools, credentials, and per-repo PATs

Reference notes on how `git`, `gh`, SSH keys, and PATs relate — and how to run
multiple repo-scoped PATs on one machine. (Reference only — never put an actual
`github_pat_…` value in this file or any tracked file.)

## Tools vs. credentials

Two **tools** (things you run):

- **`git`** — version control. Makes commits/branches and transfers them to/from
  a remote. Host-agnostic (GitHub, GitLab, anything). This is the engine.
- **`gh`** — GitHub's CLI. Convenience wrapper for GitHub-specific actions via the
  GitHub API: create repos, open PRs, manage issues. Optional; `git` alone does
  push/pull.

Two **credentials** (ways to prove identity to GitHub):

- **SSH key** — used with `git@github.com:owner/repo.git` (SSH protocol). Public
  key uploaded to GitHub; private key stays on the machine.
- **PAT** — used with `https://github.com/owner/repo.git` (HTTPS). A password
  substitute, typically stored in the macOS keychain.

SSH key and PAT are **alternatives for the same job** — pick one based on the
remote URL scheme. A PAT is just a credential: `git`, `gh`, `curl`, and CI can
all consume it, *if* its scope covers the requested action.

`git` and `gh` do **not** share credentials automatically:

- `git` (HTTPS) reads its PAT from the keychain via the credential helper.
- `gh` reads its own token from `~/.config/gh/hosts.yml` or the `GH_TOKEN` env var.

## Fine-grained PAT for one repo (e.g. sandboxing an AI agent)

A single fine-grained PAT scoped to **one repo** can serve both `git` and `gh`,
confined to that repo. Grant only the permissions the work needs:

| Permission | For | Used by |
|---|---|---|
| Contents: Read/write | clone, commit, push | `git` |
| Pull requests: Read/write | create/update/merge PRs | `gh` / API |
| Metadata: Read (auto) | mandatory baseline | both |
| Workflows: Read/write | only if editing `.github/workflows/` | `git` |
| Issues / Actions / Checks | only if the agent touches them | `gh` |

Share one token across both tools:

```bash
export GH_TOKEN=github_pat_…   # gh reads this
gh auth setup-git              # makes gh git's credential helper → git uses it too
```

The repo-scoping is a real sandbox: the token physically cannot reach other repos
or account settings. Prefer a short expiry for agent/CI environments.

## Multiple PATs for multiple repos on one machine

Problem: by default `git` keys credentials by **host**, so it reuses one PAT for
all `github.com` repos. Break the tie one of three ways:

| Method | How | Token stored | Best for |
|---|---|---|---|
| **A. useHttpPath** | `git config --global credential.https://github.com.useHttpPath true` → keychain keys per repo path | macOS keychain | daily machine |
| **B. URL-embedded** | `git remote set-url origin https://x-access-token:PAT@github.com/owner/repo.git` | repo `.git/config` (plaintext) | isolated / agent sandboxes |
| **C. env var** | `GH_TOKEN` per project (e.g. via direnv) + `gh auth setup-git` | shell env, per dir | agents, CI, ephemeral envs |

Caveat: `gh` authenticates **one token per host**, not per repo — for per-repo
`gh`, swap `GH_TOKEN` per project (Method C). `git` handles per-repo via A or B.

Rule of thumb: isolation scales with risk. One broader token is fine for personal
work; reach for per-repo PATs when sandboxing agents, shared machines, or
untrusted environments.

## PAT hygiene

- One token per purpose/machine, so revocation is surgical.
- Least privilege: fine-grained over classic; scope to specific repos + minimal
  permissions.
- Expiry is the safer default; never-expiry is acceptable only for low-value,
  narrowly-scoped tokens.
- Never commit a token or paste it into a tracked file (keychain / 1Password /
  credential helper only).
- Name tokens descriptively; audit and revoke stale ones periodically.

## This machine's current setup

- `git` + HTTPS remote + fine-grained, repo-scoped, never-expiring PAT in the
  macOS keychain. `credential.https://github.com.useHttpPath = true` (Method A).
- `gh` is installed but **not** authenticated.
- No SSH key in use for GitHub.
