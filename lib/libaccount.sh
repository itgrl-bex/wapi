#!/bin/bash

############################################################
#
# Collection of functions for managing groups, accounts and roles
#
############################################################

source ${baseDir}/lib/common.sh


function getGroups {
  # This function is to get and process group list so that local copy of group name and id is present.
  createDir $accountDir
  logThis "Retrieving group list." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o $accountDir/response.json \"${CONF_aria_operationsUrl}/api/v2/usergroup\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'GET' -o $accountDir/response.json \
    "${CONF_aria_operationsUrl}/api/v2/usergroup" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully retrieved group list." "INFO" || logThis "Could not retrieve group list." "CRITICAL"
  logThis "Processing group list." "INFO"
  jq -r '.response.items' $accountDir/response.json | jq "del(.[].roles) | \
  del(.[].roleCount) | del(.[].userCount) | del(.[].properties) | \
  del(.[].description) | del(.[].customer) | del(.[].createdEpochMillis)" > $accountDir/groups.json
  logThis "Removing response." "INFO"
  rm -f $accountDir/response.json
}

function searchGroup {
  local name="${1}"
  local data
  data=$(eval "cat <<EOF
$(<templates/searchGroup.template)
EOF
" 2> /dev/null)
  curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/search/usergroup" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "@${data}" | jq -r '.response.items' | jq -r '.[].id'
}
