#!/bin/bash

############################################################
#
#
#
############################################################

# Set GLOBALS
baseDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
## Load common functions
source ${baseDir}/lib/common.sh

## Read Config file
eval $(parse_yaml "${baseDir}/cfg/config.yaml" "CONF_")
dashboardDir="${baseDir}${CONF_dashboard_dir}"
sourceDir="${baseDir}${CONF_dashboard_sourceDir}"
responseDir="${dashboardDir}/responses"

## Logging configuration
dateTime="`date +%Y-%m-%d` `date +%T%z`" # Date format at beginning of log entries to match RFC
dateForFileName=`date +%Y%m%d`
scriptLogDir="${CONF_logging_dir}"
scriptLogPath="${scriptLogDir}/${CONF_app_name}-${dateForFileName}.log"
scriptLoggingLevel="${CONF_logging_level}"
# Setting api_token value
logThis "Setting API token from CONFIG." "DEBUG"
api_token=$CONF_aria_api_token
unset CONF_aria_api_token

# Get the options
while getopts "bdua :hi:s:t:" option; do
   case $option in
      b) # Becca's test code
         action=unit
         ;;
      d) # Execute Dashboard logic
         echo "I'm a dashboard"
         action='dashboard'
         logThis "The -${option} flag was set." "DEBUG"
         logThis "Executing Dashboard Management Logic." "INFO"
         ;;
      u) # Execute Account logic
         echo "I'm a group"
         action='account'
         logThis "The -${option} flag was set." "DEBUG"
         logThis "Executing Account Management Logic for roles, groups, and group membership." "INFO"
         ;;
      a) # Execute Alert logic
         echo "I'm alerting you to change alerts"
         action='alert'
         logThis "The -${option} flag was set." "DEBUG"
         logThis "Executing Alert Management Logic." "INFO"
         ;;
      i) # Dashboard ID
         # The ID of the published Dashboard
         dashboard_ID="${OPTARG}"
         logThis "The -${option} flag was set." "DEBUG"
         logThis "Received Dashboard ID for specific Dashboard Logic." "INFO"
         action='single_dashboard'
         ;;
      s) # Source Dashboard ID
         source_id="${OPTARG}"
         logThis "The -${option} flag was set." "DEBUG"
         logThis "Received Source Dashboard ID for specific Dashboard Logic." "INFO"
         action='single_dashboard'
         ;;
      t) # API Token
         logThis "Overriding the config file API token value" "INFO"
         api_token="${OPTARG}"
         ;;
      *) # display help info
         help
         ;;
   esac
done

case $action in

  account)
    echo "Let's modify some groups"
    ;;

  alert)
    echo "Let's publish some alerts"
    ;;

  dashboard)
    # Loop through dashboard files in dashboar dir
    for filename in $dashboardDir/*.json; do
      echo $dashboardDir
      logThis "Processing ${filename}" "INFO"
      _FILENAME=$(basename $filename)
      get_dashboardID $filename
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

      scrub_response $responseDir/$_FILENAME

      get_dashboard $dashboardID
      extract_response $sourceDir/$_FILENAME $sourceDir
      scrub_response $sourceDir/$_FILENAME
      if compare_file $_FILENAME;
      then
        push_dashboard $dashboardID
      fi

      # Clean up temp files?
      if ${CONF_dashboard_clean_tmp_files};
      then
        logThis "Cleaning up temp files" "INFO"
        logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extenstions." "DEBUG"
        rm -f ${responseDir}/*.clone
        rm -f ${responseDir}/*.clone.response
        logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extenstions." "DEBUG"
        rm -f ${sourceDir}/*.clone
        rm -f ${sourceDir}/*.clone.response
      else
        logThis "Leaving temp files" "INFO"
      fi
    done
    ;;

  single_dashboard)
    _FILENAME="${dashboardID}.json"
    get_dashboardID $_FILENAME 
    # Let's make sure the extracted dashboard ID and the file dashboard ID match.
    if [ "${dashboardID}" = "${dashboard_ID}" ];
    then
      # unsetting option value since the extracted value matches to free memory.
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

      scrub_response $responseDir/$_FILENAME

      get_dashboard $dashboardID
      extract_response $sourceDir/$_FILENAME $sourceDir
      scrub_response $sourceDir/$_FILENAME
      if compare_file $_FILENAME;
      then
        push_dashboard $dashboardID
      fi

      # Clean up temp files?
      if ${CONF_dashboard_clean_tmp_files};
      then
        logThis "Cleaning up temp files" "INFO"
        logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extenstions." "DEBUG"
        rm -f ${responseDir}/*.clone
        rm -f ${responseDir}/*.clone.response
        logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extenstions." "DEBUG"
        rm -f ${sourceDir}/*.clone
        rm -f ${sourceDir}/*.clone.response
      else
        logThis "Leaving temp files" "INFO"
      fi
    ;;
  unit)
    # Becca's testing
    # Loop through dashboard files in dashboar dir
    for filename in $dashboardDir/*.json; do
        echo $dashboardDir
        logThis "Processing ${filename}" "INFO"
        _FILENAME=$(basename $filename)
        get_dashboardID $filename
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

        scrub_response $responseDir/$_FILENAME

        get_dashboard $dashboardID
        extract_response $sourceDir/$_FILENAME $sourceDir
        scrub_response $sourceDir/$_FILENAME
        if compare_file $_FILENAME;
        then
          push_dashboard $dashboardID
        fi

        # Clean up temp files?
        if ${CONF_dashboard_clean_tmp_files};
        then
          logThis "Cleaning up temp files" "INFO"
          logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extenstions." "DEBUG"
          rm -f ${responseDir}/*.clone
          rm -f ${responseDir}/*.clone.response
          logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extenstions." "DEBUG"
          rm -f ${sourceDir}/*.clone
          rm -f ${sourceDir}/*.clone.response
        else
          logThis "Leaving temp files" "INFO"
        fi

    done
    ;;
  *)
    echo "You forgot to tell me what to do"
    help
    ;;

esac