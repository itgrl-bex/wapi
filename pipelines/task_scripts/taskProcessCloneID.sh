#!/bin/bash

##################################################################################
#
# Purpose is to provide task for use with Pipelines
#
##################################################################################

## Load init to load the config
# shellcheck source="../../init.sh"
source "../../init.sh"
unset myDir

## Load common functions
# shellcheck source="../../lib/common.sh"
source "../../lib/common.sh"
# shellcheck source="../../lib/libDashboard.sh"
source "../../lib/libDashboard.sh"

# Loop through dashboard files in dashboard dir
# shellcheck disable=SC2154 # Reusable code for tasks, the config with this is part of init.
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
      # shellcheck disable=SC2154 # Reusable code for tasks, the config with this is part of init.
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
done
