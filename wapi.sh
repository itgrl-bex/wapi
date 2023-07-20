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

# If data_path is set in the config, use it.
# Otherwise use the script base directory of ${baseDir}

if [[ -z "${CONF_data_path}" ]];
then
  dashboardDir="${baseDir}/${CONF_dashboard_dir}"
  sourceDir="${baseDir}/${CONF_dashboard_sourceDir}"
  responseDir="${dashboardDir}/responses"
  accountDir="${baseDir}/${CONF_account_dir}"
  alertDir="${baseDir}/${CONF_alert_dir}"
else
  createDir "${CONF_data_path}"
  dashboardDir="${CONF_data_path}${CONF_dashboard_dir}"
  sourceDir="${CONF_data_path}${CONF_dashboard_sourceDir}"
  responseDir="${dashboardDir}/responses"
  accountDir="${CONF_data_path}${CONF_account_dir}"
  alertDir="${CONF_data_path}${CONF_alert_dir}"
fi

## Logging configuration
dateTime="`date +%Y-%m-%d` `date +%T%z`" # Date format at beginning of log entries to match RFC
dateForFileName=`date +%Y%m%d`
scriptLogDir="${CONF_logging_dir}/${CONF_app_name}"
scriptLogPath="${scriptLogDir}/${CONF_app_name}-${dateForFileName}.log"
scriptLoggingLevel="${CONF_logging_level}"
# Setting api_token value
if [[ ! -z "${CONF_aria_api_token}" ]];
then
  api_token=$CONF_aria_api_token
  unset CONF_aria_api_token
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
          api_token="${OPTARG}"
          if [[ ! -z "${CONF_account_api_token}" ]];
          then
            logThis "Clearing variable CONF_account_api_token due to override." "INFO"
            unset CONF_account_api_token
          fi
          if [[ ! -z "${CONF_alert_api_token}" ]];
          then
            logThis "Clearing variable CONF_alert_api_token due to override." "INFO"
            unset CONF_alert_api_token
          fi
          if [[ ! -z "${CONF_dashboard_api_token}" ]];
          then
            logThis "Clearing variable CONF_dashboard_api_token due to override." "INFO"
            unset CONF_dashboard_api_token
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
    if [[ ! -z "${CONF_account_api_token}" ]];
    then
      api_token=$CONF_account_api_token
      unset CONF_aria_api_token
    fi
    source $actionCode 
    ;;

  alert)
    echo "Let's publish some alerts"
    if [[ ! -z "${CONF_alert_api_token}" ]];
    then
      api_token=$CONF_alert_api_token
      unset CONF_aria_api_token
    fi
    source $actionCode
    ;;

  dashboard)
    if [[ ! -z "${CONF_dashboard_api_token}" ]];
    then
      api_token=$CONF_dashboard_api_token
      unset CONF_dashboard_api_token
    fi
    source $actionCode
    ;;

  single_dashboard)
    if [[ ! -z "${CONF_dashboard_api_token}" ]];
    then
      api_token=$CONF_dashboard_api_token
      unset CONF_dashboard_api_token
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