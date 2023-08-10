#!/bin/bash

############################################################
#
# Collection of functions for managing alerts
#
############################################################


source "${baseDir}/lib/common.sh"

# Moving to library files to set action specific directories for reusability.
# If dataPath is set in the config, use it.
# Otherwise use the script base directory of ${baseDir}

tmpDir=$( getTmpDir )

if [ -z "${CONF_dataPath}" ];
then
  logThis "Does not have data path set." "INFO"
  dashboardDir="${baseDir}/${CONF_dashboard_dir}"
  accountDir="${baseDir}/${CONF_account_dir}"
  alertDir="${baseDir}/${CONF_alert_dir}"
  sourceDir="${tmpDir}/${CONF_alert_sourceDir}"
  responseDir="${tmpDir}/${CONF_alert_dir}/responses"
else
  logThis "Has data path '${CONF_dataPath}' set." "INFO" 
  dashboardDir="${CONF_dataPath}/${CONF_dashboard_dir}"
  accountDir="${CONF_dataPath}/${CONF_account_dir}"
  alertDir="${CONF_dataPath}/${CONF_alert_dir}"  
  sourceDir="${tmpDir}/${CONF_alert_sourceDir}"
  responseDir="${tmpDir}/${CONF_alert_dir}/responses"
fi

##############################################################################
## Function Name: createMaintenanceWindow
## Purpose: The purpose of this function is to execute the creation of the
##          standard maintenance windows for alert development workflow. This
##          will prevent multiple alerts and ticket generation while alerts 
##          during the development workflow.
##
## Inputs:
##   ${1} - The first positional parameter passed will be the filepath of  
##          the maintenance window template.  
##   ${2} - The second positional parameter will be the title/name of the 
##          maintenance window and is used only for logging purposes.
##   ${3} - The third positional parameter will be the reason to populate in
##          the maintenance window configuration.
##   ${4} - The fourth positional parameter passed will be the tag for the 
##          maintenance window to match on.
##
## Outputs:
##          Returns 0 if successful and 1 if not successful.
##
##############################################################################

