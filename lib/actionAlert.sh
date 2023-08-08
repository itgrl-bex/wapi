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
source "${baseDir}/lib/libAlert.sh"

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

  # Failing
  if getAlert;
  then
    extractResponse "${sourceDir}/${_FILENAME}" "${sourceDir}"
    scrubResponse "${sourceDir}/${_FILENAME}" "${scrubBody}"
    if compareFile "${responseDir}/${_FILENAME}" "${sourceDir}/${_FILENAME}";
    then
      pushAlert "${alertID}"
    fi
  else
    if [[ ${#} == 3 ]];
    then
      logThis "Skipped processing alert ${alertID} due to fresh creation." "INFO"
    else
      logThis "An unexpected error has ocurred. alert ${alertID} could not be retrieved or created." "SEVERE"
    fi
  fi

  # Set the published tag as per the config
  setTag "$alertID" 'alert' "${CONF_alert_published_tag}"

  # Remove issueKey and staged tags
  removeTag "$alertID" 'alert' "${CONF_alert_staged_tag}"
  gitConfig="${baseDir}/cfg/${CONF_repoManagementPlatform}.yaml"

  issueKeyPrefix=$(yq '.REPO.tracker.issueTagPrefix' "${gitConfig}")
  removeTag "$alertID" 'alert' "${issueKeyPrefix}.*"

  # Clean up temp files?
  if ${CONF_alert_cleanTmpFiles};
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

  setACL "${alertID}" "alert"

done

# Validate all alerts with the tag defined in CONF_alert_published_tag have the proper ACL set.
for a in $(searchTag 'alert' "${CONF_alert_published_tag}");
do
  alertPresent=$(grep "${a}" "${alertDir}"/*.json | grep '"id":' | awk -F '"' '{print $4}')
  if [[ "${alertPresent}" == "${a}" ]];
  then
    logThis "Confirmed published alert ${a} in remote and in repo." "INFO"
    setACL "${a}" "alert"
  else
    logThis "Confirmed published alert ${a} in remote and is not in the repo." "INFO"
    logThis "Deleting published alert ${a} due to it not being in a file." "INFO"
    # Delete functionality places alert in trash for 30 days to be able to be recovered.
    deletealert "${a}"
  fi
done
