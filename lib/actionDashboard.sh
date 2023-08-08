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

scrubBody="$(cat ${baseDir}/templates/scrubBodyDashboard.template)"

# Loop through dashboard files in dashboard dir
for filename in "${dashboardDir}"/*.json; do
  logThis "Processing ${filename}" "INFO"
  _FILENAME=$(basename "${filename}")
  getDashboardID "${filename}"
  # Let's just copy the file to correct name since processed upon commit through staged processing.
  cp "${responseDir}/${_FILENAME}.response" "${responseDir}/${_FILENAME}"

  # Failing
  if getDashboard;
  then
    extractResponse "${sourceDir}/${_FILENAME}" "${sourceDir}"
    scrubResponse "${sourceDir}/${_FILENAME}" "${scrubBody}"
    if compareFile "${responseDir}/${_FILENAME}" "${sourceDir}/${_FILENAME}";
    then
      pushDashboard "${dashboardID}"
    fi
  else
    if [[ ${#} == 3 ]];
    then
      logThis "Skipped processing dashboard ${dashboardID} due to fresh creation." "INFO"
    else
      logThis "An unexpected error has ocurred. Dashboard ${dashboardID} could not be retrieved or created." "SEVERE"
    fi
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
  dashboardPresent=$(grep "${d}" "${dashboardDir}"/*.json | grep '"id":' | awk -F '"' '{print $4}')
  if [[ "${dashboardPresent}" == "${d}" ]];
  then
    logThis "Confirmed published dashboard ${d} in remote and in repo." "INFO"
    setACL "${d}" "dashboard"
  else
    logThis "Confirmed published dashboard ${d} in remote and is not in the repo." "INFO"
    logThis "Deleting published dashboard ${d} due to it not being in a file." "INFO"
    # Delete functionality places dashboard in trash for 30 days to be able to be recovered.
    deleteDashboard "${d}"
  fi
done
