#!/usr/bin/env bash
set -euo pipefail

# Read env
cluster_rg="${CLUSTER_RG:-}"
cluster="${CLUSTER_NAME:-}"
subscription_id="${AZ_SUBSCRIPTION_ID:-}"
tenant_id="${AZ_TENANT_ID:-}"
client_id="${AZ_CLIENT_ID:-}"
client_secret="${AZ_CLIENT_SECRET:-}"
rmq_user="${RMQ_USER:-}"
rmq_password="${RMQ_PASSWORD:-}"
rmq_uri="${RMQ_URI:-}"
config_file="/root/.holmes/config.yaml"

#set sub
if [[ -n "$subscription_id" ]]; then
  az account set --subscription "$subscription_id" || true
fi

sqlserver_name=$(az sql server list --resource-group $cluster_rg --query "[0].name" -o tsv)
sqldb_name=$(az sql db list --resource-group $cluster_rg --server $sqlserver_name --query "[?contains(name, 'FCx') || contains(name, 'GCx') || contains(name, 'SFx')].name" -o tsv)

# Patch config using yq v4
# AKS Node Health
yq -i 'select(.toolsets."aks/node-health".config.cluster_name) | .toolsets."aks/node-health".config.cluster_name = "'"${cluster}"'"' "$config_file"
yq -i 'select(.toolsets."aks/node-health".config.resource_group) | .toolsets."aks/node-health".config.resource_group = "'"${cluster_rg}"'"' "$config_file"
yq -i 'select(.toolsets."aks/node-health".config.subscription_id) | .toolsets."aks/node-health".config.subscription_id = "'"${subscription_id}"'"' "$config_file"

# AKS Core
yq -i 'select(.toolsets."aks/core".config.cluster_name) | .toolsets."aks/core".config.cluster_name = "'"${cluster}"'"' "$config_file"
yq -i 'select(.toolsets."aks/core".config.resource_group) | .toolsets."aks/core".config.resource_group = "'"${cluster_rg}"'"' "$config_file"
yq -i 'select(.toolsets."aks/core".config.subscription_id) | .toolsets."aks/core".config.subscription_id = "'"${subscription_id}"'"' "$config_file"

# Azure SQL
yq -i 'select(.toolsets."azure/sql".config.tenant_id) | .toolsets."azure/sql".config.tenant_id = "'"${tenant_id}"'"' "$config_file"
yq -i 'select(.toolsets."azure/sql".config.client_id) | .toolsets."azure/sql".config.client_id = "'"${client_id}"'"' "$config_file"
yq -i 'select(.toolsets."azure/sql".config.client_secret) | .toolsets."azure/sql".config.client_secret = "'"${client_secret}"'"' "$config_file"
yq -i 'select(.toolsets."azure/sql".config.database.subscription_id) | .toolsets."azure/sql".config.database.subscription_id = "'"${subscription_id}"'"' "$config_file"
yq -i 'select(.toolsets."azure/sql".config.database.resource_group) | .toolsets."azure/sql".config.database.resource_group = "'"${cluster_rg}"'"' "$config_file"
yq -i 'select(.toolsets."azure/sql".config.database.server_name) | .toolsets."azure/sql".config.database.server_name = "'"${sqlserver_name}"'"' "$config_file"
yq -i 'select(.toolsets."azure/sql".config.database.database_name) | .toolsets."azure/sql".config.database.database_name = "'"${sqldb_name}"'"' "$config_file"

#RabbitMQ
yq -i '.toolsets."rabbitmq/core".config.clusters[0].username = "'"${rmq_user}"'"' "$config_file"
yq -i '.toolsets."rabbitmq/core".config.clusters[0].password = "'"${rmq_password}"'"' "$config_file"
yq -i '.toolsets."rabbitmq/core".config.clusters[0].management_url = "'"${rmq_uri}"'"' "$config_file"

echo "[update_builtin_vars] config patched."