#!/usr/bin/env bash
#
# install.sh — wire this repo into the live Neovim config via a symlink.
#
# This repo is the source of truth. The live config directory ~/.config/nvim
# is replaced with a symlink pointing into this repo, so edits here are picked
# up by Neovim immediately (most on reload, full config on restart).
#
# Neovim state (installed plugins under ~/.local/share/nvim/lazy, LSP servers
# under ~/.local/share/nvim/mason, caches/undo/etc under ~/.local/state/nvim)
# is never touched — it lives outside ~/.config and is not part of this repo.
#
# Usage:
#   ./install.sh            Link: back up any existing ~/.config/nvim, symlink to this repo
#   ./install.sh --status   Show link status without changing anything
#   ./install.sh --restore  Restore the most recent backup set
#
# Backups go to ~/.lazier-vim-backup/<timestamp>/ with a manifest, never inside
# ~/.config/nvim (Neovim would scan backup copies of lua/ as config).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.config/nvim"
BACKUP_ROOT="$HOME/.lazier-vim-backup"

# ── helpers ──────────────────────────────────────────────────────────────────

warn() { printf '  %s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

# Real nvim binary available? (used for pre-flight checks)
nvim_bin() {
  command -v nvim >/dev/null 2>&1 && printf 'nvim' || true
}

link_health() {
  # 'ok' if TARGET is a symlink to this repo; otherwise echo a short status word.
  if [ -L "$TARGET" ]; then
    local link
    link="$(readlink "$TARGET")"
    if [ "$link" = "$REPO_DIR" ]; then
      printf 'ok'
    else
      printf 'foreign:%s' "$link"
    fi
  elif [ -e "$TARGET" ]; then
    printf 'real'
  else
    printf 'missing'
  fi
}

# ── subcommands ──────────────────────────────────────────────────────────────

do_status() {
  local health
  health="$(link_health)"
  case "$health" in
    ok) info "OK       $TARGET -> $REPO_DIR" ;;
    foreign:*) warn "FOREIGN  $TARGET -> ${health#foreign:} (not this repo — run ./install.sh)" ;;
    real) warn "REAL     $TARGET (a real dir, not linked — run ./install.sh)" ;;
    missing) warn "MISSING  $TARGET (nothing there — run ./install.sh)" ;;
  esac
  info "backups: $( [ -d "$BACKUP_ROOT" ] && ls -d "$BACKUP_ROOT"/*/ 2>/dev/null | wc -l | tr -d ' ' ) set(s) at $BACKUP_ROOT"
}

do_link() {
  local health
  health="$(link_health)"

  if [ "$health" = "ok" ]; then
    info "Already linked: $TARGET -> $REPO_DIR"
    return 0
  fi

  # ── pre-flight: refuse to blow away an active config on a brand-new clone ──
  if [ ! -f "$REPO_DIR/init.lua" ]; then
    warn "ERROR: $REPO_DIR/init.lua not found — this doesn't look like a lazier-vim repo." >&2
    warn "Refusing to proceed." >&2
    return 1
  fi
  # If there's a real ~/.config/nvim that is NOT the LazyVim starter layout and
  # has never been linked, require confirmation before replacing it.
  if [ "$health" = "real" ] || [ "$health" = "foreign" ]; then
    if [ "$health" = "foreign" ] || { [ -d "$TARGET" ] && [ ! -f "$TARGET/init.lua" ]; }; then
      warn "WARNING: $TARGET exists and is not a plain lazier-vim repo target."
      read -r -p "Replace it? (backup to $BACKUP_ROOT first) [y/N] " ans
      case "$ans" in
        y | Y | yes | YES) ;;
        *) info "Aborted."; return 1 ;;
      esac
    fi
  fi

  # ── backup ──
  local stamp backup_path
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_path="$BACKUP_ROOT/$stamp"
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    if [ "$health" = "real" ]; then
      mkdir -p "$backup_path"
      mv "$TARGET" "$backup_path/nvim"
      printf '%s\t%s\n' "$TARGET" "nvim" >>"$backup_path/manifest"
      info "  backed up: $TARGET -> $backup_path/nvim"
    else
      # symlink (foreign) — record and remove; its source lives elsewhere
      rm -f "$TARGET"
      info "  removed foreign symlink: $TARGET"
    fi
  fi

  # ── link ──
  mkdir -p "$(dirname "$TARGET")"
  ln -s "$REPO_DIR" "$TARGET"
  info "  linked: $TARGET -> $REPO_DIR"
  info
  info "Done. ~/.config/nvim now points at $REPO_DIR."
  if [ -n "$(nvim_bin)" ]; then
    info "Open nvim to let lazy.nvim install plugins; run :Lazy to manage updates."
  else
    info "NOTE: 'nvim' not found on PATH — install Neovim, then open it to bootstrap plugins."
  fi
}

do_restore() {
  if [ ! -d "$BACKUP_ROOT" ]; then
    info "No backups found at $BACKUP_ROOT"
    return 0
  fi
  local latest
  latest="$(ls -d "$BACKUP_ROOT"/*/ 2>/dev/null | sort | tail -1)"
  if [ -z "$latest" ] || [ ! -f "$latest/manifest" ]; then
    info "No backup manifest found (latest: $latest)"
    return 0
  fi
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    rm -rf "$TARGET"
    info "  removed current link: $TARGET"
  fi
  while IFS=$'\t' read -r target name; do
    [ -z "$target" ] && continue
    if [ -e "$latest/$name" ]; then
      mkdir -p "$(dirname "$target")"
      mv "$latest/$name" "$target"
      info "  restored: $target"
    else
      warn "  missing backup file for $target (skipped)"
    fi
  done <"$latest/manifest"
  info
  info "Restored from $latest"
  info "NOTE: re-run ./install.sh to re-link, or leave restored for manual use."
}

# ── main ─────────────────────────────────────────────────────────────────────

case "${1:-link}" in
  status | --status) do_status ;;
  link | --link) do_link ;;
  restore | --restore) do_restore ;;
  -h | --help)
    sed -n '2,20p' "$0"
    exit 0
    ;;
  *)
    warn "Unknown option: $1"
    warn "Usage: ./install.sh [link|--link] [status|--status] [restore|--restore]"
    exit 1
    ;;
esac
