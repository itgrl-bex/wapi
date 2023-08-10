#!/bin/bash

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
    doNotEcho="${3}"

    logPriorities=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 [SEVERE]=4 [CRITICAL]=5)
    [[ ${logPriorities[$logMessagePriority]} ]] || return 1
    (( ${logPriorities[$logMessagePriority]} < ${logPriorities[$scriptLoggingLevel]} )) && return 2


    if ${doNotEcho};
    then
      # If doNotEcho is true, then do not echo to stdout
      # No log dir, create it.
      # No log file, create it.
      if ! [[ -d ${scriptLogDir} ]]
      then
          # echo -e "INFO : No log directory located, creating new log directory (${scriptLogDir})."
          echo "${dateTime} : PID $$ :INFO : No log directory located, creating new log directory (${scriptLogDir})." >> "${scriptLogPath}"
          mkdir -p $scriptLogDir
      fi

      # No log file, create it.
      if ! [[ -f ${scriptLogPath} ]]
      then
          # echo -e "INFO : No log file located, creating new log file (${scriptLogPath})."
          echo "${dateTime} : PID $$ :INFO : No log file located, creating new log file (${scriptLogPath})." >> "${scriptLogPath}"
          openLog
      fi

      # Write log details to file
      # echo -e "${logMessagePriority} : ${logMessage}"
      echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${logMessage}" >> "${scriptLogPath}"

      # Exiting program if SEVERE or CRITICAL
      case $logMessagePriority in
        CRITICAL)
          _msg="Received ERROR with severity of ${logMessagePriority}. Exiting program to prevent additional problems with distributed systems."
          # echo -e "${logMessagePriority} : ${_msg}"
          echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${_msg}" >> "${scriptLogPath}"
          exit 1      
        ;;
        SEVERE)
          _msg="Received ERROR with severity of ${logMessagePriority}. Exiting program to prevent additional problems with distributed systems."
          # echo -e "${logMessagePriority} : ${_msg}"
          echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${_msg}" >> "${scriptLogPath}"
          exit 1
        ;;
      esac
    else
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
    fi
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
##   ${1} - 
##          
##          
##   ${2} - 
## 
## 
## Outputs:
##
##############################################################################

function help {
  echo "Usage: $0 [ -i dashboardID ] [ -s SOURCE_dashboardID ] [ -t apiToken ]" 1>&2 
  echo "
    A single option of -d is required for task to work and app will cycle through dashboards \
    and compare with existing version. If changes are detected, then the app will push copy \
    from the dashboards directory.
    
    These options do not accept arguments
    At least one of these flags is required
    -a Process Alert modifications
    -e Process Staged Alerts modifications
    -d Process Dashboard modifications
    -g Process Staged Dashboards modifications
    -u Process Account modifications
    -h Print this message

    These optional flags require arguments
    -i <value> Dashboard ID of the target Dashboard
    -s <value> Dashboard ID of the source Dashboard
    -t <value> API Token to override config API token

  "
}

##############################################################################
## Function Name: getTmpDir
## Purpose: Use configured CONF_tmpDir or create a temp dir using mktemp -d
##
## Outputs: The temp directory to use
##
## Example: tmpDir=$(getTmpDir)
##
##############################################################################

