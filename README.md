# Workflow run cleanup action

This action cleans up previously running instances of a workflow on the same branch. This accomplishes the task of automatically cancelling CI runs on pushes to the same branch, which is a common feature in most CI systems but currently not possible with GitHub actions.

## Configuration

None. The action uses the GitHub action environment variables to obtain the workflow name and branch. You must, however, create an [access token](https://github.com/settings/tokens) that includes the scope `repo`. Then, you can set the `GITHUB_TOKEN` environment variable:

## Example usage

```yaml
uses: rokroskar/workflow-run-cleanup-action
env:
  GITHUB_TOKEN: ${{ secret.GITHUB_TOKEN }}
```

You may want to disable this action from running on tags or master, especially if you have CD pipelines linked to your CI passing on every commit. In that case, something like this should work:

```yaml
name: CI
on:
  push: []
  jobs:
    cleanup-runs:
      runs-on: ubuntu-latest
      steps:
      - uses: rokroskar/workflow-run-cleanup-action@master
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
      if: "!startsWith(github.ref, 'refs/tags/') && github.ref != 'refs/heads/master'"
    ...
    other-jobs:
```
