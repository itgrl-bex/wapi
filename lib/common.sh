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

function validateYAML {
  if [ -z "${1}" ];
  then
    logThis "Required parameter #1 'filepath' missing." "SEVERE"
  fi
  local _version=$(yq --version | awk '{print $4}')
  if [[ "${_version}" == "v4"* ]];
  then
    echo 'Found version 4'
    yq --exit-status 'tag == "!!map" or tag== "!!seq"' $1 > /dev/null
  else
    echo 'Some other version'
    yq validate "$1" > /dev/null
  fi
}

function validateJSON {
  if [ -z "${1}" ];
  then
    logThis "Required parameter #1 'filepath' missing." "SEVERE"
  fi  
  local _version=$(jq --version)
  jq empty "${1}"
}

function compareFile {
  logThis "Comparing scrubbed files" "INFO"
  file1="$1"
  # source
  file2="$2"
  if [ -z "${file1}" ];
  then
    logThis "Required parameter #1 'filepath' of first file is missing." "SEVERE"
  fi
  if [ -z "${file2}" ];
  then
    logThis "Required parameter #2 'filepath' of second file is missing." "SEVERE"
  fi
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

function getACL {
 local id="${1}"
 local apiType="${2}"
 local tmpFile="${3}"
 # Add variable validation to ensure variables are set.
  if [ -z "${id}" ];
  then
    logThis "Required parameter #1 'id' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'\
     #3 the temp file where to store the working data."
  fi
  if [ -z "${apiType}" ];
  then
    logThis "Required parameter #2 'apiType' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'\
     #3 the temp file where to store the working data."
  fi
  if [ -z "${tmpFile}" ];
  then
    logThis "Required parameter #3 'tmpFile' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'\
     #3 the temp file where to store the working data."
  fi

  logThis "Retrieving ACL for ${apiType} ${id}." "INFO"

  if _result=$(curl -X 'GET' "${CONF_aria_operations_url}/api/v2/${apiType}/acl?id=${id}" -H 'accept: application/json' -H "Authorization: Bearer  ${api_token}");
  then
    logThis "Found published ${apiType} ${id}." "INFO"
    echo $_result  > "${tmpFile}.result"
    jq -r '.response' "${tmpFile}.result" | jq -r '.[]' | jq 'del(.entityId)' > "${tmpFile}"
    rm "${tmpFile}.result"
  else
    logThis "Could not find published ${apiType} ${id}.  \
    Please ensure ${apiType} ${id} exists and try again." "ERROR"
    return 1
  fi

  if validateJSON "${tmpFile}";
  then
    logThis "Prepared JSON response for ${apiType} ${id} is valid." "INFO"
    return 0
  else
    logThis "Prepared JSON response for ${apiType} ${id} has errors." "ERROR"
    rm "${tmpFile}"
    return 1
  fi
}

function setACL {
 local id="${1}"
 local apiType="${2}"
 # Add variable validation to ensure variables are set.
  if [ -z "${id}" ];
  then
    logThis "Required parameter #1 'id' missing." "SEVERE"
    logThis "The function SetACL requires 2 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'" "Error"
  fi
  if [ -z "${apiType}" ];
  then
    logThis "Required parameter #2 'apiType' missing." "SEVERE"
    logThis "The function SetACL requires 2 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'" "Error"
  fi

  logThis "Checking ACL for ${apiType} ${id}." "INFO"
  local tracker="acl-${dateTime}"
  local remoteACL="${CONF_tmpDir}/${apiType}-${tracker}-${id}.json"
  if getACL "${id}" "${apiType}" "${remoteACL}" ;
  then
    local _remoteModifyAcl=($(jq -r '.modifyAcl' "${remoteACL}" | jq -r '.[].id'))
    local _modifyAcl=($(yq ".CONF.${apiType}.published.acls.modifyAcl" -o=json $config | jq -r '.[]'))
    changed=false
    for r in $_remoteModifyAcl;
    do
      if [[ ! " ${_modifyAcl[*]} " =~ " ${r} " ]];
      then
        logThis "Found that the published acl has value ${r} which is not present in the required modifyAcl." "INFO"
        changed=true
      fi
    done
    for l in $_modifyAcl;
    do
      if [[ ! " ${_remoteModifyAcl[*]} " =~ " ${r} " ]];
      then
        logThis "Found that the published modifyACL does not have ${r} configured as is required." "INFO"
        changed=true
      fi
    done

    local _remoteViewAcl=($(jq -r '.viewAcl' "${remoteACL}" | jq -r '.[].id'))
    local _viewAcl=($(yq ".CONF.${apiType}.published.acls.viewAcl" -o=json $config | jq -r '.[]'))
    for r in $_remoteViewAcl;
    do
      if [[ ! " ${_viewAcl[*]} " =~ " ${r} " ]];
      then
        logThis "Found that the published acl has value ${r} which is not present in the required viewAcl." "INFO"
        changed=true
      fi
    done
    for l in $_viewAcl;
    do
      if [[ ! " ${_remoteViewAcl[*]} " =~ " ${r} " ]];
      then
        logThis "Found that the published viewACL does not have ${r} configured as is required." "INFO"
        changed=true
      fi
    done
  else
    logThis "Failed to get valid JSON from published ${apiType} ${id}." "SEVERE"
  fi

  if $changed;
  then
    logThis "The ACLs are different, setting ACL to configured ACL." "INFO"
    local _data="[ $(yq -o json '.CONF.dashboard.published.acls' cfg/config.yaml | \
    jq ". += { \"entityId\": \"${id}\" }" ) ]"

    logThis "Executing command:  [curl -X 'PUT' -d \"${_data}\" \"${CONF_aria_operations_url}/api/v2/${apiType}/acl/set\" -H 'Accept: application/json' -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${api_token}]\"" "DEBUG"
    curl -X 'PUT' -d "${_data}" ${CONF_aria_operations_url}/api/v2/${apiType}/acl/set -H 'Accept: application/json' -H 'Content-Type: application/json' \
     -H "Authorization: Bearer  ${api_token}" && logThis "Successfully published ${apiType} ${id}." "INFO" || logThis "Could not publish ${apiType} ${id}." "CRITICAL"
    rm -f "${remoteACL}"
  fi

}