function getTmpDir {
  if [ -n "${CONF_tmpDir}" ];
  then
    echo "${CONF_tmpDir}"
  else
    mktemp -d -t wapi || exit 1
  fi 
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
##   ${1} - 
##          
##          
##   ${2} - 
## 
## 
## Outputs:
##
##############################################################################

function validateYAML {
  if [ -z "${1}" ];
  then
    logThis "Required parameter #1 'filepath' missing." "SEVERE"
  fi
  local _version
  _version=$(yq --version | awk '{print $4}')
  if [[ "${_version}" == "v4"* ]];
  then
    echo 'Found version 4'
    yq --exit-status 'tag == "!!map" or tag== "!!seq"' "${1}" > /dev/null
  else
    echo 'Some other version'
    yq validate "${1}" > /dev/null
  fi
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
##   ${1} - 
##          
##          
##   ${2} - 
## 
## 
## Outputs:
##
##############################################################################

function validateJSON {
  if [ -z "${1}" ];
  then
    logThis "Required parameter #1 'filepath' missing." "SEVERE"
  fi  
  local _version
  _version=$(jq --version)
  jq empty "${1}"
}

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
##   ${1} - 
##          
##          
##   ${2} - 
## 
## 
## Outputs:
##
##############################################################################

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

##############################################################################
## Function Name: 
## Purpose:
##
## Inputs:
##   ${1} - 
##          
##          
##   ${2} - 
## 
## 
## Outputs:
##
##############################################################################

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

  if _result=$(curl -X 'GET' "${CONF_aria_operationsUrl}/api/v2/${apiType}/acl?id=${id}" -H 'accept: application/json' -H "Authorization: Bearer  ${apiToken}");
  then
    logThis "Found published ${apiType} ${id}." "INFO"
    echo "${_result}"  > "${tmpFile}.result"
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

##############################################################################
## Function Name: setACL
## Purpose: To set the ACL on an object.
##
## Inputs:
##   ${1} - The first positional parameter is the json 'id' of the object to
##          set the ACL on.
##   ${2} - The second positional parameter is the apiType to execute. Such as
##          'dashboard', 'alert', or another API type.
## 
## Outputs:
##
##############################################################################

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
  local remoteACL="${tmpDir}/${apiType}-${tracker}-${id}.json"
  if getACL "${id}" "${apiType}" "${remoteACL}" ;
  then
    local _remoteModifyAcl=( $(jq -r '.modifyAcl' "${remoteACL}" | jq -r '.[].id') )
    local _modifyAcl=( $(yq ".CONF.${apiType}.published.acls.modifyAcl" -o=json $config | jq -r '.[]') )
    changed=false
    for r in "${_remoteModifyAcl[@]}";
    do
      if [[ ! " ${_modifyAcl[*]} " =~ " ${r} " ]];
      then
        logThis "Found that the published acl has value ${r} which is not present in the required modifyAcl." "INFO"
        changed=true
      fi
    done
    for r in "${_modifyAcl[@]}";
    do
      if [[ ! " ${_remoteModifyAcl[*]} " =~ ${r} ]];
      then
        logThis "Found that the published modifyACL does not have ${r} configured as is required." "INFO"
        changed=true
      fi
    done

    local _remoteViewAcl=( $(jq -r '.viewAcl' "${remoteACL}" | jq -r '.[].id') )
    local _viewAcl=( $(yq ".CONF.${apiType}.published.acls.viewAcl" -o=json $config | jq -r '.[]') )
    for r in "${_remoteViewAcl[@]}";
    do
      if [[ ! " ${_viewAcl[*]} " =~ ${r} ]];
      then
        logThis "Found that the published acl has value ${r} which is not present in the required viewAcl." "INFO"
        changed=true
      fi
    done
    for r in "${_viewAcl[@]}";
    do
      if [[ ! " ${_remoteViewAcl[*]} " =~ ${r} ]];
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
    local _data
    _data="[ $(yq -o json '.CONF.dashboard.published.acls' cfg/config.yaml | \
    jq ". += { \"entityId\": \"${id}\" }" ) ]"

    logThis "Executing command:  [curl -X 'PUT' -d \"${_data}\" \"${CONF_aria_operationsUrl}/api/v2/${apiType}/acl/set\" -H 'Accept: application/json' -H 'Content-Type: application/json' -H \"Authorization: Bearer  ${apiToken}]\"" "DEBUG"
    curl -X 'PUT' -d "${_data}" ${CONF_aria_operationsUrl}/api/v2/${apiType}/acl/set -H 'Accept: application/json' -H 'Content-Type: application/json' \
     -H "Authorization: Bearer  ${apiToken}" && logThis "Successfully published ${apiType} ${id}." "INFO" || logThis "Could not publish ${apiType} ${id}." "CRITICAL"
    rm -f "${remoteACL}"
  fi

}

##############################################################################
## Function Name: getTags
## Purpose: The purpose is to return the list of tags on the apiType object
##
## Inputs:
##   ${1} - The first positional parameter is the json 'id' of the object to
##          set the tag on.
##   ${2} - The second positional parameter is the apiType to execute. Such as
##          'dashboard', 'alert', or another API type.
## 
## Outputs:
##          Returns the tags found.
##          The following return codes values are returned:
##          0 - Successfully retrieved the tags
##          1 - Failed to retrieve the tags
##
##############################################################################

