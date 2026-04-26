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

curl -fsSL "$BASE/pgm"              -o "$tmp/pgm"
curl -fsSL "$BASE/pgm.conf.example" -o "$tmp/pgm.conf.example"

install -m 755 "$tmp/pgm"               "$PREFIX/pgm"
install -d -m 755                       "$CONFDIR"
install -m 644 "$tmp/pgm.conf.example"  "$CONFDIR/pgm.conf.example"

cat <<EOF
Installed:
  $PREFIX/pgm
  $CONFDIR/pgm.conf.example

Run:  pgm help
EOF
