#!/bin/bash

############################################################
#
# Collection of functions for managing alerts
#
############################################################


source "${baseDir}/lib/common.sh"

##############################################################################
## Function Name: createMaintenanceWindow
## Purpose: The purpose of this function is to execute the creation of the
##          standard maintenance windows for alert development workflow. This
##          will prevent multiple alerts and ticket generation while alerts 
##          during the development workflow.
##
## Inputs:
##   ${1} - first positional parameter passed will be the json file of the 
##          maintenance window.  
##   ${2} - second positional parameter will be the name of the maintenance
##          window and is used only for logging purposes.
##
## Outputs:
##          Returns 0 if successful and 1 if not successful.
##
##############################################################################

function createMaintenanceWindow {
  local data="${1}"
  local name="${2}"
  if (curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/maintenancewindow" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "@${data}");
  then
    logThis "Successfully created maintenance window ${name}." "INFO"
    return 0
  else
    logThis "Maintenance window ${name} creation failed." "Error"
    return 1
  fi
}

##############################################################################
## Function Name: searchMaintenanceWindow
## Purpose: The purpose of this function is to search for a maintenance window
##          with a specific name or title.
##          will prevent multiple alerts and ticket generation while alerts 
##          during the development workflow.
##
## Inputs:
##   ${1} - first positional parameter passed will be the title of the 
##          maintenance window. This is an exact match query.
##
## Outputs:
##          Returns id of found maintenance window matching title.
##
##############################################################################

function searchMaintenanceWindow {
  local name="${1}"
  local data
  data=$(eval "cat <<EOF
$(<templates/searchAlert.template)
EOF
" 2> /dev/null)
  curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/search/maintenancewindow" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "@${data}" | jq -r '.response.items' | jq -r '.[].id'
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
## 
## Outputs:
##
##############################################################################

function getAlert {
  logThis "Checking alert retrieval output directory ${sourceDir}." "INFO"
  if [ -d "${sourceDir}" ];
  then
    logThis "Directory ${sourceDir} exists." "DEBUG"
  else
    mkdir -p "${sourceDir}" && logThis "Successfully created ${sourceDir}." "INFO" || logThis "Error creating directory ${sourceDir}." "CRITICAL"
  fi
  logThis "Retrieving Alert ${alertID}." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o ${sourceDir}/${alertID}.json \"${CONF_aria_operationsUrl}/api/v2/alert/${alertID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  if curl -X 'GET' -o "${sourceDir}/${alertID}.json" \
    "${CONF_aria_operationsUrl}/api/v2/alert/${alertID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}";
  then
    logThis "Successfully retrieved alert ${alertID}." "INFO"
    return 0
  else
    logThis "Could not find alert ${alertID}, creating dashboard." "INFO"
    createAlert
    return 3
  fi
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
## 
## Outputs:
##
##############################################################################

function getAlertID {
  if [ -z "${1}" ];
  then
    logThis "Required parameter #1 'filename' missing." "SEVERE"
  fi
  if [ -z "${responseDir}" ];
  then
    logThis "Required parameter #2 'responseDir' missing." "SEVERE"
  fi
  logThis "Retrieving alertID" "INFO"
  local _OUTPUT
  _OUTPUT=$(jq -r '.response' "${1}")
  if [[ -z "${_OUTPUT}" ]];
  then
    alertID=$(jq -r '.response.id' "${1}")
    echo "${alertID}"
    extractResponse "${1}" "${responseDir}"
  else
    createDir "${responseDir}"
    alertID=$(jq -r '.id' "${1}")
    logThis "Copying alert to response file since the response body has been extracted already." "INFO"
    local _FILENAME
    _FILENAME=$(basename "${1}")
    cp "${1}" "${responseDir}/${_FILENAME}.response"
  fi
}

