#!/bin/bash -e

#Script spec helpers

script_directory() {
  "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

#Search argument 1 for substring in argument 2
search_substring() {
  if echo "$1" | grep -q "$2"; then
    echo 'found'
  else
    echo 'missing'
  fi;
}

should_succeed() {
  if [[ $? = 0 ]]; then
    return 0
  else
    return 1
  fi;
}

should_fail() {
  ! should_succeed
}

file_should_exist() {
  if [[ -f $1 ]];
  then
    return 0;
  else
    return 1;
  fi;
}

file_should_not_exist() {
  ! file_should_exist $1
}

enter_sandbox() {
  __DIR__="$PWD"
  rm -rf .sandbox
  mkdir -p .sandbox
  cd .sandbox
}

remove_sandbox() {
  rm -rf .sandbox
}

generate_git_repo() {
  enter_sandbox
  git init
  touch 'commit_1'
  git add -A
  git commit -am "Initial Commit"
}

generate_sandbox_tags() {
  if [[ ! -f '.git' ]]; then
    #Generate git repo & enter sandbox
    generate_git_repo
  fi;

  #Optional arrays for sets of tags and commits
  if [[ "$1" != '' ]]; then
    declare -a tag_names=("${!1}")
  else
    local tag_names="$1"
  fi;
  if [[ "$2" != '' ]]; then
    declare -a tag_commit_messages=("${!2}")
  else
    local tag_commit_messages="$2"
  fi;

  if [[ $tag_names = '' ]]; then
    echo "Error - Please be specific on the tag names you want to generate";
    exit 1;
  fi;
  for i in "${!tag_names[@]}"; do
    touch "change${i}" &>/dev/null
    git add -A  &>/dev/null
    local commit_message="${tag_commit_messages[$i]}"
    if [[ "$commit_message" = '' ]]; then
      #Use default commit message
      commit_message="Change : ${i}";
    fi;
    git commit -m "$commit_message" &>/dev/null
    git tag "${tag_names[$i]}" &>/dev/null
  done;
}

# Stub bash commands and set arguments called with to STUB_LAST_CALLED_WITH
# For example:
#  * stub test_func
#  * test_func 'arg1' 'arg2'
#  * stub_last_called_with()
#  * > test_func stub: arg1 arg2
stub() {
  local cmd="$1"
  if [ "$2" == "STDERR" ]; then local redirect=" 1>&2"; fi

  if [[ "$(type "$cmd" | head -1)" == *"is a function" ]]; then
    local source="$(type "$cmd" | tail -n +2)"
    source="${source/$cmd/original_${cmd}}"
    eval "$source"
  fi

  eval "$(echo -e "${1}() {\n STUB_LAST_CALLED_WITH=\"$1 stub: \$@\"$redirect\n}")"
}

# Restore the original command/function that was stubbed with stub.
unstub() {
  local cmd="$1"
  unset -f "$cmd"
  if type "original_${cmd}" &>/dev/null; then
    if [[ "$(type "original_${cmd}" | head -1)" == *"is a function" ]]; then
      local source="$(type "original_$cmd" | tail -n +2)"
      source="${source/original_${cmd}/$cmd}"
      eval "$source"
      unset -f "original_${cmd}"
    fi
  fi
}

stub_last_called_with() {
  echo $STUB_LAST_CALLED_WITH;
}
