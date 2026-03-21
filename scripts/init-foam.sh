#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if [ -n "${1:-}" ]; then
  VAULT_NAME="$1"
else
  read -rp "Vault name: " VAULT_NAME
fi
VAULT_NAME="${VAULT_NAME//[[:space:]]/_}"
if [ -z "$VAULT_NAME" ]; then
  echo "Vault name cannot be empty." >&2
  exit 1
fi

if [ -n "${2:-}" ]; then
  PARENT_DIR="$2"
else
  read -rp "Parent directory (leave blank for current directory): " PARENT_DIR
fi
PARENT_DIR="${PARENT_DIR:-$(pwd)}"

VAULT_ROOT="${PARENT_DIR}/${VAULT_NAME}"

if [ -e "$VAULT_ROOT" ]; then
  echo "Directory already exists: $VAULT_ROOT" >&2
  exit 1
fi

mkdir -p "$VAULT_ROOT"

runtime_dirs=(
  inbox notes facts metrics people
  sources clusters journal attachments
  private scratch cache temp exports archive
)

for rel in "${runtime_dirs[@]}"; do
  mkdir -p "${VAULT_ROOT}/${rel}"
done

# Copy templates and prompts from repo
for src in templates prompts; do
  [ -d "${REPO_ROOT}/${src}" ] && cp -r "${REPO_ROOT}/${src}" "${VAULT_ROOT}/${src}"
done

# Copy CLAUDE_FOAM.md into vault as both CLAUDE.md and AGENTS.md
if [ -f "${REPO_ROOT}/CLAUDE_FOAM.md" ]; then
  cp "${REPO_ROOT}/CLAUDE_FOAM.md" "${VAULT_ROOT}/CLAUDE.md"
  cp "${REPO_ROOT}/CLAUDE_FOAM.md" "${VAULT_ROOT}/AGENTS.md"
fi

echo "Vault '$VAULT_NAME' created at $VAULT_ROOT"
