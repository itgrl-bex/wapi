#!/bin/bash

##################################################################################
#
# Purpose is to find objects that have been tagged as staged changes.
# Reason is to simply development workflow and have tooling perform PR creation.
# Benefit is that there are less steps for a developer to have to follow.
#
##################################################################################


## Load common functions
# shellcheck disable=SC1091 disable=SC2154
source "${baseDir}/lib/common.sh"
source "${baseDir}/lib/libDashboard.sh"

# Load appropriate git functions based on appropriate git management platform being used.
# shellcheck disable=SC1090 disable=SC2154
source "${baseDir}/lib/lib${CONF_repoManagementPlatform}.sh"

scrubBody=scrubBody="del(.disableRefreshInLiveMode) | \
  del(.hideChartWarning) | \
  del(.creatorId) | \
  del(.updaterId) | \
  del(.createdEpochMillis) | \
  del(.updatedEpochMillis) | \
  del(.deleted) | \
  del(.numCharts) | \
  del(.numFavorites) | \
  del(.favorite)"

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

# Override working directories to use tmp until I can change the others to use tmpDir
createDir "${CONF_tmpDir}/dashboards"
# shellcheck disable=SC2154 # Reusable code for tasks, the config is loaded and used later in the tasks.
sourceDir="${CONF_tmpDir}/${CONF_dashboard_sourceDir}"
responseDir="${CONF_tmpDir}/dashboards/responses"
dashboardDir="${dataPath}/${CONF_dashboard_dir}"

for d in $(searchTag 'dashboard' "${CONF_dashboard_staged_tag}");
do
  dashboardID="${d}"
  getDashboard "${d}"
  filename="${sourceDir}/${d}.json"
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

  # Get updater
  # shellcheck disable=SC2034 # This is used later in templates.
  author=$(jq -r ".response.updaterId"  "${filename}")

  scrubResponse "${responseDir}/${_FILENAME}" "${scrubBody}"

  if (jq -r ".tags.customerTags" "${responseDir}/${_FILENAME}" | grep "${CONF_dashboard_staged_tag}");
  then
    sed -i '' "s/${CONF_dashboard_staged_tag}/${CONF_dashboard_published_tag}/g" "${responseDir}/${_FILENAME}"
  else
    echo "Staged tag not set" # So why are we processing this?
  fi

  if (jq -r ".tags.customerTags" "${responseDir}/${_FILENAME}" | grep "${REPO_tracker_issueTagPrefix}");
  then
    # shellcheck disable=SC2034 # This is used later in templates.
    issueKey=$(jq -r ".tags.customerTags" "${responseDir}/${_FILENAME}" | grep "${REPO_tracker_issueTagPrefix}" | awk -F '"' '{print $2}' | awk -F '.' '{print $2}')
  else
    logThis "${REPO_tracker_issueTagPrefix} issue key not set. It is required to set the issue to link everything together." "ERROR"
    removeTag "${d}" 'dashboard' "${CONF_dashboard_staged_tag}"
    # TODO: Email author error with log message 
    continue
  fi

  # Copy file to dataDir to process PR
  if validateJSON "${responseDir}/${_FILENAME}";
  then
    createBranch 'dashboard' "${d}" "${author}" "${gitBranchNameTemplate}" "${issueKey}" "${CONF_dashboard_staged_tag}"
    if [ -f "${dashboardDir}/${_FILENAME}" ];
    then
      if compareFile "${responseDir}/${_FILENAME}" "${dashboardDir}/${_FILENAME}";
      then
        logThis "Staged dashboard ${d} found, updating changes." "INFO"        
        cp "${responseDir}/${_FILENAME}" "${dashboardDir}"
        commit 'dashboard' "${d}" "${author}" "${gitCommitMessageTemplate}" "${issueKey}" "${CONF_dashboard_staged_tag}"
        gitPush
        if "${needPR}";
        then
          createPullRequest "${gitRepo}" "${REPO_git_api_url}" "${apiGitToken}" 'dashboard' "${d}" "${gitRepoBaseBranch}" "${gitPRSubjectTemplate}" "${gitPRMessageTemplate}" "${CONF_dashboard_staged_tag}" "${dashboardID}"
        else
          logThis "PR ${prNum} exists for this dashboard ${d}." "INFO"
        fi
      else
        logThis "Staged dashboard ${d} found, but does not differ from repo copy." "INFO"
        continue
      fi
    else
      cp "${responseDir}/${_FILENAME}" "${dashboardDir}"
      commit 'dashboard' "${d}" "${author}" "${gitCommitMessageTemplate}" "${issueKey}" "${CONF_dashboard_staged_tag}"
      gitPush
      # Check to see if there is an existing PR for this change.
      if "${needPR}";
      then
        echo "creating pull request with api token ${apiGitToken}"
        createPullRequest "${gitRepo}" "${REPO_git_api_url}" "${apiGitToken}" 'dashboard' "${d}" "${gitRepoBaseBranch}" "${gitPRSubjectTemplate}" "${gitPRMessageTemplate}" "${CONF_dashboard_staged_tag}" "${dashboardID}"
      else
        logThis "PR ${prNum} exists for this dashboard ${d}." "INFO"
      fi
    fi
  else
    logThis "JSON not valid for ${_FILENAME}." "ERROR"
    continue
  fi

done
