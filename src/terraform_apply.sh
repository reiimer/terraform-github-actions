#!/bin/bash

function terraformApply {
  # Gather the output of `terraform apply`.
  echo "apply: info: applying Terraform configuration in ${tfWorkingDir}"
    if [ "${tfWorkingDirLoop}" != "" ]; then
      EXITCODE=0
       echo "Printing params: ${TF_CLI_ARGS}"
      applyOutput="$( for dir in  ${tfWorkingDirLoop}/*/; do echo $dir; (set -x; cd $dir; terraform apply -input=false ${*} 2>&1|| exit $?)||EXITCODE=$?;done; exit ${EXITCODE} )"
      applyExitCode=${?}
    else
      applyOutput=$(terraform apply -input=false ${*} 2>&1)
      applyExitCode=${?}
    fi
  applyCommentStatus="Failed"

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${applyExitCode} -eq 0 ]; then
    echo "apply: info: successfully applied Terraform configuration in ${tfWorkingDir}"
    echo "${applyOutput}"
    echo
    applyCommentStatus="Success"
  fi

  # Exit code of !0 indicates failure.
  if [ ${applyExitCode} -ne 0 ]; then
    echo "apply: error: failed to apply Terraform configuration in ${tfWorkingDir}"
    echo "${applyOutput}"
    echo
  fi

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    applyCommentWrapper="#### \`terraform apply\` ${applyCommentStatus}
<details><summary>Show Output</summary>

\`\`\`
${applyOutput}
\`\`\`

</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`*"

    applyCommentWrapper=$(stripColors "${applyCommentWrapper}")
    echo "apply: info: creating JSON"
    applyPayload=$(echo "${applyCommentWrapper}" | jq -R --slurp '{body: .}')
    applyCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "apply: info: commenting on the pull request"
    echo "${applyPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${applyCommentsURL}" > /dev/null
  fi
  exit ${applyExitCode}
}
