#!/bin/sh

# as the cli does not run as root
# you need to wrap the forgejo command to run as the `git` user
forgejo_cli() {
  sudo -u git forgejo "$@"
}

# TODO wait until database is alive (port 5432 replies)
echo -n "Waiting for postgres database: "
export PGPASSWORD="{{ POSTGRES_FORGEJO_PASSWORD }}"
until psql -h database -d "{{ POSTGRES_FORGEJO_DB }}" -U "{{ POSTGRES_FORGEJO_USER }}" -c '\q' > /dev/null 2>&1; 
do
  echo -n '.'
  sleep 5
done
echo "\nPostgres database is alive"



# TODO prepare database (`forgejo migrate` cli command)
# add database info in the forgejo config file, it's useless since
# later, point 38a, it's asked to configure the database in the forgejo.ini file
# cat <<EOT >> /data/gitea/conf/app.ini
# [database]
# HOST  = database
# DB_TYPE  = postgres
# NAME     = "{{ POSTGRES_FORGEJO_DB }}"
# USER     = "{{ POSTGRES_FORGEJO_USER }}"
# PASSWD   = "{{ POSTGRES_FORGEJO_PASSWORD }}"
# EOT

# migrate

forgejo_cli migrate

# TODO create admin user (if it does not exists already)
# use `forgejo admin user list` and `forgejo admin user create`
first_line=true 
user_exists=false

for user in $(forgejo_cli admin user list | awk '{print $2}') # iterate over the rows
do 
    echo $user
    if $first_line; then
        first_line=false
        continue 
    fi

    if [ $user == "{{ FORGEJO_ADMIN }}" ]; then
        user_exists=true
        echo "Admin user {{ FORGEJO_ADMIN }} already exists"
        break
    fi
done

if ! $user_exists; then
    echo "Admin user {{ FORGEJO_ADMIN }} doesn't exist, creating it .."
    forgejo_cli admin user create \
    --username "{{ FORGEJO_ADMIN }}" \
    --password "{{ FORGEJO_ADMIN_PASSWORD }}" \
    --email "{{ FORGEJO_ADMIN_EMAIL }}" \
    --admin
fi

# start forgejo (in background)
/bin/s6-svscan /etc/s6 "$@" &

# TODO wait until forgejo is active (use curl, check for 200 code)
until [ "$(curl -k --write-out '%{http_code}' --silent --output /dev/null forgejo:3000)" -eq 200 ]; do
  echo 'Waiting for forgejo to be active'
  sleep 1
done
echo "Forgejo is active"

# TODO wait until authentication server is alive (use curl, check for 200 code)
until [ "$(curl -k --write-out '%{http_code}' --silent --output /dev/null https://auth.vcc.local)" -eq 200 ]; do
  echo 'Waiting for authentication server to be alive'
  sleep 1
done
echo "Authentication server is alive"

# TODO wait until https://auth.vcc.local/realms/vcc is alive (use curl, check for 200 code)
until [ "$(curl -k --write-out '%{http_code}' --silent --output /dev/null https://auth.vcc.local/realms/vcc)" -eq 200 ]; do
  echo 'Waiting for the realm to be alive'
  sleep 1
done
echo "The realm is alive"


# wait until self-signed certificate file exists
until [ -f /usr/local/share/ca-certificates/server.crt ]; do
  echo 'Waiting for certificate'
  sleep 1
done
echo "Self-signed certificate exists"

# TODO update the system list of accepted CA certificates
update-ca-certificates 
echo "System list of accepted CA certificates updated"

#
# Download from keycloak forgejo's client id and secret 
#
keycloakAdminToken() {
  curl -k -X POST https://auth.vcc.local/realms/master/protocol/openid-connect/token \
    --data-urlencode "username=admin" \
    --data-urlencode "password=admin" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' | jq -r '.access_token'
}
forgejo_client_id=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" https://auth.vcc.local/admin/realms/vcc/clients?clientId=forgejo | jq -r '.[0].id')
forgejo_client_secret=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" -X POST https://auth.vcc.local/admin/realms/vcc/clients/${forgejo_client_id}/client-secret | jq -r '.value')

# TODO maybe it's not that cool to put secrets in your logs :)
#echo "Forgejo client id in keycloak is ${forgejo_client_id}"
#echo "Forgejo client secret in keycloak is ${forgejo_client_secret}"

# TODO setup authentication (if it does not exist)
# use `forgejo admin auth add-oauth`
#   --auto-discover-url is https://auth.vcc.local/realms/vcc/.well-known/openid-configuration
#   --provider is openidConnect
first_line=true 
oauth_exists=false

for auth_name in $(forgejo_cli admin auth list | awk '{print $2}') # iterate over the rows
do 
    echo $auth_name
    if $first_line; then
        first_line=false
        continue 
    fi

    if [ $auth_name == "{{ FORGEJO_AUTH_NAME }}" ]; then
        oauth_exists=true
        echo "Auth for forgejo already exists"
        break
    fi
done

if ! $oauth_exists; then
    echo "Auth for forgejo doesn't exists, creating one.."
    forgejo_cli admin auth add-oauth \
    --auto-discover-url https://auth.vcc.local/realms/vcc/.well-known/openid-configuration \
    --provider openidConnect \
    --name forgejo \
    --key forgejo \
    --secret $forgejo_client_secret
fi

forgejo_cli admin auth update-oauth

# wait forever
wait