# Migrating to common function from libDashboard.sh
function getTags {
 local id="${1}"
 local apiType="${2}"
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
  local result
  result=( $(curl -X 'GET' "${CONF_aria_operationsUrl}/api/v2/${apiType}/${id}/tag" -H 'accept: application/json' \
    -H "Authorization: Bearer  ${apiToken}" | jq -r '.response.items' | sed 's/\[//' | sed 's/\]//' | sed 's/,/ /g') )

  echo "${result}"

}


##############################################################################
## Function Name: setTag
## Purpose: To set a tag on an object
##
## Inputs:
##   ${1} - The first positional parameter is the json 'id' of the object to
##          set the tag on.
##   ${2} - The second positional parameter is the apiType to execute. Such as
##          'dashboard', 'alert', or another API type.
##   ${3} - The third positional parameter is the tag that should be added.
## 
## Outputs:
##          The following return values are returned:
##          0 - Successfully added the tag
##          1 - Failed to add the tag
##          3 - The tag was already set
##
##############################################################################

# Migrating to common function from libDashboard.sh
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
  local result
  result=$(curl -X 'GET' \
  "${CONF_aria_operationsUrl}/api/v2/${apiType}/${id}/tag" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer  ${apiToken}" | jq -r '.response.items' | grep "${tag}")
  if [[ "${result}" == "  \"${tag}\"" ]];
  then
    logThis "The ${tag} tag is already set in the ${apiType} ${id}." "INFO"
    logThis "The ${apiType} ${id} has tags set ${result}." "DEBUG"
    return 3
  else
    if (curl -X 'PUT' "${CONF_aria_operationsUrl}/api/v2/${apiType}/${id}/tag/${tag}" \
    -H 'Content-Type: application/json' -H "Authorization: Bearer  ${apiToken}");
    then
      logThis "Successfully set tag ${tag} on ${apiType} ${id}." "INFO"
      return 0
    else
      logThis "Could not set tag ${tag} on ${apiType} ${id}." "ERROR"
      return 1
    fi
  fi
}

##############################################################################
## Function Name: searchTag
## Purpose: This purpose of this function is to search for items matching the
##          specified tag of the specified API type such as alert or dashboard.
##
## Inputs:
##   ${1} - The first positional parameter is the apiType to execute. Such as
##          'dashboard', 'alert', or another API type.
##   ${2} - The second positional parameter is the tag that should be searched. 
## 
## Outputs:
##      The function returns an array of IDs with the tag.
##
##############################################################################

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
  local data
  data=$(eval "cat <<EOF
$(<${baseDir}/templates/searchTag.template)
EOF
" 2> /dev/null)
  curl -X 'POST' \
    "${CONF_aria_operationsUrl}/api/v2/search/${apiType}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer  ${apiToken}" \
    -d "${data}" | jq -r '.response.items' | jq -r '.[].id'
}

##############################################################################
## Function Name: removeTag
## Purpose: This function is to remove a tag from an object.
##
## Inputs:
##   ${1} - The first positional parameter is the json 'id' of the object to
##          remove the tag from.
##   ${2} - The second positional parameter is the apiType to execute. Such as
##          'dashboard', 'alert', or another API type.
##   ${3} - The third positional parameter is the tag that should be removed.
## 
## Outputs:
##          The following return values are returned:
##          0 - Successfully removed the tag
##          1 - Failed to remove the tag
##          3 - The tag was not set
##
##############################################################################

