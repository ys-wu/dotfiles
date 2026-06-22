#!/bin/bash
# Install Claude Code via the official native installer (NOT Homebrew).
# Claude Code self-updates, so the native installer is the recommended channel —
# a brew cask would fight its built-in updater. Kept out of the Brewfile on purpose.
# run_once_ -> runs a single time per machine (tracked by content hash)
# after_    -> runs after dotfiles are applied
# 20        -> ordered after the brew scripts (00/10)
set -euo pipefail

if command -v claude >/dev/null 2>&1; then
  echo "Claude Code already installed — skipping."
  exit 0
fi

echo "Installing Claude Code (native installer)..."
curl -fsSL https://claude.ai/install.sh | bash
