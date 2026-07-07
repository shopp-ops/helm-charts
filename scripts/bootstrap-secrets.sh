#!/usr/bin/env bash
#
# Creates the Kubernetes Secrets that must be provisioned out-of-band (never
# committed to Git). Flux/Helm consume them at deploy time:
#
#   shophub-secrets        (ns shophub)                -> api.jwtSecret + database.password
#   shop-operator-discord  (ns shop-operator-system)   -> Discord bot token + guild id
#
# jwtSecret and the DB password are generated randomly. The Discord values cannot
# be generated — pass them via env (skipped if unset, since Discord is optional).
#
# Usage:
#   ./bootstrap-secrets.sh
#   DISCORD_BOT_TOKEN=xxx DISCORD_GUILD_ID=123 ./bootstrap-secrets.sh
#   JWT_SECRET=... DB_PASSWORD=... ./bootstrap-secrets.sh   # override generated values
#
set -euo pipefail

command -v kubectl >/dev/null || { echo "kubectl not found" >&2; exit 1; }

rand() { openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 40; }

JWT_SECRET="${JWT_SECRET:-$(rand)}"
DB_PASSWORD="${DB_PASSWORD:-$(rand)}"
DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
DISCORD_GUILD_ID="${DISCORD_GUILD_ID:-}"

apply() { kubectl apply -f - ; }
ensure_ns() { kubectl create namespace "$1" --dry-run=client -o yaml | apply >/dev/null; }

# --- shophub ---------------------------------------------------------------
ensure_ns shophub
kubectl create secret generic shophub-secrets -n shophub \
  --from-literal=values.yaml="$(cat <<EOF
api:
  jwtSecret: "${JWT_SECRET}"
database:
  password: "${DB_PASSWORD}"
EOF
)" \
  --dry-run=client -o yaml | apply >/dev/null
echo "ok  shophub/shophub-secrets (jwtSecret + database.password)"

# --- shop-operator Discord bot --------------------------------------------
if [[ -n "$DISCORD_BOT_TOKEN" && -n "$DISCORD_GUILD_ID" ]]; then
  ensure_ns shop-operator-system
  kubectl create secret generic shop-operator-discord -n shop-operator-system \
    --from-literal=bot-token="$DISCORD_BOT_TOKEN" \
    --from-literal=guild-id="$DISCORD_GUILD_ID" \
    --dry-run=client -o yaml | apply >/dev/null
  echo "ok  shop-operator-system/shop-operator-discord (bot-token + guild-id)"
else
  echo "skip shop-operator-discord: set DISCORD_BOT_TOKEN and DISCORD_GUILD_ID to create it"
fi
