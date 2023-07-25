#!/bin/bash

##################################################################################
#
# Purpose is to remove action specific logic to files.
# Reason is to simply and shorten main calling script.
# Benefit is that logic for specific action is easy to maintain.
#
##################################################################################

## Load init to load the config
# shellcheck source="../../init.sh"
source "../../init.sh"
unset myDir

## Load common functions
# shellcheck source="../../lib/common.sh"
source "../../lib/common.sh"
# shellcheck source="../../lib/libDashboard.sh"
source "../../lib/libDashboard.sh"

for filename in "${dashboardDir}"/*.json;
do
  _FILENAME=$(basename "${filename}")
  getDashboardID "${filename}"
  scrubResponse "${responseDir}/${_FILENAME}"
done
