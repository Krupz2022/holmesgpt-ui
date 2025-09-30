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
yq -i '.toolsets."aks/node-health".config.cluster_name = strenv(cluster)' "$config_file"
yq -i '.toolsets."aks/node-health".config.resource_group = strenv(cluster_rg)' "$config_file"
yq -i '.toolsets."aks/node-health".config.subscription_id = strenv(subscription_id)' "$config_file"

# AKS Core
yq -i '.toolsets."aks/core".config.cluster_name = strenv(cluster)' "$config_file"
yq -i '.toolsets."aks/core".config.resource_group = strenv(cluster_rg)' "$config_file"
yq -i '.toolsets."aks/core".config.subscription_id = strenv(subscription_id)' "$config_file"

# Azure SQL
yq -i '.toolsets."azure/sql".config.tenant_id = strenv(tenant_id)' "$config_file"
yq -i '.toolsets."azure/sql".config.client_id = strenv(client_id)' "$config_file"
yq -i '.toolsets."azure/sql".config.client_secret = strenv(client_secret)' "$config_file"
yq -i '.toolsets."azure/sql".config.database.subscription_id = strenv(subscription_id)' "$config_file"
yq -i '.toolsets."azure/sql".config.database.resource_group = strenv(cluster_rg)' "$config_file"
yq -i '.toolsets."azure/sql".config.database.server_name = strenv(sqlserver_name)' "$config_file"
yq -i '.toolsets."azure/sql".config.database.database_name = strenv(sqldb_name)' "$config_file"

# RabbitMQ
yq -i '.toolsets."rabbitmq/core".config.clusters[0].user = strenv(rmq_user)' "$config_file"
yq -i '.toolsets."rabbitmq/core".config.clusters[0].password = strenv(rmq_password)' "$config_file"
yq -i '.toolsets."rabbitmq/core".config.clusters[0].management_url = strenv(rmq_uri)' "$config_file"

echo "[update_builtin_vars] config patched."