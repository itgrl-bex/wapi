#!/bin/bash

#############################################################################
#
# Collection of functions for git actions
# Function names, output and operation should be identical across platforms
# Idea is that as additional technologies are defined, the core operations 
# will not change, the libraries will change how it does it, but what it 
# does will remain the same.
#
#############################################################################

# shellcheck source=./common.sh
source "${baseDir}/lib/common.sh"
gitConfig="${baseDir}/cfg/github.yaml"

## Read Config file
if validateYAML "${gitConfig}";
then
  eval "$(yq -o=shell ${gitConfig} )"
else
  echo "Configuration file ${config} is not valid yaml."
  exit 1
fi

function cloneRepo {
  # TODO: Document and log
  local repo="${1}"
  local path="${2}"
  cd "${path}/../" || echo 'failed to change directories'
  git clone "${repo}"
}

function pullRepo {
  # TODO: Document and log  
  local repo="${1}"
  local path="${2}"
  cd "${path}/${repo}" || echo 'failed to change directories'
  git pull --rebase
}

function pruneRepo {
  local repo="${1}"
  local path="${2}"
  # TODO: Document and log
  cd "${path}/${repo}" || echo 'failed to change directories'
  git fetch -p
}

function createBranch {
  # shellcheck disable=SC2034 # Variable used in template
  local msgType="${1}"
  # shellcheck disable=SC2034 # Variable used in template
  local msgID="${2}"
  # shellcheck disable=SC2034 # Variable used in template
  local author="${3}"
  local template="${4}"
  # shellcheck disable=SC2034 # Variable used in template
  local issue="${5}"
  # shellcheck disable=SC2034 # Variable used in template
  local tag="${6}"
  local branchName
  # Evaluate template for message.
  # shellcheck disable=SC2034 disable=SC2086
  branchName=$(eval "cat <<EOF
$(<${template})
EOF
" 2> /dev/null)

  # Make sure we are in the repo directory.
  cd "${dataPath}" || echo 'failed to change directories'

  if git rev-parse --verify "${branchName}" 2>/dev/null;
  then 
    logThis "Branch ${branchName} exists, no PR needed." "INFO"
    git checkout "${branchName}"
    needPR=false
  else
    logThis "Branch ${branchName} does not exist, PR is needed." "INFO"
    git checkout -b "${branchName}"
    needPR=true
  fi

}

function createIssue {
  # TODO: Code ability to create an issue.
  local msgType="${1}"
  local msgID="${2}"
  echo "TODO"
}

function getIssue {
  # TODO: Code to get issue before creating issue
  local issue="${1}"
  echo "TODO"
}

function updateIssue {
  local msgType="${1}"
  local msgID="${2}"
  echo "TODO"
}

function createPullRequest {
  local repo="${1}"
  local url="${2}"
  local token="${3}"
  local msgType="${4}"
  local msgID="${5}"
  local baseBranch="${6}"
  local titleTemplate="${7}"
  local msgTemplate="${8}"
  local tag="${9}"
  # shellcheck disable=SC2034
  local msgIDpublished="${10}"
  local currentBranch
  currentBranch="$(git branch --show-current)"
  local msg
  local title
  # shellcheck disable=SC2046 disable=SC2086
  msg=$(eval "cat <<EOF
$(<${msgTemplate})
EOF
" 2> /dev/null)
  # shellcheck disable=SC2046 disable=SC2086
  title=$(eval "cat <<EOF
$(<${titleTemplate})
EOF
" 2> /dev/null)
  curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${url}/repos/${repo}/pulls" \
    -d "{\"title\":\"${title}\",\"body\":\"${msg}\",\"head\":\"${currentBranch}\",\"base\":\"${baseBranch}\"}"
}

function listPullRequest {
  local repo="${1}"
  local url="${2}"
  local token="${3}"
  curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "${url}/repos/${repo}/pulls"
}

function getPullRequest {
  local repo="${1}"
  local url="${2}"
  local token="${3}"
  local pr="${4}"
  cd "${path}/${repo}" || echo 'failed to change directories'
  curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "${url}/repos/${repo}/pulls/${pr}"
}

function commit {
  # shellcheck disable=SC2034 # Variable used in template
  local msgType="${1}"
  # shellcheck disable=SC2034 # Variable used in template
  local msgID="${2}"
  local author="${3}"
  local template="${4}"
  # shellcheck disable=SC2034 # Variable used in template
  local issue="${5}"
  # shellcheck disable=SC2034 # Variable used in template
  local tag="${6}"
  local message
  # Evaluate template for message.
  # shellcheck disable=SC2046 disable=SC2086
  message=$(eval "cat <<EOF
$(<${template})
EOF
" 2> /dev/null)

  local authorName
  authorName=$(echo "${author}" | awk -F '@' '{print $1}')

  cd "${dataPath}" || echo 'failed to change directories'
  git add .

  git commit --author="${authorName} <${author}>" -am "${message}"
}

function gitPush {
  local branchName="${1}"
  cd "${dataPath}" || echo 'failed to change directories'
  git config push.autoSetupRemote true
  git push 
}
