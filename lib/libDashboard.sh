#!/bin/bash

############################################################
#
# Collections of functions for dashboards.
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
  sourceDir="${tmpDir}/${CONF_dashboard_sourceDir}"
  responseDir="${tmpDir}/dashboards/responses"
  accountDir="${baseDir}/${CONF_account_dir}"
  alertDir="${baseDir}/${CONF_alert_dir}"
else
  logThis "Has data path '${CONF_dataPath}' set." "INFO" 
  dashboardDir="${CONF_dataPath}/${CONF_dashboard_dir}"
  sourceDir="${tmpDir}/${CONF_dashboard_sourceDir}"
  responseDir="${tmpDir}/dashboards/responses"
  accountDir="${CONF_dataPath}/${CONF_account_dir}"
  alertDir="${CONF_dataPath}/${CONF_alert_dir}"
fi

function getDashboardID {
  if [ -z "${1}" ];
  then
    logThis "Required parameter #1 'filename' missing." "SEVERE"
  fi
  if [ -z "${responseDir}" ];
  then
    logThis "Required parameter #2 'responseDir' missing." "SEVERE"
  fi
  logThis "Retrieving dashboardID" "INFO"
  if grep '"response":' "${1}";
  then
    dashboardID=$(jq -r '.response.id' "${1}")
    echo "${dashboardID}"
    extractResponse "${1}" "${responseDir}"
  else
    createDir "${responseDir}"
    dashboardID=$(jq -r '.id' "${1}")
    logThis "Since the json response has been extracted, we are now sorting the response." "INFO"
    local _FILENAME
    _FILENAME=$(basename "${1}")
    jq -S . "${1}" > "${responseDir}/${_FILENAME}.response"
  fi
}

function getDashboard {
  logThis "Checking dashboard retrieval output directory ${sourceDir}." "INFO"
  if [ -d "${sourceDir}" ];
  then
    logThis "Directory ${sourceDir} exists." "DEBUG"
  else
    mkdir -p "${sourceDir}" && logThis "Successfully created ${sourceDir}." "INFO" || logThis "Error creating directory ${sourceDir}." "CRITICAL"
  fi
  logThis "Retrieving Dashboard '${dashboardID}'." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o ${sourceDir}/${dashboardID}.json \"${CONF_aria_operationsUrl}/api/v2/dashboard/${dashboardID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  if curl -X 'GET' -o "${sourceDir}/${dashboardID}.json" \
    "${CONF_aria_operationsUrl}/api/v2/dashboard/${dashboardID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}";
  then
    logThis "Successfully retrieved dashboard ${dashboardID}." "INFO"
    return 0
  else
    logThis "Could not find dashboard ${dashboardID}, creating dashboard." "INFO"
    createDashboard
    return 3
  fi
}

function getWorkingCopyDashboard {
  logThis "Checking dashboard retrieval output directory ${dashboardDir}." "INFO"
  if [ -d "${dashboardDir}" ];
  then
    logThis "Directory ${dashboardDir} exists." "DEBUG"
  else
    mkdir -p "${dashboardDir}" && logThis "Successfully created ${dashboardDir}." "INFO" || logThis "Error creating directory ${dashboardDir}." "CRITICAL"
  fi
  if [ -f "${dashboardDir}/${dashboardID}.json" ];
  then
    read -r -p "Replace file ${dashboardDir}/${dashboardID}.json? (yes/no) " yn
    case $yn in 
	    y | Y | yes ) 
          logThis "Replacing the Dashboard file ${dashboardDir}/${dashboardID}.json." "INFO"
          ;;
	    n | N | no )
          logThis "The Dashboard file ${dashboardDir}/${dashboardID}.json exists and not replacing." "INFO"
		      exit
          ;;
	    * ) echo invalid response;
		      exit 1
          ;;
    esac
  fi
  logThis "Retrieving Dashboard ${dashboardID}." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o \"${dashboardDir}/${dashboardID}.json\" \"${CONF_aria_operationsUrl}/api/v2/dashboard/${dashboardID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'GET' -o "${dashboardDir}/${dashboardID}.json" \
    "${CONF_aria_operationsUrl}/api/v2/dashboard/${dashboardID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully retrieved dashboard ${dashboardID}." "INFO" || logThis "Could not retrieve dashboard ${dashboardID}." "CRITICAL"
}

function pushDashboard {
  logThis "Publishing Dashboard ${dashboardID}" "INFO"
  logThis "Executing command:  [curl -X 'PUT' --data \"@${responseDir}/${dashboardID}.json\" \"${CONF_aria_operationsUrl}/api/v2/dashboard/${dashboardID}\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'PUT' --data "@${responseDir}/${dashboardID}.json" \
    "${CONF_aria_operationsUrl}/api/v2/dashboard/${dashboardID}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully pushed dashboard ${dashboardID}." "INFO" || logThis "Could not pushed dashboard ${dashboardID}." "CRITICAL"
}

function deleteDashboard {
  logThis "Deleting Dashboard ${1}" "INFO"
  logThis "Executing command:  [curl -X 'DELETE' \"${CONF_aria_operationsUrl}/api/v2/dashboard/${1}?skipTrash=false\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'DELETE' \
    "${CONF_aria_operationsUrl}/api/v2/dashboard/${1}?skipTrash=false" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully deleted dashboard ${1}." "INFO" || logThis "Could not delete dashboard ${1}." "CRITICAL"
}

function createDashboard {
  logThis "Creating Dashboard ${dashboardID}" "INFO"
  logThis "Executing command:  [curl -X 'POST' --data \"@${responseDir}/${dashboardID}.json\" \"${CONF_aria_operationsUrl}/api/v2/dashboard\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
  curl -X 'POST' --data "@${responseDir}/${dashboardID}.json" \
    "${CONF_aria_operationsUrl}/api/v2/dashboard" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully created the dashboard ${dashboardID}." "INFO" || logThis "Could not create the dashboard ${dashboardID}." "CRITICAL"
}

function searchDashboard {
  local 
}