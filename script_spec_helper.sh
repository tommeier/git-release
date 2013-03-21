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
  ! should_succeed
}

function file_should_exist() {
  if [[ -f $1 ]];
  then
    return 0;
  else
    return 1;
  fi;
}

function file_should_not_exist() {
  ! file_should_exist $1
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

function generate_git_repo() {
  enter_sandbox
  git init
  touch 'commit_1'
  git add -A
  git commit -am "Initial Commit"
}

function generate_sandbox_tags() {
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
    #Use default set of tag names. TODO: remove over time, and let specs be explicit
    tag_names=( 'random_tag_1'
                      'release/v1.0.5'
                      'random_tag_2'
                      'release/v1.0.6'
                      'release/production/v1.0.9'
                      'release/staging/v2.0.3'
                      'release/staging/v1.0.2'
                      'release/production/v3.1.9'
                      'release/production/v3.0.9'
                      'random_tag_3'
    )
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

function check_tag_exists() {
  local filtered_tags=$(git tag -l $1)
  local search_for_tag=$(search_substring "$filtered_tags" "$1")
  if [[ "$search_for_tag" = "found" ]]; then
    return 0;
  else
    return 1;
  fi;
}
