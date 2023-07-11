# Dashboard Development

To retrieve the json code for a dashboard that you have been working on, you will need the dashboard ID.

## Prepare working copy of repository

### Open an issue in repository

### Clone this repository

### Make your feature branch

## Retrieve the work that you have done in the SAAS visual editor

### Getting your API Token

An Operations for Applications API token is a string of hexadecimal characters and dashes.

#### To generate an API token for your user account

   1. Log in to your service instance (https://<your_instance>.wavefront.com) as a user with the API Tokens permission.
   2. Click the gear icon at the top right of the toolbar and select your user name.
   3. On the API Access page, click Generate. You can have up to 20 tokens at any given time. If you want to generate a new token but already have 20 tokens, then you must revoke one of the existing tokens.
   4. To revoke a token, click the Revoke button next for the token. Revoking a token cannot be undone. If you run a script that uses a revoked token, the script returns an authorization error.

#### To generate an API token for a service account

   1. Log in to your service instance (https://<your_instance>.wavefront.com) as a user with the Accounts permission.
   2. Click the gear icon at the top right of the toolbar and select Accounts.
   3. On the Service Accounts tab, click the ellipsis icon next to the service account for which you want to generate an API token, and select Edit.
   4. Click Generate. You can have up to 20 tokens per service account at any given time. If you want to generate a new token but already have 20 tokens, then you must revoke one of the existing tokens.
   5. To revoke a token, click the Revoke button next for the token. Revoking a token cannot be undone. If you run a script that uses a revoked token, the script returns an authorization error.

### Getting the Dashboard ID

The Dashboard ID and the URL are technically two different attributes of a dashboard, but the two attributes must match.
Here we are showing two different methods for retrieving the URL or Dashboard ID.

#### From the URL

   1. Log in to your service instance (https://<your_instance>.wavefront.com).
   2. Open your working copy of the dashboard.
   3. Click the &#8942;
   4. Click edit.
   5. Click `JSON`.
      1. Editing the JSON directly can have unforeseen consequences.
      2. Editing the JSON directly is advanced Dashboard Development.
   6. This will bring up a display with the JSON.
   7. Copy the value of `url:`.
   8. Close without saving the JSON window.
   9. Close without saving the dashboard.

#### From the list of Dashboards

   1. Log in to your service instance (https://<your_instance>.wavefront.com).
   2. Click Dashboards.
   3. Click All Dashboards.
   4. Search for your Dashboard.
   5. Copy value after `URL - `.

### Getting the Dashboard JSON

#### Using the bash script

Run the `bash` script `fetch_dashboard_json.sh` located in the root of this repository.

The script will prompt you for your API Token and Dashboard ID that was retrieved previously.
You may also set the linux environment variable `ENV_WAPI_USER_TOKEN` to prevent supplying the token each time.

The script will save the json file in the dashboards directory in the root of this repository.
If a file exists, you will be prompted to replace.
Where dashboardID is `Foundation-Capacity-Planner` the filename would be `dashboards/Foundation-Capacity-Planner.json`.

Do not edit the configs located in the `cfg/` directory unless you are changing global configurations for the pipeline.

#### Using the API explorer

   1. Log in to your service instance (https://<your_instance>.wavefront.com/api-docs/ui/) as a user with the API Tokens permission.
   2. Scroll down and expand `Dashboard`.
   3. Scroll down and expand `/api/v2/dashboard/{id}  Get a specific dashboard`.
   4. Enter the Dashboard ID previously obtained in the `id` field.
   5. Click execute.
   6. Scroll down to the Responses Section.
      1. Validate the `Code` is `200`
      2. Click download or copy on the `Response body`
   7. Save this response body in a file in the dashboards directory of this repository.
      1. This should be your feature branch.
      2. Filename should be {dashboardID}.json
         1. Where dashboardID is `Foundation-Capacity-Planner` the filename would be `Foundation-Capacity-Planner.json`.
         2. Above file will be placed in the `dashboards` directory in the root of this repository.

## Finalizing changes

### Document the issue

### Preparing for Pull Request

### Peer Review

### Submitting the PR

