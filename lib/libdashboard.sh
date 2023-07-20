#!/bin/bash

############################################################
#
# Collections of functions for dashboards.
#
############################################################

source ${baseDir}/lib/common.sh

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
  local _OUTPUT=$(jq -r '.response' $1)
  if [ -n "$_OUTPUT" ];
  then
    dashboardID=$(jq -r '.response.id' $1)
    echo $dashboardID
    extractResponse $1 $responseDir
  else
    dashboardID=$(jq -r '.id' $1)
    echo $dashboardID
    logThis "Copying dashboard to response file since the response body has been extracted already." "INFO"
    cp $1 $responseDir/
  fi
}

# function createResponseDir {
#   if [ -z "${responseDir}" ];
#   then
#     logThis "Required parameter 'responseDir' missing." "SEVERE"
#   fi
#   logThis "Checking ${responseDir}" "INFO"
#   if [ -d $responseDir ];
#   then
#     logThis "Directory ${responseDir} exists" "DEBUG"
#   else
#     logThis "Executing the command[mkdir ${responseDir}]" "DEBUG"
#     mkdir $responseDir && logThis "Successfully created ${responseDir}." "INFO" || logThis "Error creating directory ${responseDir}." "CRITICAL"
#   fi
# }

function extractResponse {
  createDir "${responseDir}"
  logThis "Extracting JSON response body from file." "INFO"
  local _FILENAME=$(basename $1)
  logThis "Executing the command [jq -r '.response' ${1} > ${2}/${_FILENAME}.response]" "DEBUG"
  jq -r '.response' $1 > $2/$_FILENAME.response && logThis "Successfully extracted JSON response body." "INFO" || logThis "Could not extract JSON response body from file ${1}." "CRITICAL"
  logThis "Extracted JSON response body from file ${1} and storing it in the directory ${2}." "DEBUG"
}

function scrubResponse {
  logThis "Scrubbing response to remove metadata." "INFO"
  logThis "Executing command: [cat ${1}.response | jq \"del(.disableRefreshInLiveMode) | del(.hideChartWarning) | \
  del(.creatorId) | del(.updaterId) | del(.createdEpochMillis) | del(.updatedEpochMillis) | \
  del(.deleted) | del(.numCharts) | del(.numFavorites) | del(.favorite)\" > ${1}]" "DEBUG"
  cat $1.response | \
  jq "del(.disableRefreshInLiveMode) | \
  del(.hideChartWarning) | \
  del(.creatorId) | \
  del(.updaterId) | \
  del(.createdEpochMillis) | \
  del(.updatedEpochMillis) | \
  del(.deleted) | \
  del(.numCharts) | \
  del(.numFavorites) | \
  del(.favorite)" > $1  && logThis "Successfully scrubbed JSON response body." "INFO" || logThis "Could not scrub JSON response body from file ${1}.response." "CRITICAL"
}

function getDashboard {
  logThis "Checking dashboard retrieval output directory ${sourceDir}." "INFO"
  if [ -d $sourceDir ];
  then
    logThis "Directory ${sourceDir} exists." "DEBUG"
  else
    mkdir -p $sourceDir && logThis "Successfully created ${sourceDir}." "INFO" || logThis "Error creating directory ${sourceDir}." "CRITICAL"
  fi
  logThis "Retrieving Dashboard ${dashboardID}." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o $sourceDir/$dashboardID.json \"${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
  curl -X 'GET' -o $sourceDir/$dashboardID.json \
    "${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${api_token}" && logThis "Successfully retrieved dashboard ${dashboardID}." "INFO" || logThis "Could not retrieve dashboard ${dashboardID}." "CRITICAL"
}

function getWorkingCopyDashboard {
  logThis "Checking dashboard retrieval output directory ${dashboardDir}." "INFO"
  if [ -d $dashboardDir ];
  then
    logThis "Directory ${dashboardDir} exists." "DEBUG"
  else
    mkdir -p $dashboardDir && logThis "Successfully created ${dashboardDir}." "INFO" || logThis "Error creating directory ${dashboardDir}." "CRITICAL"
  fi
  if [ -f $dashboardDir/$dashboardID.json ];
  then
    read -p "Replace file ${dashboardDir}/${dashboardID}.json? (yes/no) " yn
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
  logThis "Executing command:  [curl -X 'GET' -o $dashboardDir/$dashboardID.json \"${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
  curl -X 'GET' -o $dashboardDir/$dashboardID.json \
    "${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${api_token}" && logThis "Successfully retrieved dashboard ${dashboardID}." "INFO" || logThis "Could not retrieve dashboard ${dashboardID}." "CRITICAL"
}

function pushDashboard {
  logThis "Publishing Dashboard ${dashboardID}" "INFO"
  logThis "Executing command:  [curl -X 'PUT' --data \"@${responseDir}/${dashboardID}.json\" \"${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
  curl -X 'PUT' --data "@${responseDir}/${dashboardID}.json" \
    "${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${api_token}" && logThis "Successfully pushed dashboard ${dashboardID}." "INFO" || logThis "Could not pushed dashboard ${dashboardID}." "CRITICAL"
}

function processCloneFileName {
  logThis "Stripping working copy Clone tags from filename ${1} before publishing." "INFO"
  echo 'file process'
  newFILENAME=$(echo $_FILENAME | awk -F '-Clone-' '{print $1}').json
  logThis "Rename the file ${responseDir}/${_FILENAME}.response to ${responseDir}/${newFILENAME}.response" "INFO"
  echo $_FILENAME
  echo $newFILENAME
  mv $responseDir/$_FILENAME.response $responseDir/$newFILENAME.response
  _FILENAME=$newFILENAME
  unset newFILENAME

}

function processCloneID {
  logThis "Stripping working copy Clone tags from file ${1} before publishing." "INFO"
  local _dashboardID=$(echo $dashboardID | awk -F '-Clone-' '{print $1}')
  logThis "Changing (dashboardID) in file from ${dashboardID} to ${_dashboardID} in file $_FILENAME." "DEBUG"
  sed -i '.clone' "s/${dashboardID}/${_dashboardID}/g" $responseDir/$_FILENAME.response
  logThis "Changing dashboard name to remove the (Clone) designation." "DEBUG"
  sed -i '' -E 's/ \(Clone\)//' $responseDir/$_FILENAME.response
  logThis "Changing (dashboardID) variable from ${dashboardID} to ${_dashboardID}." "DEBUG"
  dashboardID=$_dashboardID
}
