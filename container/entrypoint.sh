#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Installing Microsoft ODBC"
if /app/odbc.sh; then
  echo "[entrypoint] Installation Of ODBC drivers done."
else
  echo "[entrypoint] Installation Of ODBC drivers failed; continuing anyway." >&2
fi

echo "[entrypoint] Building server"
cd /app/src
go mod tidy
go build -o /app/server ./api/cmd/server
echo "[entrypoint] build complete."

echo "[entrypoint] starting container…"

# az login
if [[ -n "${AZ_CLIENT_ID:-}" && -n "${AZ_CLIENT_SECRET:-}" && -n "${AZ_TENANT_ID:-}" ]]; then
  echo "[entrypoint] az login (service principal)…"
  az login --service-principal \
    -u "$AZ_CLIENT_ID" \
    -p "$AZ_CLIENT_SECRET" \
    --tenant "$AZ_TENANT_ID" >/dev/null
  if [[ -n "${AZ_SUBSCRIPTION_ID:-}" ]]; then
    az account set --subscription "$AZ_SUBSCRIPTION_ID"
  fi
else
  echo "[entrypoint] AZ_* envs not set; skipping az login."
fi

#get aks creds and set context
if [[ -n "${CLUSTER_RG:-}" && -n "${CLUSTER_NAME:-}" ]]; then
  echo "Setting context for '$CLUSTER_NAME' "
  az aks get-credentials --resource-group $CLUSTER_RG --name $CLUSTER_NAME --overwrite-existing --admin
else
  echo "[entrypoint] CLUSTER_* envs not set; skipping aks"
fi

# Update builtin vars into /root/.holmes/config.yaml
echo "[entrypoint] updating holmes config via update_builtin_vars.sh…"
if /app/update_builtin_vars.sh; then
  echo "[entrypoint] update_builtin_vars.sh done."
else
  echo "[entrypoint] update_builtin_vars.sh failed; continuing anyway." >&2
fi

# Refresh holmes toolset 
echo "[entrypoint] holmes toolset refresh…"
if command -v holmes >/dev/null 2>&1; then
  holmes toolset refresh || true
else
  echo "[entrypoint] holmes CLI not found in PATH?" >&2
fi

# supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf
