#!/bin/bash

##################################################################################
#
# Use this action to process all dashboard json files 
# 
# Purpose is to remove action specific logic to files.
# Reason is to simply and shorten main calling script.
# Benefit is that logic for specific action is easy to maintain.
#
##################################################################################


## Load common functions
source "${baseDir}/lib/common.sh"

source "${baseDir}/lib/libDashboard.sh"

# Loop through dashboard files in dashboard dir
for filename in "${dashboardDir}"/*.json; do
  logThis "Processing ${filename}" "INFO"
  _FILENAME=$(basename "${filename}")
  getDashboardID "${filename}"
  if [[ "${_FILENAME}" == *"-Clone"* ]];
  then
    logThis "Detected that ${_FILENAME} has documented working copy clone tags." "INFO"
    processCloneFileName "${_FILENAME}"
    # Now that we have changed the filename, we need to process the dashboard name and dashboard ID.
    processCloneID "${_FILENAME}"
  else
    if [[ "${dashboardID}" == *"-Clone"* ]];
    then
      logThis "Detected that the dashboard ID (${dashboardID}) has documented working copy clone tags." "INFO"
      processCloneID "${_FILENAME}"
    else
      echo "Not a clone."
      echo "${_FILENAME}"
      echo "${dashboardID}"
    fi
  fi

  scrubResponse "${responseDir}/${_FILENAME}"

  getDashboard "${dashboardID}"
  extractResponse "${sourceDir}/${_FILENAME}" "${sourceDir}"
  scrubResponse "${sourceDir}/${_FILENAME}"
  if compareFile "${responseDir}/${_FILENAME}" "${sourceDir}/${_FILENAME}";
  then
    pushDashboard "${dashboardID}"
  fi

  # Set the published tag as per the config
  setTag "$dashboardID" 'dashboard' "${CONF_dashboard_published_tag}"

  # Clean up temp files?
  if ${CONF_dashboard_cleanTmpFiles};
  then
    logThis "Cleaning up temp files" "INFO"
    logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
    rm -f "${responseDir}/*.response.clone"
    rm -f "${responseDir}/*.response"
    logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
    rm -f "${sourceDir}/*.response.clone"
    rm -f "${sourceDir}/*.response"
  else
    logThis "Leaving temp files" "INFO"
  fi

  setACL "${dashboardID}" "dashboard"
done

# Validate all dashboards with the tag defined in CONF_dashboard_published_tag have the proper ACL set.
for d in $(searchTag 'dashboard' "${CONF_dashboard_published_tag}");
do
  setACL "${d}" "dashboard"
done
