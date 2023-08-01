# Notes

Dashboard board developer applies tag `staged.dashboard`

Concourse
retrieve data repo updates from git
prune local branches from upstream git
searches for tag `staged.dashboard`
Loop through list of dashboard IDs with tag
We create branch or checkout if existing branch
if local copy exists, compare with saas, else retrieve saas copy
if changes between local copy and saas copy exists, retrieve saas copy

Commit changes - svc account is who commits and author is dashboard author / last modified

create PR including link to working copy and published copy














Questions:

What do we do with the staged copy after publishing?
How should we handle multiple changes at once?
How do we name the PR?
