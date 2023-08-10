#!/bin/bash

############################################################
#
# Purpose is to remove action specific logic to files.
# Reason is to simply and shorten main calling script.
# Benefit is that logic for specific action is easy to maintain.
#
############################################################


## Load common functions
source "${baseDir}/lib/common.sh"

source "${baseDir}/lib/libAccount.sh"

#getGroups

#getUsersInGroup $accountDir/groups.json


# Grab the group list from the account section of config.yaml file and convert into an array (managedGroups)
managedGroups=($(yq '.CONF.account.managedGroups[]' "${config}"))

echo ${managedGroups[*]}
#Parsing through each group name...
for groupName in ${managedGroups[@]};
do
    ## Get the groupID from the group name in Aria
    #searchGroup ${groupName}
    groupID=$(searchGroup ${groupName})
    ## Get all users belonging to the specified group in Aria
    getAriaGroupMembers ${groupID} ${groupName}

    ## Get all users belonging to the specified group in LDAP
    getLDAPGroupMembers ${groupName}

    compare ldap membership with Aria
    add when not found in Aria
    For each user in the group; do
    jq -r '.[]' ${CONF_tmpDir}/${groupName}_aria.json | while IFS= read -r user; do
        echo "Checking for user ${user} in ${CONF_tmpDir}/${groupName}_ldap.json"
        if jq -e ".[] | select(. == \"${user}\")" ${CONF_tmpDir}/${groupName}_ldap.json > /dev/null; then
            echo "User ${user} is already a member of the ${groupName} group"
        else
            echo "User ${user} is NOT a member of the ${groupName} group."
            logThis "User ${user} is NOT a member of ${groupName} in Aria" "INFO"
            logThis "Removing User ${user} from group: ${groupName} in Aria" "INFO"
            removeUser ${user} ${groupID}
        fi

    done


    ##Inverse Check.

    jq -r '.[]' ${CONF_tmpDir}/${groupName}_ldap.json | while IFS= read -r user; do
        echo "Checking for user ${user} in ${CONF_tmpDir}/${groupName}_aria.json"
        if jq -e ".[] | select(. == \"${user}\")" ${CONF_tmpDir}/${groupName}_aria.json > /dev/null; then
            echo "User ${user} is already a member of the ${groupName} group"
        else
            echo "User ${user} is NOT yet a member of the ${groupName} group."
            logThis "User ${user} is NOT yet a member of ${groupName} in Aria" "INFO"
            logThis "Adding User ${user} to group: ${groupName} in Aria" "INFO"
            addUser ${user} ${groupID}
        fi

    done
    
   

  
done

#getLDAPGroupMembers Scientists