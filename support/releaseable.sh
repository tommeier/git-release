#!/bin/sh -e

############################################################
#####               SUPPORT FUNCTIONS                  #####
############################################################

function validate_version_type() {
  #Confirm version type is in the accepted types
  local v="$1"
  local error_output="$2"

  if [[ $v != "major" && $v != 'minor' && $v != 'patch' ]]; then
    printf "incorrect versioning type: '%s'\n" "$v" >&2
    echo "Please set to one of 'major', 'minor' or 'patch'" >&2
    echo "$error_output" >&2
    exit 1
  fi;
}

function ensure_git_directory() {
  if [[ ! -d  '.git' ]]; then
    echo "Error - Not a git repository please run from the base of your git repo." >&2
    exit 1
  fi;
}

function versioning_prefix() {
  if [[ $2 ]]; then
    echo "${1}/${2}"
  else
    echo "${1}"
  fi;
}

############################################################
#####                TAG FUNCTIONS                     #####
############################################################

function get_release_tags() {
  # refs=`git log --date-order --simplify-by-decoration --pretty=format:%H`
  # ref_list=$(IFS=' '; echo "${refs[*]}")
  #tag_pattern="${RELEASE_PREFIX}/${VERSION_PREFIX}"

  local filter=""
  if [[ $1 ]]; then
    tag_pattern=$1
    filter="${tag_pattern}*"
  fi;
  tag_names=$(git tag -l $filter)

  #git name-rev --tags --all
  #00003b0ff9826fc1a8a2e6cd904e8a7d3ef5b9c6 tags/20110818_1_ultimate_warrior~1^2
  #0800aaa7cf30a6645108800931291b2bbff0be2e tags/20120213_1103_hulk_hogan~5^2
  #0900e412938f81238593e59247536ce116379d7c tags/20110812_1_release_ultimate_warrior~73

  #<ref> tags/<release_prefix>/<version_prefix><version_number>
  echo "$tag_names"
}
