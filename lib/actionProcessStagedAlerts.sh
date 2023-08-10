#!/bin/bash

############################################################
#
# Purpose is to remove action specific logic to files.
# Reason is to simply and shorten main calling script.
# Benefit is that logic for specific action is easy to maintain.
#
############################################################

## Load common functions
# shellcheck disable=SC1091 disable=SC2154
source "${baseDir}/lib/common.sh"
source "${baseDir}/lib/libAlert.sh"

# Load appropriate git functions based on appropriate git management platform being used.
# shellcheck disable=SC1090 disable=SC2154
source "${baseDir}/lib/lib${CONF_repoManagementPlatform}.sh"


# Process Alert workflow maintenance window creation according to configuration.
# shellcheck disable=SC1091 disable=SC2154
source "${baseDir}/lib/actionMaintenanceWindow.sh"

# Set Alert Scrub body to remove variant data later.
# shellcheck disable=SC2086
scrubBody="$(cat ${baseDir}/templates/scrubBodyAlert.template)"

# Check to see if single repo or split code and data repos
if "${REPO_git_dataRepo}";
then
  echo 'split data'
  createDir "${CONF_dataPath}"
  if [[ -z "${REPO_git_data_api_token}" ]];
  then
    apiGitToken="${REPO_git_api_token}"
  else
    apiGitToken="${REPO_git_data_api_token}"
  fi
  dataPath="${REPO_git_data_path}/${REPO_git_data_repo}"
  gitRepo="${REPO_git_data_repoOwner}/${REPO_git_data_repo}"
  repoSshUrl="${REPO_git_data_repoSshUrl}"
  sshKey="${REPO_git_data_sshKey}"
  gitRepoBaseBranch="${REPO_git_data_branch_base}"
  gitBranchNameTemplate="${baseDir}/${REPO_git_data_branch_template_nameFormat}"
  gitCommitMessageTemplate="${baseDir}/${REPO_git_data_branch_template_commitMessage}"
  gitIssueEnabled="${REPO_git_data_issue_enabled}"
  gitIssueMessageTemplate="${baseDir}/${REPO_git_data_issue_template}"
  gitIssueSubjectTemplate="${baseDir}/${REPO_git_data_issue_subject}"
  gitPRMessageTemplate="${baseDir}/${REPO_git_data_pullRequest_template}"
  gitPRSubjectTemplate="${baseDir}/${REPO_git_data_pullRequest_subject}"
else
  echo "Single repo"
  if [[ -z "${REPO_git_code_api_token}" ]];
  then
    apiGitToken="${REPO_git_api_token}"
  else
    apiGitToken="${REPO_git_code_api_token}"
  fi
  dataPath="${REPO_git_code_path}/${REPO_git_code_repo}"
  gitRepo="${REPO_git_code_repoOwner}/${REPO_git_code_repo}"
  repoSshUrl="${REPO_git_code_repoSshUrl}"
  sshKey="${REPO_git_code_sshKey}"
  gitRepoBaseBranch="${REPO_git_code_branch_base}"
  gitBranchNameTemplate="${baseDir}/${REPO_git_code_branch_template_nameFormat}"
  gitCommitMessageTemplate="${baseDir}/${REPO_git_code_branch_template_commitMessage}"
  gitIssueEnabled="${REPO_git_code_issue_enabled}"
  gitIssueMessageTemplate="${baseDir}/${REPO_git_code_issue_template}"
  gitIssueSubjectTemplate="${baseDir}/${REPO_git_code_issue_subject}"
  gitPRMessageTemplate="${baseDir}/${REPO_git_code_pullRequest_template}"
  gitPRSubjectTemplate="${baseDir}/${REPO_git_code_pullRequest_subject}"
fi

# Create the working directory 
createDir "${tmpDir}/${CONF_alert_dir}"

## Search for issuekey.issue tag from issue tracker file and remove if no objects found in API
# Logic to remove issuekey.issue from issue tracker file
while read -r l;
do
  i=$(echo ${l} | awk -F '::' '{print $1}')
  d=$(echo ${l} | awk -F '::' '{print $2}')

  getAlert "${d}"
  if grep "${i}" "${sourceDir}/${d}.json";
  then
    logThis "Issue ${i} is still actively being worked for alert ${d}." "INFO"
  else
    logThis "Issue ${i} is not tagged on working copy alert ${d} and will be removed." "INFO"
    # Saving deletes to a temp file to prevent reading and writing in the same loop.
    echo "${l}" >> "${tmpDir}/issueTrackerDeletes"
  fi
done < "${alertDir}/issueTracker"

# Looping through the deletes file to remove entries from "${alertDir}/issueTracker"
if [ -f "${tmpDir}/issueTrackerDeletes" ];
then
  while read -r l;
  do
    sed -i "${l}/d" "${alertDir}/issueTracker"
  done
fi

