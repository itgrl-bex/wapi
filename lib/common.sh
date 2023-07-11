#################################################################################
# SCRIPT LOGGING CONFIGURATION
#
# The following is used by the script to output log data. Depending upon the log
# level indicated, more or less data may be output, with a "lower" level
# providing more detail, and the "higher" level providing less verbose output.
#################################################################################
#
# Logging Level configuration works as follows:
# DEBUG - Provides all logging output
# INFO  - Provides all but debug messages
# WARN  - Provides all but debug and info
# ERROR - Provides all but debug, info and warn
#
# SEVERE and CRITICAL are also supported levels as extremes of ERROR
# SEVERE and CRITICAL will exit the program and log the exit
#
#################################################################################
#          ##      END OF GLOBAL VARIABLE CONFIGURATION      ##
#################################################################################
# LOGGING
#
# Calls to the logThis() function will determine if an appropriate log file
# exists. If it does, then it will use it, if not, a call to openLog() is made,
# if the log file is created successfully, then it is used.
#
# All log output is comprised of
# [+] An RFC 3339 standard date/time stamp
# [+] The declared level of the log output
# [+] The runtime process ID (PID) of the script
# [+] The log message
################################################################################
function openLog {
    echo -e "${dateTime} : PID $$ : INFO : New log file (${scriptLogPath}) created." >> "${scriptLogPath}"

    if ! [[ "$?" -eq 0 ]]
    then
        echo "${dateTime} - ERROR : UNABLE TO OPEN LOG FILE - EXITING SCRIPT."
        exit 1
    fi
}

function logThis() {
    # Simple hack for developing on my mac
    kernel=$(uname)
    if [ "${kernel}" = "Darwin" ];
    then
      dateTime=$(gdate --rfc-3339=seconds)
    else
      dateTime=$(date --rfc-3339=seconds)
    fi

    if [[ -z "${1}" || -z "${2}" ]]
    then
        echo "${dateTime} - ERROR : LOGGING REQUIRES A DESTINATION FILE, A MESSAGE AND A PRIORITY, IN THAT ORDER."
        echo "${dateTime} - ERROR : INPUTS WERE: ${1} and ${2}."
        exit 1
    fi

    logMessage="${1}"
    logMessagePriority="${2}"

    logPriorities=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 [SEVERE]=4 [CRITICAL]=5)
    [[ ${logPriorities[$logMessagePriority]} ]] || return 1
    (( ${logPriorities[$logMessagePriority]} < ${logPriorities[$scriptLoggingLevel]} )) && return 2

    # No log dir, create it.
    # No log file, create it.
    if ! [[ -d ${scriptLogDir} ]]
    then
        echo -e "INFO : No log directory located, creating new log directory (${scriptLogDir})."
        echo "${dateTime} : PID $$ :INFO : No log directory located, creating new log directory (${scriptLogDir})." >> "${scriptLogPath}"
        mkdir -p $scriptLogDir
    fi

    # No log file, create it.
    if ! [[ -f ${scriptLogPath} ]]
    then
        echo -e "INFO : No log file located, creating new log file (${scriptLogPath})."
        echo "${dateTime} : PID $$ :INFO : No log file located, creating new log file (${scriptLogPath})." >> "${scriptLogPath}"
        openLog
    fi

    # Write log details to file
    echo -e "${logMessagePriority} : ${logMessage}"
    echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${logMessage}" >> "${scriptLogPath}"

    # Exiting program if SEVERE or CRITICAL
    case $logMessagePriority in
      CRITICAL)
        _msg="Received ERROR with severity of ${logMessagePriority}. Exiting program to prevent additional problems with distributed systems."
        echo -e "${logMessagePriority} : ${_msg}"
        echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${_msg}" >> "${scriptLogPath}"
        exit 1      
      ;;
      SEVERE)
        _msg="Received ERROR with severity of ${logMessagePriority}. Exiting program to prevent additional problems with distributed systems."
        echo -e "${logMessagePriority} : ${_msg}"
        echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${_msg}" >> "${scriptLogPath}"
        exit 1
      ;;
    esac
}

