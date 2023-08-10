#!/bin/bash

############################################################################
#
# To be executed by concourse pipelines to initialize environment for tasks 
#
############################################################################

# Set GLOBALS
baseDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
config="${baseDir}/cfg/config.yaml"

## Load common functions
source "${baseDir}/lib/common.sh"

## Read Config file
if validateYAML "${config}";
then
  echo 'i am groot.'
  # shellcheck disable=SC2046
  eval $(yq -o=shell "${config}" )
else
  echo 'i am not groot'
  echo "Configuration file ${config} is not valid yaml."
  exit 1
fi

## Logging configuration
dateTime="$(date +%Y-%m-%d) $(date +%T%z)" # Date format at beginning of log entries to match RFC
dateForFileName=$(date +%Y%m%d)
# shellcheck disable=SC2154 # Reusable code for tasks, the config is loaded and used later in the tasks.
scriptLogDir="${CONF_logging_dir}/${CONF_appName}"
scriptLogPath="${scriptLogDir}/${CONF_appName}-${dateForFileName}.log"
# shellcheck disable=SC2154 # Reusable code for tasks, the config is loaded and used later in the tasks.
scriptLoggingLevel="${CONF_logging_level}"

# Setting apiToken value
if [[ -n "${CONF_aria_apiToken}" ]];
then
  apiToken=$CONF_aria_apiToken
  unset CONF_aria_apiToken
fi

echo "##########################################################################################"
echo "Launching ${1}"
# shellcheck disable=SC1090
source "${1}"
