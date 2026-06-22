#!/bin/bash
# Apply macOS system defaults.
# run_once_ -> runs a single time per machine (tracked by content hash);
#              edit this file to re-trigger on the next apply.
# after_    -> runs after dotfiles are applied
# 30        -> ordered after the brew (00/10) and Claude Code (20) scripts
set -euo pipefail

# Disable the press-and-hold accent popup globally, so holding a key repeats it
# (e.g. j/k in Vim-mode editors) instead of showing the accent menu.
# Trade-off: type accented characters via Option-key combos instead.
# Apps read this at launch — restart apps (or log out/in) for it to take effect.
defaults write -g ApplePressAndHoldEnabled -bool false

echo "macOS defaults applied. Restart apps (or log out/in) for changes to take effect."
