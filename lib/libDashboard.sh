#!/bin/bash

############################################################
#
# Collections of functions for dashboards.
#
############################################################

source "${baseDir}/lib/common.sh"

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
  local _OUTPUT
  _OUTPUT=$(jq -r '.response' "${1}")
  if [[ -z "${_OUTPUT}" ]];
  then
    dashboardID=$(jq -r '.response.id' "${1}")
    echo "${dashboardID}"
    extractResponse "${1}" "${responseDir}"
  else
    createDir "${responseDir}"
    dashboardID=$(jq -r '.id' "${1}")
    logThis "Copying dashboard to response file since the response body has been extracted already." "INFO"
    local _FILENAME
    _FILENAME=$(basename "${1}")
    cp "${1}" "${responseDir}/${_FILENAME}.response"
  fi
}

# Moved to common.sh
# function extractResponse {
#   createDir "${2}"
#   logThis "Extracting JSON response body from file." "INFO"
#   local _FILENAME
#   _FILENAME=$(basename "${1}")
#   logThis "Executing the command [jq -r '.response' ${1} > ${2}/${_FILENAME}.response]" "DEBUG"
#   jq -r '.response' "${1}" > "${2}/${_FILENAME}.response" && logThis "Successfully extracted JSON response body." "INFO" || logThis "Could not extract JSON response body from file ${1}." "CRITICAL"
#   logThis "Extracted JSON response body from file ${1} and storing it in the directory ${2}." "DEBUG"
# }

# Moved to common.sh
# function scrubResponse {
#   logThis "Scrubbing response to remove metadata." "INFO"
#   logThis "Executing command: [cat ${1}.response | jq \"del(.disableRefreshInLiveMode) | del(.hideChartWarning) | \
#   del(.creatorId) | del(.updaterId) | del(.createdEpochMillis) | del(.updatedEpochMillis) | \
#   del(.deleted) | del(.numCharts) | del(.numFavorites) | del(.favorite)\" > ${1}]" "DEBUG"
# #  cat "${1}".response | \
#   jq "del(.disableRefreshInLiveMode) | \
#   del(.hideChartWarning) | \
#   del(.creatorId) | \
#   del(.updaterId) | \
#   del(.createdEpochMillis) | \
#   del(.updatedEpochMillis) | \
#   del(.deleted) | \
#   del(.numCharts) | \
#   del(.numFavorites) | \
#   del(.favorite)" < "${1}.response" > "${1}" && logThis "Successfully scrubbed JSON response body." "INFO" || logThis "Could not scrub JSON response body from file ${1}.response." "CRITICAL"
# }

function getDashboard {
  logThis "Checking dashboard retrieval output directory ${sourceDir}." "INFO"
  if [ -d "${sourceDir}" ];
  then
    logThis "Directory ${sourceDir} exists." "DEBUG"
  else
    mkdir -p "${sourceDir}" && logThis "Successfully created ${sourceDir}." "INFO" || logThis "Error creating directory ${sourceDir}." "CRITICAL"
  fi
  logThis "Retrieving Dashboard ${dashboardID}." "INFO"
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

# Moved to common.sh
# function processCloneFileName {
#   logThis "Stripping working copy Clone tags from filename ${1} before publishing." "INFO"
#   echo 'file process'
#   newFILENAME=$(echo "${_FILENAME}" | awk -F '-Clone' '{print $1}').json
#   logThis "Rename the file ${responseDir}/${_FILENAME}.response to ${responseDir}/${newFILENAME}.response" "INFO"
#   echo "${_FILENAME}"
#   echo "${newFILENAME}"
#   mv "${responseDir}/${_FILENAME}.response" "${responseDir}/${newFILENAME}.response"
#   _FILENAME="${newFILENAME}"
#   unset newFILENAME

# }

# Moved to common.sh
# function processCloneID {
#   logThis "Stripping working copy Clone tags from file ${1} before publishing." "INFO"
#   local _dashboardID
#   _dashboardID=$(echo "${dashboardID}" | awk -F '-Clone' '{print $1}')
#   logThis "Changing (dashboardID) in file from ${dashboardID} to ${_dashboardID} in file ${_FILENAME}." "DEBUG"
#   sed -i '.clone' "s/${dashboardID}/${_dashboardID}/g" "${responseDir}/${_FILENAME}.response"
#   logThis "Changing dashboard name to remove the (Clone) designation." "DEBUG"
#   sed -i '' -E 's/ \(Clone\)//' "${responseDir}/${_FILENAME}.response"
#   logThis "Changing (dashboardID) variable from ${dashboardID} to ${_dashboardID}." "DEBUG"
#   dashboardID="${_dashboardID}"
# }

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