#!/bin/bash

function terraformInit {
  # Gather the output of `terraform init`.
  echo "init: info: initializing Terraform configuration in ${tfWorkingDir}"
  if [ "${tfWorkingDirLoop}" != "" ]; then
    EXITCODE=0
    initOutput="$( for dir in  ${tfWorkingDirLoop}/*/; do echo $dir; terraform init -input=false ${*} $dir 2>&1||EXITCODE=1;done; exit ${EXITCODE} )"
    initExitCode=${?}
  else
    initOutput=$(terraform init -input=false ${*} 2>&1)
    initExitCode=${?}
  fi

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${initExitCode} -eq 0 ]; then
    echo "init: info: successfully initialized Terraform configuration in ${tfWorkingDir}"
    echo "${initOutput}"
    echo
    exit ${initExitCode}
  fi

  # Exit code of !0 indicates failure.
  echo "init: error: failed to initialize Terraform configuration in ${tfWorkingDir}"
  echo "${initOutput}"
  echo

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    initCommentWrapper="#### \`terraform init\` Failed

\`\`\`
${initOutput}
\`\`\`

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`*"

    initCommentWrapper=$(stripColors "${initCommentWrapper}")
    echo "init: info: creating JSON"
    initPayload=$(echo "${initCommentWrapper}" | jq -R --slurp '{body: .}')
    initCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "init: info: commenting on the pull request"
    echo "${initPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${initCommentsURL}" > /dev/null
  fi

  exit ${initExitCode}
}
