# Chart for Supabase Deployment

This only sets up the barebones, without any ingresses or secrets.

## Secrets Setup

`secrets.yaml.example` provides you an example of secret resources, that can be adapted to fit your deployment. Without these secrets set, the applications won't work.

## Ingress Setup

`supabase-ingresses.yaml.example` provides you an example of ingress resources, that should work out of the box, if you're using ingress nginx and cert-manager with _Let's Encrypt_ as cluster issuer.

Also the config maps needs to be patched (patchStrategicMerge)

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: supabase-auth-config
  namespace: supabase
data:
  API_EXTERNAL_URL: https://supabase.subdomain.example.com
  GOTRUE_SITE_URL: https://supabase-studio.subdomain.example.com
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: supabase-studio-config
  namespace: {{ .Release.Namespace }}
data:
  SUPABASE_REST_URL: https://supabase.example.com/rest/v1/
```

Additionally for kong we can't load the secrets as environment variables, but have to provide a config file instead. Therefore a configmap needs to be created, you can use the script `generate_kong_configmap` to generate it.
