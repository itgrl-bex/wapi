#!/bin/bash

############################################################
#
# Collection of functions for managing groups, accounts and roles
#
############################################################

source ${baseDir}/lib/common.sh

# # Deprecated for createDir function
# function createAccountDir {
#   logThis "Checking ${accountDir}" "INFO"
#   if [ -d $accountDir ];
#   then
#     logThis "Directory ${accountDir} exists" "DEBUG"
#   else
#     logThis "Executing the command[mkdir ${accountDir}]" "DEBUG"
#     mkdir $accountDir && logThis "Successfully created ${accountDir}." "INFO" || logThis "Error creating directory ${accountDir}." "CRITICAL"
#   fi
# }

function getGroups {
  # This function is to get and process group list so that local copy of group name and id is present.
  createDir $accountDir
  logThis "Retrieving group list." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o $accountDir/response.json \"${CONF_aria_operationsUrl}/api/v2/usergroup\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'GET' -o $accountDir/response.json \
    "${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully retrieved group list." "INFO" || logThis "Could not retrieve group list." "CRITICAL"
  logThis "Processing group list." "INFO"
  jq -r '.response.items' $accountDir/response.json | jq "del(.[].roles) | \
  del(.[].roleCount) | del(.[].userCount) | del(.[].properties) | \
  del(.[].description) | del(.[].customer) | del(.[].createdEpochMillis)" > $accountDir/groups.json
  logThis "Removing response." "INFO"
  rm -f $accountDir/response.json
}

