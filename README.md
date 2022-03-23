[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

# DEPRECATION WARNING

GitHub Action supports the functionality of this action natively with the `concurrency` command.

Please check out the release artice and the official docs:
* https://github.blog/changelog/2021-04-19-github-actions-limit-workflow-run-or-job-concurrency/
* https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency

# Workflow run cleanup action

This action cleans up previously running instances of a workflow
on the same branch. This accomplishes the task of automatically
cancelling CI runs on pushes to the same branch, which is a common
feature in most CI systems but currently not possible with
GitHub actions.

## Configuration

* `DEBUG`: if set to `TRUE` the debug logs will be printed.

* The action uses the GitHub action environment variables
to obtain the workflow name and branch. You must, however,
set the `GITHUB_TOKEN` environment variable:

*Note: if you use a personal access token, ensure that the `repo` scope is included.*

## Example usage

```yaml
uses: rokroskar/workflow-run-cleanup-action
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  DEBUG: FALSE
```

You may want to disable this action from running on tags or master,
especially if you have CD pipelines linked to your CI passing on
every commit. In that case, something like this should work:

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
