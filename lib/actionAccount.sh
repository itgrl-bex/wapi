#!/bin/bash

############################################################
#
# Purpose is to remove action specific logic to files.
# Reason is to simply and shorten main calling script.
# Benefit is that logic for specific action is easy to maintain.
#
############################################################


## Load common functions
source "${baseDir}/lib/common.sh"

source ${baseDir}/lib/libaccount.sh

