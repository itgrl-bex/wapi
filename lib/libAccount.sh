#!/bin/bash

############################################################
#
# Collection of functions for managing groups, accounts and roles
#
############################################################

source ${baseDir}/lib/common.sh


function getGroups {
  # This function is to get and process group list so that local copy of group name and id is present.
  createDir ${accountDir}
  logThis "Retrieving group list." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o ${accountDir}/response.json \"${CONF_aria_operationsUrl}/api/v2/usergroup\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'GET' -o ${accountDir}/response.json \
    "${CONF_aria_operationsUrl}/api/v2/usergroup" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully retrieved group list." "INFO" || logThis "Could not retrieve group list." "CRITICAL"
  logThis "Processing group list." "INFO"
  jq -r '.response.items' ${accountDir}/response.json | jq "del(.[].roles) | \
  del(.[].roleCount) | del(.[].userCount) | del(.[].properties) | \
  del(.[].description) | del(.[].customer) | del(.[].createdEpochMillis)" > ${accountDir}/groups.json
  logThis "Removing response." "INFO"
  rm -f ${accountDir}/response.json
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
##   ${1} - 
##          
##          
##   ${2} - 
## 
## 
## Outputs:
##
##############################################################################
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
    -d "${data}" | jq -r '.response.items' | jq -r '.[].id'
}




