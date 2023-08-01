#!/bin/bash

##################################################################################
#
# Task script for pipelines to be called by init.sh
#
##################################################################################

## Load common functions
source "${baseDir}/lib/common.sh"
source "${baseDir}/lib/libDashboard.sh"

for filename in "${dashboardDir}"/*.json;
do
  _FILENAME=$(basename "${filename}")
  getDashboardID "${filename}"
  scrubResponse "${responseDir}/${_FILENAME}"
done
