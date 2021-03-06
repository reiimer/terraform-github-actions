#!/bin/bash

function terraformValidate {


  echo "init: info: initializing Terraform configuration in ${tfWorkingDir}"
  if [ "${tfWorkingDirLoop}" != "" ]; then
    EXITCODE=0
    validateOutput="$( for dir in  ${tfWorkingDirLoop}/*/; do echo $dir;(cd $dir; terraform validate ${*} 2>&1||exit $?)||EXITCODE=$?;done; exit ${EXITCODE} )"
    validateExitCode=${?}
  else
    validateOutput=$(terraform validate ${*} 2>&1)
    validateExitCode=${?}
  fi

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${validateExitCode} -eq 0 ]; then
    echo "validate: info: successfully validated Terraform configuration in ${tfWorkingDir}"
    echo "${validateOutput}"
    echo
    exit ${validateExitCode}
  fi

  # Exit code of !0 indicates failure.
  echo "validate: error: failed to validate Terraform configuration in ${tfWorkingDir}"
  echo "${validateOutput}"
  echo

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    validateCommentWrapper="#### \`terraform validate\` Failed

\`\`\`
${validateOutput}
\`\`\`

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`*"

    validateCommentWrapper=$(stripColors "${validateCommentWrapper}")
    echo "validate: info: creating JSON"
    validatePayload=$(echo "${validateCommentWrapper}" | jq -R --slurp '{body: .}')
    validateCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "validate: info: commenting on the pull request"
    echo "${validatePayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${validateCommentsURL}" > /dev/null
  fi

  exit ${validateExitCode}
}
