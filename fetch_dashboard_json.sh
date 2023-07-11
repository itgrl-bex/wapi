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
scriptLogDir="${baseDir}/log/"
scriptLogPath="${scriptLogDir}/${CONF_app_name}-${dateForFileName}.log"
scriptLoggingLevel="${CONF_logging_level}"

print -f "This utility is designed to aid in the easy retrieval of the json. \
This does require you to have API permissions in VMware Aria Operations for \
Applications. Please see [Dashboard Development] (dashboards/DashboardDevelopment.md)\
for instructions on how to get an API token and the designed workflow for dashboard \
development.

Working copy logs are stored in ${scriptLogDir} which is in `.gitignore`.

You will now be prompted for your API Token and the Dashboard ID to retrieve.
"

if [[ -z "${ENV_WAPI_USER_TOKEN}" ]];
then
    # api_token="USER INPUT"
    read -p "Enter your API token: " api_token
else
    api_token="${ENV_WAPI_USER_TOKEN}"
fi

while true;
do
    # dashboardID="USER INPUT"
    read -p "Enter DashboardID: " dashboardID

    get_workingcopy_dashboard $dashboardID

    print -f "Completed operation.  Please see log file ${scriptLogPath} for more information."

    # yn="USER INPUT"

    read -p "Retrieve another dashboard with same API Token? (yes/no) " yn
    case $yn in 
        y | Y | yes ) 
            logThis "Pre[aring to process another dashboard using same configuration." "INFO"
            ;;
        n | N | no )
            logThis "Finished processing.  Exiting." "INFO"
            print -f "Goodbye"
            exit
            ;;
        * ) 
            echo "invalid response";
            exit 1
            ;;
    esac
done
