#!/usr/bin/env bash
[[ "TRUE" == "${DEBUG}" ]] && set -x # enable debug
set -e # fail fast
# simple script to cancel a github actions workflow given its name

#################### CONSTANTS AND HELPER FUNCTIONS  ####################

GITHUB_API="https://api.github.com"
ACCEPT_HEADER="Accept: application/vnd.github.v3+json"

WORKFLOW_ID_KEY="workflow_id"
BRANCH_KEY="branch"
REPO_KEY="repo"

function validate_required_env_variables() {
  local required_env_variables=( "GITHUB_TOKEN" "GITHUB_REPOSITORY" "GITHUB_RUN_ID" )

  for env in "${required_env_variables[@]}"; do
    if [ -z "${!env}" ]; then
      echo "Must specify ${env}"
      exit 1
    fi
  done
}

function extractMetaInformation() {
  jq "{ ${WORKFLOW_ID_KEY}: .workflow_id, ${BRANCH_KEY}: .head_branch, ${REPO_KEY}: .head_repository.full_name}"
}

function getRunningWorkflowIds() {
  local workflow_ids
  workflow_ids=$(jq ".workflow_runs | .[] | select(.head_branch==\"${branch}\" and .head_repository.full_name==\"${repo}\" and (.status==\"in_progress\" or .status==\"queued\" or .status== \"waiting\")) | .id ")
  local condition="<"
  for id in $workflow_ids; do
    if [[ "$id" -gt "$GITHUB_RUN_ID" ]]; then
      condition="<="
      break
    fi
  done
  echo "$workflow_ids" | jq "select( . $condition $GITHUB_RUN_ID )"
}

#################### MAIN CODE ####################

validate_required_env_variables

auth_header="Authorization: token ${GITHUB_TOKEN}"

# extract meta information for current workflow run
meta_data="$( curl -s "${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" -H "${auth_header}" -H "${ACCEPT_HEADER}" | extractMetaInformation )"
workflow_id="$( echo "$meta_data" | jq -r ".${WORKFLOW_ID_KEY}" )"
branch="$( echo "$meta_data" | jq -r ".${BRANCH_KEY}" )"
repo="$( echo "$meta_data" | jq -r ".${REPO_KEY}" )"

echo "workflow id: ${workflow_id}"
echo "branch: ${branch}"
echo "repo: ${repo}"

# get the run ids for runs on same branch/repo
run_ids=$( curl -s "${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow_id}/runs" -H "${auth_header}" -H "${ACCEPT_HEADER}" | getRunningWorkflowIds )

echo "run ids: ${run_ids}"

# cancel the previous runs
for run_id in $run_ids; do
  curl -s -X POST "${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/runs/${run_id}/cancel" -H "${auth_header}" -H "${ACCEPT_HEADER}"
  echo "Cancelled run $run_id"
done
