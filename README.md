# fastlane-actions
Collection of Fastlane Actions to help automate some continious delivery tasks.

These extensions have not been contributed to the main Fastlane repository because they depend on third-party APIs. 

## Actions
### Jenkins
* Get Jenkins Job
* Build Jenkins Job
* Wait For Jenkins Job
* Download Jenkins Artifact

### JIRA
* Add Jira Attachment
* Create Jira Issue

### GitLab
* Test GitLab Access
* Set GitLab Release
* Add Gitlab Tag

### GitHub
* Test GitHub Access

## Helper Lanes
* `gitlab_tag` - Creates a tag on Gitlab if it doesn't exist else raises error
* `gitlab_release` - Creates a Gitlab release for a tag, updates it if it already exists else or raises error
* `get_jenkins_job` - Returns the next build number for a Jenkins job
* `attach_files_to_jira_ticket` - Attaches array of filepaths to a single existing JIRA ticket and raises errors

