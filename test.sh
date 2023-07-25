#!/bin/bash

function commit {
  local msgType="${1}"
  local msgID="${2}"
  local author="${3}"
  local template="${4}"
  echo "${path}/${repo}" || echo 'failed to change directories'
  echo "  git add ."
  local message=$(eval "cat <<EOF
$(<${template})
EOF
" 2> /dev/null)

  # shellcheck disable=SC2046
  echo "commit --author=\"${author}\" -am ${message}"
}


commit 'dashboard' 'mydashboard' 'tinkerbell' 'templates/commitMsg.template'