# Migrating to common function from libdashboard.sh
function setTag {
 local id="${1}"
 local apiType="${2}"
 local tag="${3}"
 # Add variable validation to ensure variables are set.
  if [ -z "${id}" ];
  then
    logThis "Required parameter #1 'id' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'\
     #3 the tag that should be set such as 'published.dashboard'" "Error"
  fi
  if [ -z "${apiType}" ];
  then
    logThis "Required parameter #2 'apiType' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'\
     #3 the tag that should be set such as 'published.dashboard'" "Error"  
  fi
  if [ -z "${tag}" ];
  then
    logThis "Required parameter #3 'tag' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard'\
     #3 the tag that should be set such as 'published.dashboard'" "Error"
  fi
  local result=$(curl -X 'GET' \
  "${CONF_aria_operations_url}/api/v2/${apiType}/${id}/tag" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer  ${api_token}" | jq -r '.response.items' | grep "${tag}")
  if [[ "${result}" == "  \"${tag}\"" ]];
  then
    logThis "The ${tag} tag is already set in the ${apiType} ${id}." "INFO"
    logThis "The ${apiType} ${id} has tags set ${result}." "DEBUG"
  else
    curl -X 'PUT' "${CONF_aria_operations_url}/api/v2/${apiType}/${id}/tag/${tag}" \
    -H 'Content-Type: application/json' -H "Authorization: Bearer  ${api_token}" && \
    logThis "Successfully set tag ${tag} on ${apiType} ${id}." "INFO" || \
    logThis "Could not set tag ${tag} on ${apiType} ${id}." "ERROR"
  fi
}

function searchTag {
  local apiType=$1
  local tag=$2
  if [ -z "${apiType}" ];
  then
    logThis "Required parameter #1 'apiType' missing." "SEVERE"
    logThis "The function searchTag requires 2 arguments in positional order. \
     #1 the apiType to query such as 'dashboard'\
     #2 the tag that should be searched such as 'published.dashboard'" "Error"
  fi
  if [ -z "${tag}" ];
  then
    logThis "Required parameter #2 'tag' missing." "SEVERE"
    logThis "The function searchTag requires 2 arguments in positional order. \
     #1 the apiType to query such as 'dashboard'\
     #2 the tag that should be searched such as 'published.dashboard'" "Error"
  fi  
  curl -X 'POST' \
    "${CONF_aria_operations_url}/api/v2/search/${apiType}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${api_token}" \
    -d "{
    \"limit\": 1000,
    \"offset\": 0,
    \"query\": [
      {
        \"key\": \"tags.customerTags\",
        \"value\": \"string\",
        \"values\": [
          \"${tag}\"
        ],
        \"matchingMethod\": \"CONTAINS\",
        \"negated\": false,
        \"start\": 0,
        \"end\": 0
      }
    ],
    \"sort\": {
      \"ascending\": true,
      \"field\": \"id\"
    }
  }" | jq -r '.response.items' | jq -r '.[].id'
}

function createDir {
  local dir="${1}"
  if [ -z "${dir}" ];
  then
    logThis "Required parameter 'directoryPath' missing." "SEVERE"
  fi
  logThis "Checking ${dir}" "INFO"
  if [ -d $dir ];
  then
    logThis "Directory ${dir} exists" "DEBUG"
  else
    logThis "Executing the command[mkdir ${dir}]" "DEBUG"
    mkdir -p $dir && logThis "Successfully created ${dir}." "INFO" || logThis "Error creating directory ${dir}." "CRITICAL"
  fi
}