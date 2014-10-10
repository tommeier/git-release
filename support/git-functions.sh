#!/bin/bash -e

############################################################
#####                GIT FUNCTIONS                     #####
############################################################

get_github_repo_origin_url() {
  # Capture remote
  local remote_origin_url=$(git config --get remote.origin.url)

  if [[ "$remote_origin_url" = '' ]]; then
    echo "Error : Unable to determine the remote origin."
    echo "      : Set origin url with 'git remote set-url origin git://new.url.here'"
    exit 1;
  else
    local repo_regex="^(https?:\/\/|git:\/\/|git\@)?github\.com[:/]([^.]*)(.git)?$"
    if [[ $remote_origin_url =~ $repo_regex ]]; then
      local github_repo_url="https://github.com/${BASH_REMATCH[2]}"
      echo "$github_repo_url";
    else
      echo "Error : Unable to determine the remote repo url with format: '${remote_origin_url}'."
      exit 1;
    fi
  fi
}

check_tag_exists() {
  local tag_find=$(git tag -l "$1")
  if [[ "$tag_find" = '' ]]; then
    return 1;
  else
    return 0;
  fi;
}

current_git_version() {
  local git_version="`git --version`"
  local newline=$'\n'
  regex=".*git version ([0-9\.]+).*$"

  if [[ $git_version =~ $regex ]]; then
    local full_version=$BASH_REMATCH
    local version_number="${BASH_REMATCH[1]}"
    echo "$version_number"
  else
    echo "Error - Unable to determine git version."
  fi;
}

# We must ensure 2+ git version to allow for git tag sorting
# Its the only cross platform way to be sure of accurate sort
# Mac can `gsort -V`, others can `sort -V` but requires specific versions
ensure_git_version() {
  local git_version=$(current_git_version)
  local minimum_git_version="2.0.0"

  if (( $(echo "$git_version $minimum_git_version" | awk '{print ($1 < $2)}') )); then
    echo "Error - Minimum git version required for accurate version numbering is ${minimum_git_version}. Your version: $git_version" >&2
    exit 1
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
