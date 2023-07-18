#!/bin/bash

############################################################
#
#
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

dashboardDir="${baseDir}${CONF_dashboard_dir}"
sourceDir="${baseDir}${CONF_dashboard_sourceDir}"
responseDir="${dashboardDir}/responses"
accountDir="${baseDir}${CONF_account_dir}"
alertDir="${baseDir}${CONF_alert_dir}"

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
          source ${baseDir}/lib/libdashboard.sh
          source ${baseDir}/lib/libalert.sh
          source ${baseDir}/lib/libaccount.sh
          action=unit
          ;;
      d) # Execute Dashboard logic
          source ${baseDir}/lib/libdashboard.sh
          action='dashboard'
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Executing Dashboard Management Logic." "INFO"
          ;;
      u) # Execute Account logic
          source ${baseDir}/lib/libaccount.sh
          action='account'
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Executing Account Management Logic for roles, groups, and group membership." "INFO"
          ;;
      a) # Execute Alert logic
          source ${baseDir}/lib/libalert.sh
          action='alert'
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Executing Alert Management Logic." "INFO"
          ;;
      i) # Dashboard ID
          # The ID of the published Dashboard
          source ${baseDir}/lib/libdashboard.sh
          dashboard_ID="${OPTARG}"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Received Dashboard ID for specific Dashboard Logic." "INFO"
          action='single_dashboard'
          ;;
      s) # Source Dashboard ID
          source ${baseDir}/lib/libdashboard.sh
          source_id="${OPTARG}"
          logThis "The -${option} flag was set." "DEBUG"
          logThis "Received Source Dashboard ID for specific Dashboard Logic." "INFO"
          action='single_dashboard'
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
    ;;

  alert)
    echo "Let's publish some alerts"
    if [[ ! -z "${CONF_alert_api_token}" ]];
    then
      api_token=$CONF_alert_api_token
      unset CONF_aria_api_token
    fi
    ;;

  dashboard)
    if [[ ! -z "${CONF_dashboard_api_token}" ]];
    then
      api_token=$CONF_dashboard_api_token
      unset CONF_dashboard_api_token
    fi

    # Loop through dashboard files in dashboard dir
    for filename in $dashboardDir/*.json; do
      echo $dashboardDir
      logThis "Processing ${filename}" "INFO"
      _FILENAME=$(basename $filename)
      getDashboardID $filename
      if [[ "${_FILENAME}" == *"-Clone-"* ]];
      then
        logThis "Detected that ${_FILENAME} has documented working copy clone tags." "INFO"
        processCloneFileName $_FILENAME
        # Now that we have changed the filename, we need to process the dashboard name and dashboard ID.
        processCloneID $_FILENAME
      else
        if [[ "${dashboardID}" == *"-Clone-"* ]];
        then
          logThis "Detected that the dashboard ID (${dashboardID}) has documented working copy clone tags." "INFO"
          processCloneID $_FILENAME
        else
          echo "Not a clone."
          echo $_FILENAME
          echo $dashboardID
        fi
      fi

      scrubResponse $responseDir/$_FILENAME

      getDashboard $dashboardID
      extractResponse $sourceDir/$_FILENAME $sourceDir
      scrubResponse $sourceDir/$_FILENAME
      if compareFile $responseDir/$_FILENAME $sourceDir/$_FILENAME
      then
        pushDashboard $dashboardID
      fi

      # Clean up temp files?
      if ${CONF_dashboard_clean_tmp_files};
      then
        logThis "Cleaning up temp files" "INFO"
        logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
        rm -f ${responseDir}/*.clone
        rm -f ${responseDir}/*.clone.response
        logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
        rm -f ${sourceDir}/*.clone
        rm -f ${sourceDir}/*.clone.response
      else
        logThis "Leaving temp files" "INFO"
      fi
    done
    ;;

  single_dashboard)
    if [[ ! -z "${CONF_dashboard_api_token}" ]];
    then
      api_token=$CONF_dashboard_api_token
      unset CONF_dashboard_api_token
    fi

    _FILENAME="${dashboardID}.json"
    getDashboardID $_FILENAME 
    # Let's make sure the extracted dashboard ID and the file dashboard ID match.
    if [[ "${dashboardID}" == "${dashboard_ID}" ]];
    then
      # un-setting option value since the extracted value matches to free memory.
      unset dashboard_ID
    else
      logThis "Extracting dashboardID from file ${1} returned value of ${dashboardID} when ${dashboard_ID} was provided." "SEVERE"
    fi

    # Process Clone tags in name, Dashboard ID, and URL
    if [[ "${_FILENAME}" == *"-Clone-"* ]];
    then
      logThis "Detected that ${_FILENAME} has documented working copy clone tags." "INFO"
      processCloneFileName $_FILENAME
      # Now that we have changed the filename, we need to process the dashboard name and dashboard ID.
      processCloneID $_FILENAME
    else
      if [[ "${dashboardID}" == *"-Clone-"* ]];
      then
        logThis "Detected that the dashboard ID (${dashboardID}) has documented working copy clone tags." "INFO"
        processCloneID $_FILENAME
      else
        echo "Not a clone."
        echo $_FILENAME
        echo $dashboardID
      fi
    fi

      scrubResponse $responseDir/$_FILENAME

      getDashboard $dashboardID
      extractResponse $sourceDir/$_FILENAME $sourceDir
      scrubResponse $sourceDir/$_FILENAME
      if compareFile $responseDir/$_FILENAME $sourceDir/$_FILENAME;
      then
        pushDashboard $dashboardID
      fi

      # Clean up temp files?
      if ${CONF_dashboard_clean_tmp_files};
      then
        logThis "Cleaning up temp files" "INFO"
        logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
        rm -f ${responseDir}/*.clone
        rm -f ${responseDir}/*.clone.response
        logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
        rm -f ${sourceDir}/*.clone
        rm -f ${sourceDir}/*.clone.response
      else
        logThis "Leaving temp files" "INFO"
      fi
    ;;
  unit)
    # Becca's testing
    # Loop through dashboard files in dashboard dir
    for filename in $dashboardDir/*.json; do
        echo $dashboardDir
        logThis "Processing ${filename}" "INFO"
        _FILENAME=$(basename $filename)
        getDashboardID $filename
        if [[ "${_FILENAME}" == *"-Clone-"* ]];
        then
          logThis "Detected that ${_FILENAME} has documented working copy clone tags." "INFO"
          processCloneFileName $_FILENAME
          # Now that we have changed the filename, we need to process the dashboard name and dashboard ID.
          processCloneID $_FILENAME
        else
          if [[ "${dashboardID}" == *"-Clone-"* ]];
          then
            logThis "Detected that the dashboard ID (${dashboardID}) has documented working copy clone tags." "INFO"
            processCloneID $_FILENAME
          else
            echo "Not a clone."
            echo $_FILENAME
            echo $dashboardID
          fi
        fi

        scrubResponse $responseDir/$_FILENAME

        getDashboard $dashboardID
        extractResponse $sourceDir/$_FILENAME $sourceDir
        scrubResponse $sourceDir/$_FILENAME
        if compareFile $responseDir/$_FILENAME $sourceDir/$_FILENAME;
        then
          pushDashboard $dashboardID
        fi

        # Set the published tag as per the config
        setTag "$dashboardID" 'dashboard' "${CONF_dashboard_published_tag}"

        # Clean up temp files?
        if ${CONF_dashboard_clean_tmp_files};
        then
          logThis "Cleaning up temp files" "INFO"
          logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
          rm -f ${responseDir}/*.response.clone
          rm -f ${responseDir}/*.response
          logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
          rm -f ${sourceDir}/*.response.clone
          rm -f ${sourceDir}/*.response
        else
          logThis "Leaving temp files" "INFO"
        fi

        setACL "${dashboardID}" "dashboard"
    done

    ;;
  *)
    echo "You forgot to tell me what to do"
    help
    ;;

esac