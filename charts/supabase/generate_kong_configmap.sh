#!/bin/sh

set -eu

ANON_KEY=$(kubectl -n supabase get secret jwt -o jsonpath='{.data.anon_key}' | base64 --decode)
SERVICE_KEY=$(kubectl -n supabase get secret jwt -o jsonpath='{.data.service_key}' | base64 --decode)

if [[ "$ANON_KEY" == "" || "$SERVICE_KEY" == "" ]]; then
  echo -e "Secret \e[1mjwt\e[0m with values \e[3manon_key\e[0m and \e[3mservice_key\e[0m was not found in namespace supabase"
  exit 1
fi

k8s_yaml_cleanup () {
  yq eval 'del(
    .metadata.annotations.["kubectl.kubernetes.io/last-applied-configuration"],
    .metadata.labels["app.kubernetes.io/instance"],
    .metadata.uid,
    .metadata.creationTimestamp,
    .metadata.resourceVersion)' -
}

# param $1: anon key
# param $2: service role key
patch_consumers () {
  ANON=$1 SERVICE=$2 yq '.consumers |= map(select(.username=="anon") |= .keyauth_credentials.0.key=env(ANON)) |= map(select(.username=="service_role") |= .keyauth_credentials.0.key=env(SERVICE))'
}

CONFIG_MAP=$(kubectl -n supabase get configmap --field-selector metadata.name=supabase-kong-config-initial -o yaml | yq '.items.0' | k8s_yaml_cleanup)
KONG_YML=$(echo "$CONFIG_MAP" | yq '.data["kong.yml"]')

PATCHED_KONG_YML=$(echo "$KONG_YML" | patch_consumers $ANON_KEY $SERVICE_KEY)
PATCHED_CONFIG_MAP=$(echo "$CONFIG_MAP" | KONG="$PATCHED_KONG_YML" yq '.data["kong.yml"]=strenv(KONG) | .metadata.name="supabase-kong-config" | .metadata.namespace="supabase"')

echo "$PATCHED_CONFIG_MAP" | kubectl apply -f -
