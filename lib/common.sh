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

function parseYAML {
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

function compareFile {
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
