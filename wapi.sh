#!/bin/bash

############################################################
#
# To be executed by concourse pipelines after merge 
#
############################################################

# Set GLOBALS
baseDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
config="${baseDir}/cfg/config.yaml"

## Load common functions
source "${baseDir}/lib/common.sh"

## Read Config file
if validateYAML $config;
then
  eval $(yq -o=shell $config )
else
  echo 'Configuration file ${config} is not valid yaml.'
  exit 1
fi

# If dataPath is set in the config, use it.
# Otherwise use the script base directory of ${baseDir}

if [[ -z "${CONF_dataPath}" ]];
then
  dashboardDir="${baseDir}/${CONF_dashboard_dir}"
  sourceDir="${baseDir}/${CONF_dashboard_sourceDir}"
  responseDir="${dashboardDir}/responses"
  accountDir="${baseDir}/${CONF_account_dir}"
  alertDir="${baseDir}/${CONF_alert_dir}"
else
  createDir "${CONF_dataPath}"
  dashboardDir="${CONF_dataPath}${CONF_dashboard_dir}"
  sourceDir="${CONF_dataPath}${CONF_dashboard_sourceDir}"
  responseDir="${dashboardDir}/responses"
  accountDir="${CONF_dataPath}${CONF_account_dir}"
  alertDir="${CONF_dataPath}${CONF_alert_dir}"
fi

## Logging configuration
dateTime="`date +%Y-%m-%d` `date +%T%z`" # Date format at beginning of log entries to match RFC
dateForFileName=`date +%Y%m%d`
scriptLogDir="${CONF_logging_dir}/${CONF_appName}"
scriptLogPath="${scriptLogDir}/${CONF_appName}-${dateForFileName}.log"
scriptLoggingLevel="${CONF_logging_level}"
# Setting apiToken value
if [[ ! -z "${CONF_aria_apiToken}" ]];
then
  apiToken=$CONF_aria_apiToken
  unset CONF_aria_apiToken
fi

# Get the options
while getopts "bdua :hi:s:t:" option; do
   case $option in
      b) # Becca's test code
          action=unit
          actionCode="${baseDir}/lib/actionUnit.sh"
          ;;
      d) # Execute Dashboard logic
          action='dashboard'
          actionCode="${baseDir}/lib/actionDashboard.sh"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Executing Dashboard Management Logic." "INFO"
          ;;
      u) # Execute Account logic
          action='account'
          actionCode="${baseDir}/lib/actionAccount.sh"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Executing Account Management Logic for roles, groups, and group membership." "INFO"
          ;;
      a) # Execute Alert logic
          action='alert'
          actionCode="${baseDir}/lib/actionAlert.sh"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Executing Alert Management Logic." "INFO"
          ;;
      i) # Dashboard ID
          # The ID of the Dashboard to publish
          action='single_dashboard'
          actionCode="${baseDir}/lib/actionSingleDashboard.sh"
          dashboard_ID="${OPTARG}"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Received Dashboard ID for specific Dashboard Logic." "INFO"
          ;;
      s) # Source Dashboard ID
          # The ID of the published Dashboard
          action='single_dashboard'
          actionCode="${baseDir}/lib/actionSingleDashboard.sh"
          source_id="${OPTARG}"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Received Source Dashboard ID for specific Dashboard Logic." "INFO"
          ;;
      t) # API Token
          logThis "Overriding the config file API token values." "INFO"
          apiToken="${OPTARG}"
          if [[ ! -z "${CONF_account_apiToken}" ]];
          then
            logThis "Clearing variable CONF_account_apiToken due to override." "INFO"
            unset CONF_account_apiToken
          fi
          if [[ ! -z "${CONF_alert_apiToken}" ]];
          then
            logThis "Clearing variable CONF_alert_apiToken due to override." "INFO"
            unset CONF_alert_apiToken
          fi
          if [[ ! -z "${CONF_dashboard_apiToken}" ]];
          then
            logThis "Clearing variable CONF_dashboard_apiToken due to override." "INFO"
            unset CONF_dashboard_apiToken
          fi
          ;;
      *) # display help info
          help
          ;;
   esac
done

case $action in

  account)
    echo "Let's modify some groups"
    if [[ ! -z "${CONF_account_apiToken}" ]];
    then
      apiToken=$CONF_account_apiToken
      unset CONF_aria_apiToken
    fi
    source $actionCode 
    ;;

  alert)
    echo "Let's publish some alerts"
    if [[ ! -z "${CONF_alert_apiToken}" ]];
    then
      apiToken=$CONF_alert_apiToken
      unset CONF_aria_apiToken
    fi
    source $actionCode
    ;;

  dashboard)
    if [[ ! -z "${CONF_dashboard_apiToken}" ]];
    then
      apiToken=$CONF_dashboard_apiToken
      unset CONF_dashboard_apiToken
    fi
    source $actionCode
    ;;

  single_dashboard)
    if [[ ! -z "${CONF_dashboard_apiToken}" ]];
    then
      apiToken=$CONF_dashboard_apiToken
      unset CONF_dashboard_apiToken
    fi
    source $actionCode
    ;;

  unit)
    echo "Executing external action code actionUnit.sh"
    source $actionCode
    ;;

  *)
    echo "You forgot to tell me what to do"
    help
    ;;

esac