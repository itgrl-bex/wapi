# Aria Operations for Applications API tasks

## About

WAPI (Wavefront API) is a collection of pipelines and utilities to aid in a GitOps workflow that
is developer friendly and publishes changes in an idempotent nature. This suite focus it to be
an aid to pipelines by providing a repository for various changes along with a simple mechanism
that will control the edit permissions of published items as well as determine if there are
changes that need to be made, and if so make the changes.

***Alpha release only***

## Setup

In the `cfg` directory of this repository, you will find the example configuration file.  
Copy the file `cfg\example-config.yaml` to `cfg/config.yaml` and edit the settings specific to your needs.

Common settings to update will be the settings identified below:

```yaml
aria:
  svc_account: 'sa::example-dashboards-gitops'
  api_token: '4example-th1s-ismy-d3m0-apitoken4u2c'
  operations_url: 'https://vmware.wavefront.com'
```

## Dashboard Development

For additional information on developing dashboards with this workflow, please see [Dashboard Development](dashboards/DashboardDevelopment.md).

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
-i OPTION_VALUE Dashboard ID of the target Dashboard
-s OPTION_VALUE Dashboard ID of the source Dashboard
-t OPTION_VALUE API Token to override config API token

## Pipelines

At this time the pipelines directory is present and will house the concourse pipelines. The
pipelines are just rough templates at this time and will be filled out more as the
functionality evolves of the application.

### Concourse Pipelines

Concourse pipelines are in the `pipelines/concourse` directory of this repository.