for alert in $(searchTag 'alert' "${CONF_alert_staged_tag}");
do
  alertID="${alert}"
  getAlert "${alert}"
  filename="${sourceDir}/${alert}.json"
  _FILENAME=$(basename "${filename}")
  getAlertID "${filename}" "${responseDir}"
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

  # Get updater
  # shellcheck disable=SC2034 # This is used later in templates.
  author=$(jq -r ".response.updaterId"  "${filename}")

  scrubResponse "${responseDir}/${_FILENAME}" "${scrubBody}"

  if (jq -r ".tags.customerTags" "${responseDir}/${_FILENAME}" | grep "${CONF_alert_staged_tag}");
  then
    sed -i '' "s/${CONF_alert_staged_tag}/${CONF_alert_published_tag}/g" "${responseDir}/${_FILENAME}"
  else
    echo "Staged tag not set" # So why are we processing this?
  fi

  if (jq -r ".tags.customerTags" "${responseDir}/${_FILENAME}" | grep "${REPO_tracker_issueTagPrefix}");
  then
    # shellcheck disable=SC2034 # This is used later in templates.
    issueKey=$(jq -r ".tags.customerTags" "${responseDir}/${_FILENAME}" | grep "${REPO_tracker_issueTagPrefix}" | awk -F '"' '{print $2}' | awk -F '.' '{print $2}')
  else
    logThis "${REPO_tracker_issueTagPrefix} issue key not set. It is required to set the issue to link everything together." "ERROR"
    removeTag "${alert}" 'alert' "${CONF_alert_staged_tag}"
    # TODO: Email author error with log message 
    continue
  fi
  
  # Copy file to dataDir to process PR
  if validateJSON "${responseDir}/${_FILENAME}";
  then
    ## Remove issuekey before comparing.
    cp "${responseDir}/${_FILENAME}" "${responseDir}/${_FILENAME}.removeissuekey"
    echo "Running command [jq \"del(.tags.customerTags[] | select(. | contains(\"${REPO_tracker_issueTagPrefix}.\")))\" \"${responseDir}/${_FILENAME}.removeissuekey\" > \"${responseDir}/${_FILENAME}\"]"
    jq "del(.tags.customerTags[] | select(. | contains(\"${REPO_tracker_issueTagPrefix}.\")))" "${responseDir}/${_FILENAME}.removeissuekey" > "${responseDir}/${_FILENAME}"

    ### Logic to add issue to issue tracker file
    if grep "${trackedIssue}" "${alertDir}/issueTracker";
      logThis "Issue ${trackedIssue} for alert ${d} is already being tracked." "INFO"
    then
      logThis "Tracking issue ${trackedIssue} for alert ${d}." "INFO"
      echo "${trackedIssue}::${d}" >> "${alertDir}/issueTracker"
    fi

    createBranch 'alert' "${alert}" "${author}" "${gitBranchNameTemplate}" "${issueKey}" "${CONF_alert_staged_tag}"
    if [ -f "${alertDir}/${_FILENAME}" ];
    then
      if compareFile "${responseDir}/${_FILENAME}" "${alertDir}/${_FILENAME}";
      then
        logThis "Staged alert ${alert} found, updating changes." "INFO"        
        cp "${responseDir}/${_FILENAME}" "${alertDir}"
        commit 'alert' "${alert}" "${author}" "${gitCommitMessageTemplate}" "${issueKey}" "${CONF_alert_staged_tag}"
        gitPush
        if "${needPR}";
        then
          createPullRequest "${gitRepo}" "${REPO_git_api_url}" "${apiGitToken}" 'alert' "${alert}" "${gitRepoBaseBranch}" "${gitPRSubjectTemplate}" "${gitPRMessageTemplate}" "${CONF_alert_staged_tag}" "${alertID}"
        else
          logThis "PR ${prNum} exists for this alert ${alert}." "INFO"
        fi
      else
        logThis "Staged alert ${alert} found, but does not differ from repo copy." "INFO"
        continue
      fi
    else
      cp "${responseDir}/${_FILENAME}" "${alertDir}"
      commit 'alert' "${alert}" "${author}" "${gitCommitMessageTemplate}" "${issueKey}" "${CONF_alert_staged_tag}"
      gitPush
      # Check to see if there is an existing PR for this change.
      if "${needPR}";
      then
        echo "creating pull request with api token ${apiGitToken}"
        createPullRequest "${gitRepo}" "${REPO_git_api_url}" "${apiGitToken}" 'alert' "${alert}" "${gitRepoBaseBranch}" "${gitPRSubjectTemplate}" "${gitPRMessageTemplate}" "${CONF_alert_staged_tag}" "${alertID}"
      else
        logThis "PR ${prNum} exists for this alert ${alert}." "INFO"
      fi
    fi
  else
    logThis "JSON not valid for ${_FILENAME}." "ERROR"
    continue
  fi

done