function help {
  echo "Usage: $0 [ -i dashboardID ] [ -s SOURCE_dashboardID ] [ -t API_TOKEN ]" 1>&2 
  echo "
    A single option of -d is required for task to work and app will cycle through dashboards \
    and compare with existing version. If changes are detected, then the app will push copy \
    from the dashboards directory.
    
    These options do not accept arguments
    At least one of these flags is required
    -a Process Alert modifications
    -d Process Dashboard modifications
    -u Process Account modifications
    -h Print this message

    These optional flags require arguments
    -i <value> Dashboard ID of the target Dashboard
    -s <value> Dashboard ID of the source Dashboard
    -t <value> API Token to override config API token

  "
}

function parse_yaml {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
       -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
       -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
     indent = length($1)/2;
     vname[indent] = $2;
     for (i in vname) {if (i > indent) {delete vname[i]}}
     if (length($3) > 0) {
        vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
        printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
     }
  }'
}

function get_dashboardID {
  logThis "Retrieving dashboardID" "INFO"
  local _OUTPUT=$(grep '  \"response\"\:' $1)
  if [ -n "$_OUTPUT" ];
  then
    dashboardID=$(jq -r '.response.id' $1)
    echo $dashboardID
    extract_response $1 $responseDir
  else
    dashboardID=$(jq -r '.id' $1)
    echo $dashboardID
    logThis "Copying dashboard to response file since the response body has been extracted already." "INFO"
    cp $1 $responseDir/
  fi
}

function create_responseDir {
  logThis "Checking ${responseDir}" "INFO"
  if [ -d $responseDir ];
  then
    logThis "Directory ${responseDir} exists" "DEBUG"
  else
    logThis "Executing the command[mkdir ${responseDir}]" "DEBUG"
    mkdir $responseDir && logThis "Successfully created ${responseDir}." "INFO" || logThis "Error creating directory ${responseDir}." "CRITICAL"
  fi
}

function extract_response {
  create_responseDir
  logThis "Extracting JSON response body from file." "INFO"
  local _FILENAME=$(basename $1)
  logThis "Executing the command [jq -r '.response' ${1} > ${2}/${_FILENAME}.response]" "DEBUG"
  jq -r '.response' $1 > $2/$_FILENAME.response && logThis "Successfully extracted JSON response body." "INFO" || logThis "Could not extract JSON response body from file ${1}." "CRITICAL"
  logThis "Extracted JSON response body from file ${1} and storing it in the directory ${2}." "DEBUG"
}

function scrub_response {
  logThis "Scrubbing response to remove metadata." "INFO"
  logThis "Executing command: [cat ${1}.response | jq \"del(.disableRefreshInLiveMode) | del(.hideChartWarning) | \
  del(.creatorId) | del(.updaterId) | del(.createdEpochMillis) | del(.updatedEpochMillis) | \
  del(.deleted) | del(.numCharts) | del(.numFavorites) | del(.favorite)\" > ${1}]" "DEBUG"
  cat $1.response | \
  jq "del(.disableRefreshInLiveMode) | \
  del(.hideChartWarning) | \
  del(.creatorId) | \
  del(.updaterId) | \
  del(.createdEpochMillis) | \
  del(.updatedEpochMillis) | \
  del(.deleted) | \
  del(.numCharts) | \
  del(.numFavorites) | \
  del(.favorite)" > $1  && logThis "Successfully scrubbed JSON response body." "INFO" || logThis "Could not scrub JSON response body from file ${1}.response." "CRITICAL"
}

function get_dashboard {
  logThis "Checking dashboard retrieval output directory ${sourceDir}." "INFO"
  if [ -d $sourceDir ];
  then
    logThis "Directory ${sourceDir} exists." "DEBUG"
  else
    mkdir $sourceDir && logThis "Successfully created ${sourceDir}." "INFO" || logThis "Error creating directory ${sourceDir}." "CRITICAL"
  fi
  logThis "Retrieving Dashboard ${dashboardID}." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o $sourceDir/$dashboardID.json \"${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
  curl -X 'GET' -o $sourceDir/$dashboardID.json \
    "${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${api_token}" && logThis "Successfully retrieved dashboard ${dashboardID}." "INFO" || logThis "Could not retrieve dashboard ${dashboardID}." "CRITICAL"
}