##############################################################################
## Function Name: getAriaGroupMembers
## Purpose: This function sends an API call to Aria Operations for Applications 
##          to find all users belonging to a specified group and then create a 
##          json file with users in an array
##
## Inputs:
##   ${1} - The groupID
##          
##   ${2} - The name of the group
## 
## 
## Outputs: A json file named ${groupName}_ldap.json
##
##############################################################################
function getAriaGroupMembers {
  #set -o xtrace
  #createDir ${CONF_tmpDir}
  createDir ${accountDir}
  local groupID=${1}
  local groupName=${2}

  echo "group name is ${groupName} and ID is ${groupID}"
  logThis "Retrieving group list." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o ${accountDir}/response.json \"${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'GET' -o ${accountDir}/response.json \
  "${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully retrieved user list from group ${groupName} ." "INFO" || logThis "Could not retrieve user list for group ${groupName}." "CRITICAL"
  logThis "Processing user list from group ${groupName}." "INFO"
  jq -r '.response' ${accountDir}/response.json | jq "del(.roles) | \
  del(.userCount) | del(.createdEpochMillis) | del(.customer) | \
  del(.roleCount) | del(.properties) | del(.description)| del(.name)| del(.id)" > ${CONF_tmpDir}/tmpUserList.json
  ## Sort in alphabetical order
  cat ${CONF_tmpDir}/tmpUserList.json | jq '.users | sort' > ${CONF_tmpDir}/${groupName}_aria.json
  #cat ${CONF_tmpDir}/tmpUserList.json
  #cat ${CONF_tmpDir}/${groupName}_aria.json
  ##cleanup
  rm -f ${CONF_tmpDir}/tmpUserList.json
}

##############################################################################
## Function Name: getLDAPGroupMembers
## Purpose: This function connects to a remote LDAP server to find all users
##          belonging to a specified group and then create a json file with
##          users in an array
##
## Inputs:
##   ${1} - The name of the group
##          
## 
## 
## Outputs: A json file named ${groupName}_ldap.json
##
##############################################################################
function getLDAPGroupMembers {
    createDir ${CONF_tmpDir}
    local group="${1}"

    # Perform the LDAP search for the group members
    local result=$(ldapsearch -x -H "${CONF_account_LDAP_Server}" -b "${CONF_account_LDAP_baseDN}" -D "${CONF_account_LDAP_bindDN}" -w "${CONF_account_LDAP_bindPassword}" \
                    "(&(objectClass=groupOfUniqueNames)(ou=${group}))" uniqueMember)

    # Extract the group members and save to a JSON file
    local members=$(echo "$result" | grep "uid" | awk '{print $2}' | sed -n 's/^uid=\([^,]*\),.*/\1/p' | tr '\n' ' ') 
    read -ra user_array <<< "$members"
    json_users=""
    for user in "${user_array[@]}"; do
        json_users+="\"$user\", "
    done

    json_users=${json_users%, }  # Remove the trailing comma and space

    ## Sort the users in alphabetical order
    echo "{\"users\": [$json_users]}" | jq '.users | sort' > "${CONF_tmpDir}/${group}_ldap.json"
}


##############################################################################
## Function Name: addUser
## Purpose: This function sends an API call to Aria Operations for Applications
##          to add a user to a usergroup
##
## Inputs:
##   ${1} - userID
##          
##          
##   ${2} - groupID
## 
## 
## Outputs: HTTP Status response
##
##############################################################################
function addUser {
    local user="${1}"
    local groupID="${2}"
    local data
    data=$(eval "cat <<EOF
$(<templates/updateUser.template)
EOF
" 2> /dev/null)
  curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}/addUsers" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "${data}" && logThis "Successfully added User ${user}." "INFO" || logThis "Could not added User ${user}." "CRITICAL"
}

##############################################################################
## Function Name: removeUser
## Purpose: This function sends an API call to Aria Operations for Applications
##          to remove a user from a usergroup
##
## Inputs:
##   ${1} - userID
##          
##          
##   ${2} - groupID
## 
## 
## Outputs: HTTP Status response
##
##############################################################################
function removeUser {
    local user="${1}"
    local groupID="${2}"
    local data
    data=$(eval "cat <<EOF
$(<templates/updateUser.template)
EOF
" 2> /dev/null)
  curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}/removeUsers" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "${data}" && logThis "Successfully remove User ${user}." "INFO" || logThis "Could not remove User ${user}." "CRITICAL"
}





# function isMember {
#     ## Probably move this into the config yaml?
#     local ldapServer="ldap://ldap_server_address"
#     local baseDN="dc=example,dc=com"
#     local bindDN="cn=admin,dc=example,dc=com"   # Replace with admin bind DN
#     local bindPassword="your_admin_password"   # Replace with admin password
#     local user="${1}"
#     local groupName="${2}"

#     # Perform the LDAP search for the given user's group membership
#     local result=$(ldapsearch -x -H "${ldapServer}" -b "${baseDN}N" -D "${bindDN}" -w "${bindPassword}" \
#                     "(&(objectClass=posixGroup)(cn=${groupName})(memberUid=${user}))" memberUid)

#     # Check if the user is a member of the group
#     if echo "${result}" | grep -q "memberUid: ${user}"; then
#         return 0
#     else
#         return 1
#     fi
# }


# function getUsersInGroup {
#   createDir $accountDir/tmpDir
#   local groups_file=$1

#   while IFS=':' read -r groupName groupID; do
#     echo "group name is ${groupName} and ID is ${groupID}"
#     logThis "Retrieving group list." "INFO"
#     logThis "Executing command:  [curl -X 'GET' -o $accountDir/response.json \"${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
#     curl -X 'GET' -o $accountDir/response.json \
#     "${CONF_aria_operationsUrl}/api/v2/usergroup/${groupID}" \
#     -H 'accept: application/json' \
#     -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully retrieved user list from group ${groupName} ." "INFO" || logThis "Could not retrieve user list for group ${groupName}." "CRITICAL"
#     logThis "Processing user list from group ${groupName}." "INFO"
#     jq -r '.response' $accountDir/response.json | jq "del(.roles) | \
#     del(.userCount) | del(.createdEpochMillis) | del(.customer) | \
#     del(.roleCount) | del(.properties) | del(.description)" > $accountDir/tmpDir/${groupID}.json
#     jq -s 'flatten' $accountDir/tmpDir/* > $accountDir/users.json
#   done< <(cat ${groups_file} | jq -r '.[] | "\(.name):\(.id)"')

# }
