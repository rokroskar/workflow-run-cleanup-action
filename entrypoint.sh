#!/usr/bin/env bash
set -x # enable debug
# simple script to cancel a github actions workflow given its name

if [ -z "$GITHUB_TOKEN" ]
then
  echo "Must specify GITHUB_TOKEN"
  exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]
then
  echo "Must specify GITHUB_REPOSITORY"
  exit 1
fi

if [ -z "$GITHUB_RUN_ID" ]
then
  echo "Must specify GITHUB_RUN_ID"
  exit 1
fi

GITHUB_API=https://api.github.com

auth_header="Authorization: token ${GITHUB_TOKEN}"
accept_header="Accept: application/vnd.github.v3+json"

function extractMetaInformation() {
  jq "{ workflow_id: .workflow_id, branch: .head_branch, repo: .head_repository.full_name}"
}

function convertToKeyValuePairs() {
  jq -r "to_entries | map(\"\(.key)=\(.value | tostring)\") | .[]"
}

function getRunningWorkflowIds() {
  jq ".workflow_runs | .[] | select(.head_branch==\"${branch}\" and .head_repository.full_name==\"${repo}\" and .status==\"in_progress\" or .status==\"queued\" or .status== \"waiting\") | .id " | grep -v "${GITHUB_RUN_ID}"
}

function exportAll() {
  for var in $1; do
    export $var
  done
}

# extract meta information for current workflow run
exportAll "$(curl -s "${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" -H "${auth_header}" -H "${accept_header}" | extractMetaInformation | convertToKeyValuePairs)"
echo "workflow id: $workflow_id"
echo "branch: $branch"
echo "repo: $repo"

# get the run ids for runs on same branch/repo
run_ids=$(curl -s ${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow_id}/runs -H "${auth_header}" -H "${accept_header}" | getRunningWorkflowIds)

echo "run ids: ${run_ids}"

# cancel the previous runs
for run_id in $run_ids; do
  curl -s -X POST -H "${auth_header}" -H "${accept_header}" ${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/runs/${run_id}/cancel
  echo "Cancelled run $run_id"
done
