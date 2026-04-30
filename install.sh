#!/usr/bin/env bash
#
# hermes-spawn installer
#
# Downloads the hermes-spawn script to /usr/local/bin and makes it executable.
# Re-run the same command to update: an existing /usr/local/bin/hermes-spawn is overwritten.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/oscarfrank/hermes-spawn/main/install.sh | bash
#

set -euo pipefail

REPO="oscarfrank/hermes-spawn"
BRANCH="main"
SCRIPT_NAME="hermes-spawn"
INSTALL_PATH="/usr/local/bin/${SCRIPT_NAME}"
SCRIPT_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${SCRIPT_NAME}"

# --- preflight ------------------------------------------------------------
if ! command -v curl &>/dev/null; then
  echo "Error: curl is not installed. Install it first." >&2
  exit 1
fi

# pick sudo or not depending on whether we can write to /usr/local/bin
if [[ -w "$(dirname "$INSTALL_PATH")" ]]; then
  SUDO=""
else
  if ! command -v sudo &>/dev/null; then
    echo "Error: cannot write to $(dirname "$INSTALL_PATH") and sudo is not available." >&2
    exit 1
  fi
  SUDO="sudo"
fi

# --- warn on overwrite ----------------------------------------------------
if [[ -e "$INSTALL_PATH" ]]; then
  echo ">> $INSTALL_PATH already exists. Overwriting with the latest version."
fi

# --- download -------------------------------------------------------------
echo ">> Downloading $SCRIPT_NAME from $SCRIPT_URL"
$SUDO curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"
$SUDO chmod +x "$INSTALL_PATH"

# --- verify ---------------------------------------------------------------
if ! command -v "$SCRIPT_NAME" &>/dev/null; then
  echo "Warning: $SCRIPT_NAME installed at $INSTALL_PATH but not on PATH." >&2
  echo "         You may need to add /usr/local/bin to your PATH." >&2
  exit 1
fi

cat <<EOF

✓ $SCRIPT_NAME installed at $INSTALL_PATH

Quick start:
  hermes-spawn <name>        # e.g. hermes-spawn hermes
  source ~/.bashrc           # activate the new alias
  <name>                     # chat with your instance
  hermes-spawn remove <name>  # when done: container, data, and ~/.bashrc cleanup

Docs: https://github.com/${REPO}

EOF
