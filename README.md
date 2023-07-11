# Aria Operations for Applications API tasks

## About

WAPI (Wavefront API) is a collection of pipelines and utilities to aid in a GitOps workflow that
is developer friendly and publishes changes in an idempotent nature. This suite focus it to be
an aid to pipelines by providing a repository for various changes along with a simple mechanism
that will control the edit permissions of published items as well as determine if there are
changes that need to be made, and if so make the changes.

***Alpha release only***

## Dashboard Development

For additional information on developing dashboards with this workflow, please see [Dashboard Development] (dashboards/DashboardDevelopment.md)

## `wapi.sh` Usage

    A single option of -d is required for task to work and app will cycle through dashboards and 
    compare with existing version. If changes are detected, then the app will push copy from the 
    dashboards directory.
    
    These options do not accept arguments
    At least one of these flags is required
    -a Process Alert modifications (future)
    -d Process Dashboard modifications
    -u Process Account modifications (future)
    -h Print this message

    These optional flags require arguments
    -i <value> Dashboard ID of the target Dashboard
    -s <value> Dashboard ID of the source Dashboard
    -t <value> API Token to override config API token

## Pipelines

At this time the pipelines directory is present and will house the concourse pipelines. The
pipelines are just rough templates at this time and will be filled out more as the
functionality evolves of the application.

### Concourse Pipelines

Concourse pipelines are in the `pipelines/concourse` directory of this repository.
