#!/usr/bin/env bash
set -x
# simple script to cancel a github actions workflow given its name

if [ -z "$GITHUB_WORKFLOW" ]
then
  echo "Must specify GITHUB_WORKFLOW"
  exit 1
fi

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

if [ -z "$GITHUB_HEAD_REF" ]
then
  # we have a push event
  BRANCH=${GITHUB_REF:11}
else
  BRANCH=${GITHUB_HEAD_REF}
fi

# jq queries
jq_run_ids=".workflow_runs | .[] | select(.head_branch==\"${BRANCH}\" and (.status==\"in_progress\" or .status==\"queued\" or .status==\"waiting\")) | .id"

# get the github workflow ID

GITHUB_API=https://api.github.com

auth_header="Authorization: token ${GITHUB_TOKEN}"

workflow_url=$(curl -s ${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID} -H "${auth_header}" | jq -r '.workflow_url' | cut -d/ -f2-)
workflow_id=${workflow_url##/*/}
echo "workflow id: "$workflow_id

# get the run ids
run_ids=$(curl -s ${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow_id}/runs -H "${auth_header}" | jq -r "${jq_run_ids}" | sort -n | head -n-1)

echo "run ids: "$run_ids

# cancel the previous runs
for run_id in $run_ids
do
  curl -s -X POST -H "${auth_header}" ${GITHUB_API}/repos/${GITHUB_REPOSITORY}/actions/runs/${run_id}/cancel
  echo "Cancelled run $run_id"
done
