#!/usr/bin/env bash
# Regenerate published OpenPGP artifacts from an exported public key.
# Usage: ./update-key.sh <public-key.asc>
# Writes:
#   pgp-key.asc                                          (armored, for the download link)
#   .well-known/openpgpkey/hu/<hash>                     (binary, minimized, for WKD)
set -euo pipefail

SRC="${1:?usage: ./update-key.sh <public-key.asc>}"
# FPR: pinned primary fingerprint — we export exactly this key so a stray/extra key
#      in the input can never be published. Only changes on a primary-key rotation.
FPR="F7F3427AFA307FB717CB86AFD321F15B02224094"
# WKD_HASH: z-base32 SHA-1 of the local-part "alexey" — a fixed constant for that address.
WKD_HASH="5zfqd795m5k3ao3sxk8gue3fox6uj9zy"
WKD_FILE=".well-known/openpgpkey/hu/${WKD_HASH}"

TMP="$(mktemp -d)"
chmod 700 "$TMP"
trap 'rm -rf "$TMP"' EXIT
export GNUPGHOME="$TMP"

gpg --quiet --import "$SRC"

# Fail fast if the input doesn't actually contain the expected key
# (otherwise gpg --export would silently write empty artifacts).
gpg --list-keys "$FPR" >/dev/null 2>&1 || {
  echo "ERROR: $SRC does not contain key $FPR" >&2; exit 1
}

# Armored full key for the human-facing download link.
gpg --quiet --armor --export "$FPR" > pgp-key.asc

# Minimized binary key for WKD (direct method).
mkdir -p "$(dirname "$WKD_FILE")"
gpg --quiet --export-options export-minimal --export "$FPR" > "$WKD_FILE"

echo "Wrote pgp-key.asc ($(wc -c < pgp-key.asc) bytes)"
echo "Wrote ${WKD_FILE} ($(wc -c < "$WKD_FILE") bytes)"
