# Workflow run cleanup action

This action cleans up previously running instances of a workflow
on the same branch. This accomplishes the task of automatically
cancelling CI runs on pushes to the same branch, which is a common
feature in most CI systems but currently not possible with
GitHub actions.

## Configuration

None. The action uses the GitHub action environment variables
to obtain the workflow name and branch. You must, however,
set the `GITHUB_TOKEN` environment variable.

## Example usage

```yaml
uses: rokroskar/workflow-run-cleanup-action
env:
  GITHUB_TOKEN: ${{ secret.GITHUB_TOKEN }}
```
