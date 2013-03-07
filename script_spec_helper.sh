#Script spec helpers

function script_directory() {
  "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

#Search argument 1 for substring in argument 2
function search_substring() {
  if echo "$1" | grep -q "$2"; then
    echo 'found'
  else
    echo 'missing'
  fi;
}

function should_succeed() {
  if [[ $? = 0 ]]; then
    return 0
  else
    return 1
  fi;
}

function should_fail() {
  ! is_successful
}

function enter_sandbox() {
  __DIR__="$PWD"
  rm -rf .sandbox
  mkdir -p .sandbox
  cd .sandbox
}

function remove_sandbox() {
  rm -rf .sandbox
}

function generate_sandbox_tags() {
  enter_sandbox
  git init
  touch 'commit_1'
  git add -A
  git commit -am "Initial Commit"

  local tag_names=( 'random_tag_1'
                    'release/v1.0.5'
                    'random_tag_2'
                    'release/v1.0.6'
                    'release/production/v1.0.9'
                    'release/staging/v2.0.3'
                    'release/staging/v1.0.2'
                    'release/production/v3.0.9'
                    'random_tag_3'
  )
  for i in "${!tag_names[@]}"; do
    touch "change${i}" &>/dev/null
    git add -A  &>/dev/null
    git commit -m "Change : ${i}" &>/dev/null
    git tag "${tag_names[$i]}" &>/dev/null
  done;
}