function removeTag {
 local id="${1}"
 local apiType="${2}"
 local tag="${3}"
 # Add variable validation to ensure variables are set.
  if [ -z "${id}" ];
  then
    logThis "Required parameter #1 'id' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard' or 'alert'\
     #3 the tag that should be set such as 'published.dashboard'" "Error"
  fi
  if [ -z "${apiType}" ];
  then
    logThis "Required parameter #2 'apiType' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard' or 'alert'\
     #3 the tag that should be set such as 'published.dashboard'" "Error"  
  fi
  if [ -z "${tag}" ];
  then
    logThis "Required parameter #3 'tag' missing." "SEVERE"
    logThis "The function SetACL requires 3 arguments in positional order. \
     #1 the ID of the object\
     #2 the apiType to query such as 'dashboard' or 'alert'\
     #3 the tag that should be set such as 'published.dashboard'" "Error"
  fi
  local result
  result=$(curl -X 'GET' \
  "${CONF_aria_operationsUrl}/api/v2/${apiType}/${id}/tag" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer  ${apiToken}" | jq -r '.response.items' | grep "${tag}")
  if [[ "${result}" == "  \"${tag}\"" ]];
  then
    if (curl -X 'DELETE' "${CONF_aria_operationsUrl}/api/v2/${apiType}/${id}/tag/${tag}" \
    -H 'Content-Type: application/json' -H "Authorization: Bearer  ${apiToken}");
    then
      logThis "Successfully removed tag ${tag} on ${apiType} ${id}." "INFO"
      return 0
    else
      logThis "Could not remove tag ${tag} on ${apiType} ${id}." "ERROR"
      return 1
    fi
  else
    logThis "The ${tag} tag is not set in the ${apiType} ${id}." "INFO"
    logThis "The ${apiType} ${id} does not have tag ${tag} set ${result}." "DEBUG"
    return 3
  fi
}

##############################################################################
## Function Name: createDir
## Purpose: The purpose of this function is to test to see if a directory 
##          exists and if not, to create it and the parent directories.
##
## Inputs:
##   ${1} - The first positional parameter is to specify the full path of the 
##          directory to create.
## 
## Outputs:
##          The directory passed to the function exists already or was created.
##          Returns 0 if successful and 1 if not successful.
##
##############################################################################

function createDir {
  local dir="${1}"
  if [ -z "${dir}" ];
  then
    logThis "Required parameter 'directoryPath' missing." "SEVERE"
  fi
  logThis "Checking ${dir}" "INFO"
  if [ -d "${dir}" ];
  then
    logThis "Directory ${dir} exists" "DEBUG"
  else
    logThis "Executing the command[mkdir ${dir}]" "DEBUG"
    if (mkdir -p "${dir}");
    then
      logThis "Successfully created ${dir}." "INFO"
      return 0
    else
      logThis "Error creating directory ${dir}." "CRITICAL"
      return 1
    fi
  fi
}

##############################################################################
## Function Name: extractResponse
## Purpose: This function is used to extract the sorted json response body 
##          from an API response.
##
## Inputs:
##   ${1} - first positional parameter passed will be the json file to 
##          extract the response, the filename.json is appended with 
##          the extension .response.  Pass the filepath without .response
##   ${2} - second positional parameter will be the directory where to store
##          the extracted response.
##
## Outputs:
##          When extracting the response, the filename.json is appended with 
##          the extension .response.  The file is stored in the directory 
##          passed in for parameter #2.
##
## Example:
##          extractResponse "/tmp/dashboard/mytestdashboard.json" \
##           "/tmp/dashboard/responses/"
##
##############################################################################

function extractResponse {
  local file="${1}"
  local dir="${2}"
  createDir "${dir}"
  logThis "Extracting JSON response body from file." "INFO"
  local _FILENAME
  _FILENAME=$(basename "${file}")
  logThis "Executing the command [jq -S '.response' ${file} > ${dir}/${_FILENAME}.response]" "DEBUG"
  jq -S '.response' "${file}" > "${dir}/${_FILENAME}.response" && logThis "Successfully extracted JSON response body." "INFO" || logThis "Could not extract JSON response body from file ${file}." "CRITICAL"
  logThis "Extracted JSON response body from file ${file} and storing it in the directory ${dir}." "DEBUG"
}

##################################################################################
## Function Name: scrubResponse
## Purpose: Process the json response body primarily to delete variant data for
##          file comparison. Such data may be last modified time, last updated by,
##          created by, etc.
##
## Inputs:
##   ${1} - first positional parameter passed will be the json file to scrub.
##          When extracting the response, the filename.json is appended with 
##          the extension .response.  Pass the filepath without .response
##   ${2} - second positional parameter will be the body of items to scrub out.
##
## Outputs:
##          When extracting the response, the filename.json is appended with 
##          the extension .response.  The output is the file without .response.
##
## Example:
## 
##   scrubBody="del(.disableRefreshInLiveMode) | \
##     del(.hideChartWarning) | \
##     del(.creatorId) | \
##     del(.updaterId) | \
##     del(.createdEpochMillis) | \
##     del(.updatedEpochMillis) | \
##     del(.deleted) | \
##     del(.numCharts) | \
##     del(.numFavorites) | \
##     del(.favorite)"
## 
##  scrubResponse "/tmp/dashboard/responses/mytestdashboard.json" "${scrubBody}"
##
##  The function would take the input from the file 
##    '/tmp/dashboard/responses/mytestdashboard.json.response'
##  and then remove the deletions in the scrubBody variable and save the file as
##    '/tmp/dashboard/responses/mytestdashboard.json'
##
##################################################################################

function scrubResponse {
  local jsonFile="${1}"
  local myScrubBody="${2}"
  logThis "Scrubbing response to remove metadata." "INFO"
  logThis "Executing command: [jq \"${myScrubBody}\" < \"${jsonFile}.response\" > ${jsonFile}]" "DEBUG"
  if jq "${myScrubBody}" < "${jsonFile}.response" > "${jsonFile}";
  then
    logThis "Successfully scrubbed JSON response body." "INFO" 
  else
    logThis "Could not scrub JSON response body from file ${jsonFile}.response." "CRITICAL"
  fi
}

##############################################################################
## Function Name: processCloneFileName
## Purpose: The purpose of this function is to process the filename and remove
##          any -Clone suffix to the name.
## Inputs:
##   ${1} - The first positional parameter to pass is the filename of the file
##          to process. Calling logic may pass _FILENAME which is defined in loop.
##          _FILENAME=$(basename "${filename}")     
##   ${2} - The second positional parameter to pass is the directory where the
##          response body is stored and where the file should be processed.
##          Common reference is the 'responseDir'
## 
## Outputs:
##          The output is setting _FILENAME to the new processed filename that
##          removes the -Clone* from the end of the name and adds .json ext.
##
##############################################################################

function processCloneFileName {
  local file="${1}"
  local dir="${2}"

  logThis "Stripping working copy Clone tags from filename ${file} before publishing." "INFO"
  newFILENAME=$(echo "${file}" | awk -F '-Clone' '{print $1}').json
  logThis "Rename the file ${dir}/${file}.response to ${dir}/${newFILENAME}.response" "INFO"
  mv "${dir}/${file}.response" "${dir}/${newFILENAME}.response"
  _FILENAME="${newFILENAME}"
  unset newFILENAME
}

##############################################################################
## Function Name: processCloneID
## Purpose: The purpose of this function is to process the url and id json keys
##          in the file. The function also returns the new ID 
##
## Inputs:
##   ${1} - The first positional parameter to pass is type of ID we to be 
##          processed. For example, you may pass 'dashboard' or 'alert'
##          We use this to aid in logging to make things easier to follow.
##   ${2} - The second positional parameter to pass is the ID of the object to
##          process. This may be the dashboardID or the alertID.
##   ${3} - The third positional parameter to pass is the filename of the file
##          to process. Calling logic may pass _FILENAME which is defined in loop.
##          _FILENAME=$(basename "${filename}")     
##   ${4} - The fourth positional parameter to pass is the directory where the
##          response body is stored and where the file should be processed.
##          Common reference is the 'responseDir'
##
## Outputs:
##          The output is processing the file and modifying the url and id
##          json keys in the file. The function also returns the new ID so 
##          call the function as the value of a variable.
##
## Example:
##   dashboardID=$(processCloneID 'dashboard' "${dashboardID}" "${_FILENAME}" "${responseDir}")
##
##############################################################################

function processCloneID {
  local type="${1}"
  local id="${2}"
  local file="${3}"
  local dir="${4}"
  logThis "Stripping working copy Clone tags from ${type} file ${file} before publishing." "INFO" true
  _ID=$(echo "${id}" | awk -F '-Clone' '{print $1}')
  logThis "Changing (${type}ID) in file from ${id} to ${_ID} in file ${file}." "DEBUG" true
  sed -i '.clone' "s/${id}/${_ID}/g" "${dir}/${file}.response"
  logThis "Changing dashboard name to remove the (Clone) designation." "DEBUG" true
  sed -i '' -E 's/ \(Clone.*$/",/' "${dir}/${file}.response"
  logThis "Changing (${type}ID) variable from ${id} to ${_ID}." "DEBUG" true
  echo "${_ID}"
}
