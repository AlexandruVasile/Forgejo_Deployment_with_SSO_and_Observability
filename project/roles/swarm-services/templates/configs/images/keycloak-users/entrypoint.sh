#!/bin/sh

# check if authentication server is alive (use curl, check for 200 code)
until [ "$(curl -k --write-out '%{http_code}' --silent --output /dev/null https://auth.vcc.local)" -eq 200 ]; do
  echo 'Waiting for authentication active'
  sleep 1
done

keycloakAdminToken() {
  # get a keycloak admin token
  curl -k -X POST https://auth.vcc.local/realms/master/protocol/openid-connect/token \
    --data-urlencode "username=admin" \
    --data-urlencode "password=admin" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' | jq -r '.access_token'
}

keycloakAdminCurl() {
  # launch a request to keycloak
  curl -k \
    -H "Authorization: Bearer $(keycloakAdminToken)" \
    "$@"
}

# create "vcc-admin" role
keycloakAdminCurl \
  -X POST \
  "https://auth.vcc.local/admin/realms/vcc/roles" \
  -H 'Content-Type: application/json' \
  --data-binary @- <<EOF
{
  "name": "vcc-admin",
  "description": "VCC administrators"
}
EOF

admin_role_id=$(keycloakAdminCurl "https://auth.vcc.local/admin/realms/vcc/roles?search=vcc-admin" | jq -r '.[0].id')

#
# Users
#

findUser() {
  keycloakAdminCurl "https://auth.vcc.local/admin/realms/vcc/users?exact=true&email=$1"
}

findUserId() {
  findUser "$1" | jq -r '.[0].id'
}

# create VCC `exam-user` role
if [ "$(findUser user@vcc.local | jq -r '. | length')" -eq 0 ]; then
  keycloakAdminCurl \
    -H "Content-Type: application/json" \
    https://auth.vcc.local/admin/realms/vcc/users \
    --data-binary @- <<EOF
{
  "username": "exam-user",
  "firstName": "User",
  "lastName": "Examiner",
  "email": "user@vcc.local",
  "emailVerified": true,
  "enabled": true
}
EOF
  user_id=$(findUserId user@vcc.local)
  keycloakAdminCurl \
    -X PUT \
    -H "Content-Type: application/json" \
    "https://auth.vcc.local/admin/realms/vcc/users/${user_id}/reset-password" \
    --data-binary @- <<EOF
{
  "type": "rawPassword",
  "value": "testpass"
}
EOF
fi

# wait forever
while true; do
  sleep 1
done