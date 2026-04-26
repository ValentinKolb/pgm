#!/usr/bin/env bash
# pgm installer — download + install. Idempotent. Designed for `curl | bash`.
set -euo pipefail

REPO="${PGM_REPO:-valentinkolb/pgm}"
REF="${PGM_REF:-main}"
PREFIX="${PGM_PREFIX:-/usr/local/bin}"
CONFDIR="${PGM_CONFDIR:-/etc/pgm}"
BASE="https://raw.githubusercontent.com/$REPO/$REF"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Cache-buster query string — GitHub's raw CDN caches for 5 min, which
# bites when re-installing right after a push.
cb="?cb=$(date +%s)"
curl -fsSL "$BASE/pgm$cb"              -o "$tmp/pgm"
curl -fsSL "$BASE/pgm.conf.example$cb" -o "$tmp/pgm.conf.example"

install -m 755 "$tmp/pgm"               "$PREFIX/pgm"
install -d -m 755                       "$CONFDIR"
install -m 644 "$tmp/pgm.conf.example"  "$CONFDIR/pgm.conf.example"

# `sudo pgm` only works if pgm is in sudoers' `secure_path`. RHEL/Fedora's
# default secure_path is `/sbin:/bin:/usr/sbin:/usr/bin`, excluding
# /usr/local/bin. Drop a symlink in /usr/sbin so `sudo pgm` works anywhere.
symlink_line=""
if ln -sf "$PREFIX/pgm" /usr/sbin/pgm 2>/dev/null; then
    symlink_line="
  /usr/sbin/pgm  (symlink — so 'sudo pgm' works on RHEL/Fedora)"
fi

cat <<EOF
Installed:
  $PREFIX/pgm
  $CONFDIR/pgm.conf.example$symlink_line

Run:  pgm help
EOF
