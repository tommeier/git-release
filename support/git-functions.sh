#!/bin/bash -e

RELEASEABLE_GIT_LOADED='true'

############################################################
#####                GIT FUNCTIONS                     #####
############################################################

check_tag_exists() {
  local tag_find=$(git tag -l "$1")
  if [[ "$tag_find" = '' ]]; then
    return 1;
  else
    return 0;
  fi;
}

ensure_git_directory() {
  if [[ ! -d  '.git' ]]; then
    echo "Error - Not a git repository please run from the base of your git repo." >&2
    exit 1
  fi;
}

ensure_git_is_clean() {
  local result=$(git status --porcelain)

  if [[ "$result" != '' ]]; then
    result=$(git status)
    echo "Error - Current branch is in a dirty state, please commit your changes first."
    echo "$result"
    exit 1
  fi;
}

get_sha_for_tag_name() {
  local result=$(git show-ref --tags --hash $1)
  echo "$result"
}

get_sha_for_first_commit() {
  local filter=$1
  local result=$(git log --reverse --format="%H" $filter | head -1)
  echo "$result"
}

get_commit_message_for_first_commit() {
  local filter=$1
  local result=$(git log --reverse --format="%s" $filter | head -1)
  echo "$result"
}

get_commit_message_for_latest_commit() {
  local filter=$1
  local result=$(git log -n1 --format="%s" $filter)
  echo "$result"
}

get_commits_between_points() {
  local starting_point="$1" #optional
  local end_point="$2"      #optional
  local log_filter="$3"     #optional

  local git_command="git log";
  local log_options="--no-notes --format=%H"
  local git_range=""

  if [[ "$log_filter" != '' ]]; then
    log_options="$log_options --grep="'"'"$log_filter"'"'""
  fi;
  if [[ "$starting_point" != '' && "$end_point" != '' ]]; then
    git_range="${starting_point}^1..${end_point}";
  elif [[ "$end_point" != '' ]]; then
    git_range="${end_point}"
  elif [[ "$starting_point" != '' ]]; then
    git_range="${starting_point}^1..HEAD"
  fi;

  eval $git_command $log_options $git_range
}