function get_workingcopy_dashboard {
  logThis "Checking dashboard retrieval output directory ${dashboardDir}." "INFO"
  if [ -d $dashboardDir ];
  then
    logThis "Directory ${dashboardDir} exists." "DEBUG"
  else
    mkdir $dashboardDir && logThis "Successfully created ${dashboardDir}." "INFO" || logThis "Error creating directory ${dashboardDir}." "CRITICAL"
  fi
  if [ -f $dashboardDir/$dashboardID.json ];
  then
    read -p "Replace file ${dashboardDir}/${dashboardID}.json? (yes/no) " yn
    case $yn in 
	    y | Y | yes ) 
          logThis "Replacing the Dashboard file ${dashboardDir}/${dashboardID}.json." "INFO"
          ;;
	    n | N | no )
          logThis "The Dashboard file ${dashboardDir}/${dashboardID}.json exists and not replacing." "INFO"
		      exit
          ;;
	    * ) echo invalid response;
		      exit 1
          ;;
    esac
  fi
  logThis "Retrieving Dashboard ${dashboardID}." "INFO"
  logThis "Executing command:  [curl -X 'GET' -o $dashboardDir/$dashboardID.json \"${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}\" -H 'accept: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
  curl -X 'GET' -o $dashboardDir/$dashboardID.json \
    "${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer  ${api_token}" && logThis "Successfully retrieved dashboard ${dashboardID}." "INFO" || logThis "Could not retrieve dashboard ${dashboardID}." "CRITICAL"
}


function compare_file {
  logThis "Comparing scrubbed Dashboard files" "INFO"
  file1="${responseDir}/${1}"
  file2="${sourceDir}/${1}"
  if cmp -s "$file1" "$file2"; then
    logThis "The file ${file1} is the same as ${file2}." "INFO"
    printf 'The file "%s" is the same as "%s"\n'  "$file1" "$file2"
    # Return 1 or false to indicate the file has not changed to the calling if condition.
    return 1
  else
    logThis "The file ${file1} is not the same as ${file2}." "INFO"
    printf 'The file "%s" is different from "%s"\n' "$file1" "$file2"
    # Return 0 or true to indicate the file has changed to the calling if condition.
    return 0
  fi
}

function push_dashboard {
  logThis "Publishing Dashboard ${dashboardID}" "INFO"
  logThis "Executing command:  [curl -X 'PUT' --data \"@${responseDir}/${dashboardID}.json\" \"${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}\" -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
  curl -X 'PUT' --data "@${responseDir}/${dashboardID}.json" \
    "${CONF_aria_operations_url}/api/v2/dashboard/${dashboardID}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${api_token}" && logThis "Successfully retrieved dashboard ${dashboardID}." "INFO" || logThis "Could not retrieve dashboard ${dashboardID}." "CRITICAL"
}

function processCloneFileName {
  logThis "Stripping working copy Clone tags from filename ${1} before publishing." "INFO"
  echo 'file process'
  newFILENAME=$(echo $_FILENAME | awk -F '-Clone-' '{print $1}').json
  logThis "Rename the file ${responseDir}/${_FILENAME}.response to ${responseDir}/${newFILENAME}.response" "INFO"
  echo $_FILENAME
  echo $newFILENAME
  mv $responseDir/$_FILENAME.response $responseDir/$newFILENAME.response
  _FILENAME=$newFILENAME
  unset newFILENAME

}

function processCloneID {
  logThis "Stripping working copy Clone tags from file ${1} before publishing." "INFO"
  local _dashboardID=$(echo $dashboardID | awk -F '-Clone-' '{print $1}')
  logThis "Changing (dashboardID) in file from ${dashboardID} to ${_dashboardID} in file $_FILENAME." "DEBUG"
  sed -i '.clone' "s/${dashboardID}/${_dashboardID}/g" $responseDir/$_FILENAME.response
  logThis "Changing dashboard name to remove the (Clone) designation." "DEBUG"
  sed -i '' -E 's/ \(Clone\)//' $responseDir/$_FILENAME.response
  logThis "Changing (dashboardID) variable from ${dashboardID} to ${_dashboardID}." "DEBUG"
  dashboardID=$_dashboardID
}

