#!/bin/sh

# a. Complete the database health check
echo -n "Waiting for postgres database: "
export PGPASSWORD="{{ POSTGRES_GRAFANA_PASSWORD }}"
until psql -h database -d "{{ POSTGRES_GRAFANA_DB }}" -U "{{ POSTGRES_GRAFANA_USER }}" -c '\q' > /dev/null 2>&1; 
do
  echo -n '.'
  sleep 5
done
echo "\nPostgres database is alive"


# TODO wait until authentication server is alive (use curl, check for 200 code)
until [ "$(curl -k --write-out '%{http_code}' --silent --output /dev/null https://auth.vcc.local)" -eq 200 ]; do
  echo 'Waiting for authentication active'
  sleep 1
done
echo "Authentication server is alive"

# TODO wait until https://auth.vcc.local/realms/vcc is alive (use curl, check for 200 code)
until [ "$(curl -k --write-out '%{http_code}' --silent --output /dev/null https://auth.vcc.local/realms/vcc)" -eq 200 ]; do
  echo 'Waiting for authentication active'
  sleep 1
done
echo "Vcc realm is alive"

# wait until self-signed certificate file exists
until [ -f /usr/local/share/ca-certificates/server.crt ]; do
  echo 'Waiting for certificate'
  sleep 1
done
echo "Self-signed certificate exists"

# TODO update the system list of accepted CA certificates
update-ca-certificates

#
# Download from keycloak grafana's client id and secret 
#
keycloakAdminToken() {
  curl -k -X POST https://auth.vcc.local/realms/master/protocol/openid-connect/token \
    --data-urlencode "username=admin" \
    --data-urlencode "password=admin" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' | jq -r '.access_token'
}

grafana_client_id=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" https://auth.vcc.local/admin/realms/vcc/clients?clientId=grafana | jq -r '.[0].id')
grafana_client_secret=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" -X POST https://auth.vcc.local/admin/realms/vcc/clients/${grafana_client_id}/client-secret | jq -r '.value')

# TODO maybe it's not that cool to put secrets in your logs :)
#echo "Grafana client id in keycloak is ${grafana_client_id}"
#echo "Grafana client secret in keycloak is ${grafana_client_secret}"

# TODO setup authentication
export GF_AUTH_GENERIC_OAUTH_ENABLED="true"
export GF_AUTH_GENERIC_OAUTH_NAME="Keycloak-OAuth"
export GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP="true"
export GF_AUTH_GENERIC_OAUTH_CLIENT_ID="grafana"
export GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET="${grafana_client_secret}"
export GF_AUTH_GENERIC_OAUTH_SCOPES="openid email profile offline_access roles"
export GF_AUTH_GENERIC_OAUTH_EMAIL_ATTRIBUTE_PATH="email"
export GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH="username"
export GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH="full_name"
export GF_AUTH_GENERIC_OAUTH_AUTH_URL="https://auth.vcc.local/realms/vcc/protocol/openid-connect/auth"
export GF_AUTH_GENERIC_OAUTH_TOKEN_URL="https://auth.vcc.local/realms/vcc/protocol/openid-connect/token"
export GF_AUTH_GENERIC_OAUTH_API_URL="https://auth.vcc.local/realms/vcc/protocol/openid-connect/userinfo"
export GF_AUTH_GENERIC_OAUTH_TLS_SKIP_VERIFY_INSECURE="true"
export GF_SERVER_ROOT_URL="https://mon.vcc.local/"
export GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH="contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'"

# config database
export GF_DATABASE_TYPE="postgres"
export GF_DATABASE_HOST="database"
export GF_DATABASE_NAME="{{ POSTGRES_GRAFANA_DB }}"
export GF_DATABASE_USER="{{ POSTGRES_GRAFANA_USER }}"
export GF_DATABASE_PASSWORD="{{ POSTGRES_GRAFANA_PASSWORD }}"
export GF_DATABASE_SSL_MODE="disable"

# config credentials
export GF_SECURITY_ADMIN_USER="{{ GRAFANA_ADMIN }}"
export GF_SECURITY_ADMIN_PASSWORD="{{ GRAFANA_ADMIN_PASSWORD }}"

# enable metrics
export GF_METRICS_ENABLED="true"
export GF_SERVER_DOMAIN="https://mon.vcc.local"

# enable provisioning
export GF_PROVISIONING_ENABLED="true" 
export GF_PROVISIONING_CONFIG_FILE="/etc/grafana/provisioning" 


# relaunch original
exec /run.sh "$@"

wait
