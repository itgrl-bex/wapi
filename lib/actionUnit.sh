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

source "${baseDir}/lib/libDashboard.sh"
source "${baseDir}/lib/libAlert.sh"
source "${baseDir}/lib/libAccount.sh"
source "${baseDir}/lib/libGithub.sh"

# scrubBody="$(cat ${baseDir}/templates/scrubBodyDashboard.template)"

# # Becca's testing
# # Loop through dashboard files in dashboard dir
# for filename in "${dashboardDir}"/*.json; do
#     logThis "Processing ${filename}" "INFO"
#     _FILENAME=$(basename "${filename}")
#     getDashboardID "${filename}"
#     # Let's just copy the file to correct name since processed upon commit through staged processing.
#     cp "${responseDir}/${_FILENAME}.response" "${responseDir}/${_FILENAME}"

#     if getDashboard;
#     then
#       extractResponse "${sourceDir}/${_FILENAME}" "${sourceDir}"
#       scrubResponse "${sourceDir}/${_FILENAME}" "${scrubBody}"
#       if compareFile "${responseDir}/${_FILENAME}" "${sourceDir}/${_FILENAME}";
#       then
#         echo "I AM GROOOT!"
#         pushDashboard "${dashboardID}"
#       fi
#     else
#       if [[ ${#} == 3 ]];
#       then
#         logThis "Skipped processing dashboard ${dashboardID} due to fresh creation." "INFO"
#       else
#         logThis "An unexpected error has ocurred. Dashboard ${dashboardID} could not be retrieved or created." "SEVERE"
#       fi
#     fi

#     # Set the published tag as per the config
#     setTag "${dashboardID}" 'dashboard' "${CONF_dashboard_published_tag}"

#     # Clean up temp files?
#     if ${CONF_dashboard_cleanTmpFiles};
#     then
#       logThis "Cleaning up temp files" "INFO"
#       logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
#       rm -f "${responseDir}/*.response.clone"
#       rm -f "${responseDir}/*.response"
#       logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
#       rm -f "${sourceDir}/*.response.clone"
#       rm -f "${sourceDir}/*.response"
#     else
#       logThis "Leaving temp files" "INFO"
#     fi

#     setACL "${dashboardID}" "dashboard"
# done

# # Validate all dashboards with the tag defined in CONF_dashboard_published_tag have the proper ACL set.
# for d in $(searchTag 'dashboard' "${CONF_dashboard_published_tag}");
# do
#   echo "${dashboardDir}"
#   echo "grep \"${d}\" \"${dashboardDir}\"/*.json | grep '\"id\":' | awk -F '\"' '{print \$4}'"
#   dashboardPresent=$(grep "${d}" "${dashboardDir}"/*.json | grep '"id":' | awk -F '"' '{print $4}')
#   echo "${dashboardPresent}"
#   if [[ "${dashboardPresent}" == "${d}" ]];
#   then
#     logThis "Confirmed published dashboard ${d} in remote and in repo." "INFO"
#     setACL "${d}" "dashboard"
#   else
#     logThis "Confirmed published dashboard ${d} in remote and is not in the repo." "INFO"
#     logThis "Deleting published dashboard ${d} due to it not being in a file." "INFO"
#     # Delete functionality places dashboard in trash for 30 days to be able to be recovered.
#     # deleteDashboard "${d}"
#   fi
# done

# # source "${baseDir}/lib/actionProcessStagedDashboards.sh"


## Alert functionality testing


# Set Alert Scrub body to remove variant data later.
scrubBody="$(cat \"${baseDir}/templates/scrubBodyAlert.template\")"

# Loop through alert files in alert dir
for filename in "${alertDir}"/*.json; do
  logThis "Processing ${filename}" "INFO"
  _FILENAME=$(basename "${filename}")
  getAlertID "${filename}"
  if [[ "${_FILENAME}" == *"-Clone"* ]];
  then
    logThis "Detected that ${_FILENAME} has documented working copy clone tags." "INFO"
    processCloneFileName "${_FILENAME}" "${responseDir}"
    # Now that we have changed the filename, we need to process the alert name and alert ID.
    alertID=$(processCloneID 'alert' "${alertID}" "${_FILENAME}" "${responseDir}")
  else
    if [[ "${alertID}" == *"-Clone"* ]];
    then
      logThis "Detected that the alert ID (${alertID}) has documented working copy clone tags." "INFO"
      alertID=$(processCloneID 'alert' "${alertID}" "${_FILENAME}" "${responseDir}")
    else
      echo "Not a clone."
      echo "${_FILENAME}"
      echo "${alertID}"
    fi
  fi

    scrubResponse "${responseDir}/${_FILENAME}" "${scrubBody}"

  # if getAlert;
  # then
  #   extractResponse "${sourceDir}/${_FILENAME}" "${sourceDir}"
  #   scrubResponse "${sourceDir}/${_FILENAME}" "${scrubBody}"
  #   if compareFile "${responseDir}/${_FILENAME}" "${sourceDir}/${_FILENAME}";
  #   then
  #     pushAlert "${alertID}"
  #   fi
  # else
  #   if [[ ${#} == 3 ]];
  #   then
  #     logThis "Skipped processing alert ${alertID} due to fresh creation." "INFO"
  #   else
  #     logThis "An unexpected error has ocurred. alert ${alertID} could not be retrieved or created." "SEVERE"
  #   fi
  # fi

  # # Set the published tag as per the config
  # setTag "$alertID" 'alert' "${CONF_alert_published_tag}"

  # # Remove issueKey and staged tags
  # removeTag "$alertID" 'alert' "${CONF_alert_staged_tag}"
  # gitConfig="${baseDir}/cfg/${CONF_repoManagementPlatform}.yaml"

  # issueKeyPrefix=$(yq '.REPO.tracker.issueTagPrefix' "${gitConfig}")
  # removeTag "$alertID" 'alert' "${issueKeyPrefix}.*"

  # # Clean up temp files?
  # if ${CONF_alert_cleanTmpFiles};
  # then
  #   logThis "Cleaning up temp files" "INFO"
  #   logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
  #   rm -f "${responseDir}/*.response.clone"
  #   rm -f "${responseDir}/*.response"
  #   logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
  #   rm -f "${sourceDir}/*.response.clone"
  #   rm -f "${sourceDir}/*.response"
  # else
  #   logThis "Leaving temp files" "INFO"
  # fi

  # setACL "${alertID}" "alert"

done

# # Validate all alerts with the tag defined in CONF_alert_published_tag have the proper ACL set.
# for a in $(searchTag 'alert' "${CONF_alert_published_tag}");
# do
#   alertPresent=$(grep "${a}" "${alertDir}"/*.json | grep '"id":' | awk -F '"' '{print $4}')
#   if [[ "${alertPresent}" == "${a}" ]];
#   then
#     logThis "Confirmed published alert ${a} in remote and in repo." "INFO"
#     setACL "${a}" "alert"
#   else
#     logThis "Confirmed published alert ${a} in remote and is not in the repo." "INFO"
#     logThis "Deleting published alert ${a} due to it not being in a file." "INFO"
#     # Delete functionality places alert in trash for 30 days to be able to be recovered.
#     deleteAlert "${a}"
#   fi
# done