function createMaintenanceWindow {
  local file="${1}"
  local title="${2}"
  local reason="${3}"
  local tag="${4}"
  local data
  data=$(eval "cat <<EOF
$(<${file})
EOF
" 2> /dev/null)
  if (curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/maintenancewindow" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "${data}");
  then
    logThis "Successfully created maintenance window ${title}." "INFO"
    return 0
  else
    logThis "Maintenance window ${title} creation failed." "Error"
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
##   ${1} - The first positional parameter passed will be the title of the 
##          maintenance window. This is an exact match query.
##
## Outputs:
##          Returns id of found maintenance window matching title.
##
##############################################################################

function searchMaintenanceWindow {
  local name="${1}"
  local file="${2}"
  local data
  data=$(eval "cat <<EOF
$(<${baseDir}/templates/searchMaintenanceWindow.template)
EOF
" 2> /dev/null)
  curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/search/maintenancewindow" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "${data}" | jq -r '.response.items' | jq -r '.[].id'
}

##############################################################################
## Function Name: getAlert
## Purpose: This function retrieves the alert from Aria Operations for
##          Applications and stores in the the directory.
##
## Inputs: 
##         This function is alert specific and has no positional parameters to 
##         pass. The alert relies on the calling logic to have the following
##         variables set.
##         (sourceDir) This is the directory where to put files from the Aria
##                     Operations for Applications API call via the 'getAlert'
##                     function.
##         (alertID)   This is the 13 digit id of the alert, 'getAlertID' 
##                     function retrieves this from the file in the repo.
##         (CONF_aria_operationsUrl) https://<yourinstance>.wavefront.com
##                       This is front the configuration file 'cfg/config.yaml'
##         (apiToken)  This is the API token used to talk to the Aria 
##                     Operations for Applications API. This token can be
##                     set in the file 'cfg/config.yaml' under the global
##                     aria key or under the alert key.
## 
## Outputs:
##         The output of this function is a json file for the alert stored as
##         the API call response.
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
    logThis "Could not find alert ${alertID}, creating alert." "INFO"
    createAlert
    return 3
  fi
}

##############################################################################
## Function Name: getAlertID
## Purpose: The file we are working with can be the API response or the json
##          response body. The function determines which and returns the value
##          from the json key ID out of the json response body. As part of 
##          finding the value, the function uses the 'extractResponse' if 
##          needed so the output of the 'getAlertID' function is always the 
##          alertID and the json response body with the '.response' extension
##          stored in the directory specified.
##
## Inputs:
##   ${1} - The first positional parameter to pass is the filename of the file
##          to process. Full path to the file is passed.     
##   ${2} - The second positional parameter to pass is the directory where the
##          response body is stored and where the file should be processed.
##          Common reference is the 'responseDir'
##
## Outputs:
##          This function is a compound function and performs many steps. 
##          1. The function determines if the passed file is the full API 
##             response or just the json response body. 
##          2. The functions will create the directory and parent directories 
##             if they do not exist.
##          3. If the file is the full API response, then the function 
##             extracts the json response and stores it in the directory
##             specified as input with the extension '.response'. 
##          4. If the file is the JSON response body, then the function copies
##             the file to the directory specified as input with the extension
##             '.response'
##          5. The function sets the variable alertID.
##          6. The function passes back the alertID in case calling to store
##             in a variable
##             
##############################################################################

function getAlertID {
  local filename="${1}"
  local dir="${2}"
  if [ -z "${filename}" ];
  then
    logThis "Required parameter #1 'filename' missing." "SEVERE"
  fi
  if [ -z "${dir}" ];
  then
    logThis "Required parameter #2 'responseDir' missing." "SEVERE"
  fi
  logThis "Retrieving alertID" "INFO"
  if grep '"response":' "${1}";
  then
    alertID=$(jq -r '.response.id' "${filename}")
    echo "${alertID}"
    extractResponse "${filename}" "${dir}"
  else
    createDir "${dir}"
    alertID=$(jq -r '.id' "${filename}")
    logThis "Copying alert to response file since the response body has been extracted already." "INFO"
    local _FILENAME
    _FILENAME=$(basename "${filename}")
    cp "${filename}" "${dir}/${_FILENAME}.response"
  fi
  echo "${alertID}"
}

##############################################################################
## Function Name: deleteAlert
## Purpose: The purpose of this function is to delete alerts via the Aria 
##          Operations for Applications API.
##
## Inputs:
##   ${1}  The first positional parameter to pass is the (alertID)     
##         This is the 13 digit id of the alert, 'getAlertID' function 
##         retrieves this from the file in the repo.
##
##         This function is alert specific and has no positional parameters to 
##         pass. 
##         The alert relies on the calling logic to have the following 
##         variables set.
##         (responseDir) This is the directory where to put files from the Aria
##                       Operations for Applications API call via the 'getAlert'
##                       function.
##         (CONF_aria_operationsUrl) https://<yourinstance>.wavefront.com
##                       This is front the configuration file 'cfg/config.yaml'
##         (apiToken)    This is the API token used to talk to the Aria 
##                       Operations for Applications API. This token can be
##                       set in the file 'cfg/config.yaml' under the global
##                       aria key or under the alert key.
## 
## Outputs:
##          Returns 0 if successful and 1 if not successful.
##
##############################################################################

function deleteAlert {
  local ID="${1}"
  logThis "Deleting Alert ID ${ID}" "INFO"
  logThis "Executing command:  [curl -X 'DELETE' \"${CONF_aria_operationsUrl}/api/v2/alert/${ID}?skipTrash=false\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  if (curl -X 'DELETE' \
    "${CONF_aria_operationsUrl}/api/v2/alert/${ID}?skipTrash=false" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}");
  then
    logThis "Successfully deleted alert ID ${ID}." "INFO"
    return 0
  else
    logThis "Could not delete alert ID ${ID}." "CRITICAL"
    return 1
  fi
}

##############################################################################
## Function Name: pushAlert
## Purpose: The purpose of this function is to push changes for alert files 
##          from the repository to Aria Operations for Applications via the 
##          API.
##
## Inputs:
##         This function is alert specific and has no positional parameters to 
##         pass. The alert relies on the calling logic to have the following
##         variables set.
##         (responseDir) This is the directory where to put files from the Aria
##                       Operations for Applications API call via the 'getAlert'
##                       function.
##         (alertID)     This is the 13 digit id of the alert, 'getAlertID' 
##                       function retrieves this from the file in the repo.
##         (CONF_aria_operationsUrl) https://<yourinstance>.wavefront.com
##                       This is front the configuration file 'cfg/config.yaml'
##         (apiToken)    This is the API token used to talk to the Aria 
##                       Operations for Applications API. This token can be
##                       set in the file 'cfg/config.yaml' under the global
##                       aria key or under the alert key.
## 
## Outputs:
##          Returns 0 if successful and 1 if not successful.
##
##############################################################################

function pushAlert {
  logThis "Publishing Dlert ${alertID}" "INFO"
  logThis "Executing command:  [curl -X 'PUT' --data \"@${responseDir}/${alertID}.json\" \"${CONF_aria_operationsUrl}/api/v2/alert/${alertID}\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  if (curl -X 'PUT' --data "@${responseDir}/${alertID}.json" \
    "${CONF_aria_operationsUrl}/api/v2/alert/${alertID}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}");
  then
    logThis "Successfully pushed alert ${alertID}." "INFO"
    return 0
  else
    logThis "Could not pushed alert ${alertID}." "CRITICAL"
    return 1
  fi
}
