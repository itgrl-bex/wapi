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

source "${baseDir}/lib/common.sh"
gitConfig="${baseDir}/cfg/gitlab.yaml"

## Read Config file
if validateYAML "${gitConfig}";
then
  eval $(yq -o=shell "${gitConfig}" )
else
  echo "Configuration file ${gitConfig} is not valid yaml."
  exit 1
fi

function cloneRepo {
  local msgType="${1}"
  local msgID="${2}"

}

function pullRepo {
  local msgType="${1}"
  local msgID="${2}"

}

function pruneRepo {
  local msgType="${1}"
  local msgID="${2}"

}

function createBranch {
  local msgType="${1}"
  local msgID="${2}"

}

function createIssue {
  local msgType="${1}"
  local msgID="${2}"
  
}

function getIssue {
  local msgType="${1}"
  local msgID="${2}"

}

function createPullRequest {
  local msgType="${1}"
  local msgID="${2}"

}

function getPullRequest {
  local msgType="${1}"
  local msgID="${2}"

}

function updateIssue {
  local msgType="${1}"
  local msgID="${2}"

}

function commit {
  local msgType="${1}"
  local msgID="${2}"

}

