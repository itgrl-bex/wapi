# Dashboard Development

This document will provide general guidance on how to use the tools for dashboard development.

## Prepare working copy of repository

The working copy will be stored on your development workstation in folder that is somewhere that only you can get. The reason for this is so that only you can make commits and push code using your keys or credentials.  Each dashboard developer should have their own copy of the code and not share a copy. The sharing is done through the remote git repository.

### Clone this repository

[The WAPI Repository](https://github.com/itgrl-bex/wapi) is where it all begins.

1. Click the [link](https://github.com/itgrl-bex/wapi)
2. Click on the down arrow in the green `Code` button
3. Choose protocol
   1. Choose SSH or HTML and copy URL
   2. Download as a zip file
4. Clone or extract the repository into a directory on your development workstation.

### Open an issue in repository

Whenever we are working on a change or have an issue with the tooling, we should open an issue in the repository.
The issues will help identify items reported to be worked on as well as identify what is currently being worked.
Each PR should be linked to an issue so that all communication related to the change can be related and tracked.
Additionally all communications should be handled through the issue or the PR related to the change so they can easily be seen.
The Jira story should also be linked to the issue when opening to complete the reference and transparency.

1. Open the repository.
2. Click issues.
3. Click new issue.
4. The Title should start with the Jira # of the story.
5. Provide a detailed description of the issue.
6. If you are doing the dashboard development, assign the issue to yourself.

### Make your feature branch

Feature branches are a good way to track code related to specific issues or user stories.
Since we create issues in the repos, we should start our feature branch with the issue number
and then follow it with a short description of the change.

1. We created issue number 12 to add an additional chart for max memory usage for the day.
2. We have cloned our repository to our development workstation.
3. We should now do a git pull --rebase on the main branch on our development workstation.
4. After ensuring that we have all the latest changes at the time in our local main branch,
   1. Create feature branch starting with 12_max-mem-usage-daily on your development workstation.
   2. Make all changes related to this issue in this feature branch.
   3. Do not make changes related to other issues in this feature branch.
5. Ensure that you are in the feature branch that you just created on your development workstation.

## Dashboard editing

### Create a new Dashboard

   1. Log in to your service instance (https://<your_instance>.wavefront.com) as a user with the API Tokens permission.
   2. Click `Dashboards` in the top left.
      1. In the dropdown click `Create Dashboard`.
      2. Name the dashboard by entering a name in the upper left.
   3. Make all the required edits to your working copy of the dashboard.
   4. Test the dashboard functionality.
   5. Optimize your slow queries.
   6. Test again and repeat as necessary.
   7. Save the dashboard.
   8. When ready to publish the dashboard:
      1. After publishing, all edits must follow the workflow `Edit a published Dashboard`.
      2. Click `Dashboards` in the top left.
         1. In the dropdown click `All Dashboards`.
      3. Search for your dashboard but do not open it.
      4. Check the box next to your dashboard.
      5. Click on `+ Tag` just under the search bar.
      6. Choose or create the tag to publish the dashboard.
         1. This tag is a configurable item.
         2. The default tag is `published.dashboard`
   9. You're done, and the pipeline will modify the ACLs.

### Edit a published Dashboard

Create and change your working copy of the dashboard:

   1. Log in to your service instance (https://<your_instance>.wavefront.com) as a user with the API Tokens permission.
   2. Navigate to the dashboard that you wish to change.
   3. Click the &#8942;
   4. Click Clone.
   5. The name field should end in (Clone)
   6. The url should end in -Clone
      1. You can optionally set an identifier such as -Clone-1
      2. The URL you set here will be the dashboardID of your working copy.
   7. Make all the required edits to your working copy of the dashboard.
   8. Save the dashboard.
   9. Test the dashboard functionality.
   10. Optimize your slow queries.
   11. Test again and repeat as necessary.
   12. You're ready to publish your changes.

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
   5. Copy value after `URL -`.

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

We want to make sure that we document any gotchas, design decision points, and the overall change in the issue.
It is a good habit to have this information documented and you can alway use or reference it in your pull request and peer reviews later.

### Preparing for Pull Request (PR)

One of the first things we should do in preparation for a PR is to make sure that we have documented our changes and that we are ready for a peer review. After that is done, we also want to ensure that we have the latest copy of the main branch so that we incorporate any new code or changes that may have taken place while we were developing.  

1. We should now do a git pull --rebase on the main branch on our development workstation.
2. Now we should merge the main branch into our feature branch.
3. Next we need to resolve any merge conflicts that may arise.
4. After a quick review of the merge and merge conflict resolution,
   1. We need to review our code changes and make sure they are still good.
   2. We need to commit the merge and conflict resolution.
   3. We then need to push or publish our feature branch to the remote repository.

### Peer Review

Peer review is a good way to ensure that the requirements of the issue are being met by the change and that our interpretation of the requirements is on par with what is expected. A peer review also helps keep the code base more consistent so that it does not end up being the wild, wild west.

A peer code review could be as simple as sending a peer the link to your working copy of the dashboard and the link to your published feature branch to review.

### Submitting the Pull Request (PR)

Create the PR in the repository and include all design decisions, Jira story #s, who did the peer review, and a synopsis of what the change is. You should also link the Pull Request to the issue so they can both be closed at the same time.
