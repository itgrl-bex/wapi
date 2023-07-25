#!/bin/bash

##################################################################################
#
# Purpose is to find objects that have been tagged as staged changes.
# Reason is to simply development workflow and have tooling perform PR creation.
# Benefit is that there are less steps for a developer to have to follow.
#
##################################################################################

## Load common functions
source common.sh

# Load appropriate git functions based on appropriate git management platform being used.
# shellcheck disable=SC1090 disable=SC2154
source "${baseDir}/lib/lib${CONF_repoManagementPlatform}.sh"

# load functions for functional areas, but may want to split into loading as needed.
source libDashboard.sh
source libAlert.sh
source libAccount.sh


