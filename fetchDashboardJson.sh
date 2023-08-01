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
source ${baseDir}/lib/common.sh
source ${baseDir}/lib/libDashboard.sh

## Read Config file
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

## Logging configuration
dateTime="`date +%Y-%m-%d` `date +%T%z`" # Date format at beginning of log entries to match RFC
dateForFileName=`date +%Y%m%d`
scriptLogDir="${baseDir}/log/"
scriptLogPath="${scriptLogDir}/${CONF_appName}-${dateForFileName}.log"
scriptLoggingLevel="${CONF_logging_level}"

echo "This utility is designed to aid in the easy retrieval of the json. \
This does require you to have API permissions in VMware Aria Operations for \
Applications. Please see [Dashboard Development] (dashboards/DASHBOARDDEVELOPMENT.md)\
for instructions on how to get an API token and the designed workflow for dashboard \
development.

Working copy logs are stored in ${scriptLogDir} which is in .gitignore.

You will now be prompted for your API Token and the Dashboard ID to retrieve.
"

if [[ -z "${ENV_WAPI_USER_TOKEN}" ]];
then
    # apiToken="USER INPUT"
    read -p "Enter your API token: " apiToken
else
    apiToken="${ENV_WAPI_USER_TOKEN}"
fi

while true;
do
    # dashboardID="USER INPUT"
    read -p "Enter DashboardID: " dashboardID

    getWorkingCopyDashboard $dashboardID

    echo "Completed operation.  Please see log file ${scriptLogPath} for more information."

    # yn="USER INPUT"

    read -p "Retrieve another dashboard with same API Token? (yes/no) " yn
    case $yn in 
        y | Y | yes ) 
            logThis "Preparing to process another dashboard using same configuration." "INFO"
            ;;
        n | N | no )
            logThis "Finished processing.  Exiting." "INFO"
            echo "Goodbye"
            exit
            ;;
        * ) 
            echo "invalid response";
            exit 1
            ;;
    esac
done
