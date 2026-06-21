#!/bin/bash
# Install Homebrew if it isn't already present.
# run_once_  -> runs a single time per machine (tracked by content hash)
# before_    -> runs before dotfiles are applied
# 00         -> orders this ahead of the brew-bundle script (10)
set -euo pipefail

if command -v brew >/dev/null 2>&1 || [ -x /opt/homebrew/bin/brew ] || [ -x /usr/local/bin/brew ]; then
  echo "Homebrew already installed — skipping."
  exit 0
fi

echo "Installing Homebrew (non-interactive)..."
NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
