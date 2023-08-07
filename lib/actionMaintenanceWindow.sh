#!/bin/bash

############################################################
#
# Actions to create Alert workflow Maintenance Windows
#
############################################################

source "${baseDir}/lib/common.sh"
source "${baseDir}/lib/libAlert.sh"

# Are we managing the developing maintenance window creation?
if ${CONF_alert_developing_maintenancewindow_create};
then
  logThis "Checking to see if maintenance window '${CONF_alert_developing_maintenancewindow_title}' exists." "INFO"
  if [[ -n $(searchMaintenanceWindow "${CONF_alert_developing_maintenancewindow_title}") ]];
  then
    # Maintenance Window exists
    logThis "The maintenance window '${CONF_alert_developing_maintenancewindow_title}' exists." "INFO"
  else
    # Maintenance Window does not exist
    logThis "The maintenance window '${CONF_alert_developing_maintenancewindow_title}' does not exist." "INFO"
    if (createMaintenanceWindow "${CONF_alert_developing_maintenancewindow_jsonTemplate}" \
    "${CONF_alert_developing_maintenancewindow_title}" \
    "${CONF_alert_developing_maintenancewindow_reason}" \
    "${CONF_alert_developing_tag}");
    then
      logThis "Successfully created maintenance window '${CONF_alert_developing_maintenancewindow_title}'." "INFO"
    else
      logThis "There was an error creating maintenance window '${CONF_alert_developing_maintenancewindow_title}'" "ERROR"
    fi
  fi
fi

# Are we managing the staged maintenance window creation?
if ${CONF_alert_staged_maintenancewindow_create};
then
  logThis "Checking to see if maintenance window '${CONF_alert_staged_maintenancewindow_title}' exists." "INFO"
  if [[ -n $(searchMaintenanceWindow "${CONF_alert_staged_maintenancewindow_title}") ]];
  then
    # Maintenance Window exists
    logThis "The maintenance window '${CONF_alert_staged_maintenancewindow_title}' exists." "INFO"
  else
    # Maintenance Window does not exist
    logThis "The maintenance window '${CONF_alert_staged_maintenancewindow_title}' does not exist." "INFO"
    if (createMaintenanceWindow "${CONF_alert_staged_maintenancewindow_jsonTemplate}" \
    "${CONF_alert_staged_maintenancewindow_title}" \
    "${CONF_alert_staged_maintenancewindow_reason}" \
    "${CONF_alert_staged_tag}");
    then
      logThis "Successfully created maintenance window '${CONF_alert_staged_maintenancewindow_title}'." "INFO"
    else
      logThis "There was an error creating maintenance window '${CONF_alert_staged_maintenancewindow_title}'." "ERROR"
    fi
  fi
fi
