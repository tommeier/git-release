#!/bin/bash -e

############################################################
#####                    GLOBALS                       #####
############################################################

TAG_VERSION_NUMBER_REGEX="([0-9]+)\\.([0-9]+)\\.([0-9]+)$"

############################################################
#####               SUPPORT FUNCTIONS                  #####
############################################################

validate_version_type() {
  #Confirm version type is in the accepted types
  local v="$1"
  local error_output="$2"

  if [[ $v != "major" && $v != 'minor' && $v != 'patch' ]]; then
    printf "incorrect versioning type: '%s'\\n" "$v" >&2
    echo "Please set to one of 'major', 'minor' or 'patch'" >&2
    echo "$error_output" >&2
    exit 1
  fi;
}

#Releaseable-deployed only
validate_deploy_tag() {
  local t="$1"
  local error_output="$2"

  if [[ "$t" = '' ]]; then
    echo "Required parameter: Please enter the deploy tag released."
    echo "$error_output"
    exit 1;
  elif [[ "$(git tag -l $t )" = '' ]]; then
    echo "Error: Unable to find tag '${t}'. Please check and try again."
    exit 1;
  fi;
}

versioning_prefix() {
  if [[ $2 ]]; then
    echo "${1}/${2}"
  else
    echo "${1}"
  fi;
}

############################################################
#####                TAG FUNCTIONS                     #####
############################################################

get_release_tags() {
  local filter=""
  local tag_names=""

  if [[ $1 ]]; then
    local tag_pattern=$1
    filter="${tag_pattern}*"
  fi;
  tag_names=$(git tag -l $filter)

  #<ref> tags/<release_prefix>/<version_prefix><version_number>
  echo "$tag_names"
}

get_last_tag_name() {
  local versioning_prefix=$1

  tags=$(get_release_tags $versioning_prefix)
  echo "$tags" | tail -1
}

get_versioning_prefix_from_tag() {
  local tag_name="$1"
  if [[ $tag_name =~ $TAG_VERSION_NUMBER_REGEX ]]; then
    local version_number=$BASH_REMATCH
    local version_prefix="${tag_name%%$version_number}"
  else
    echo "Error : Unable to determine version prefix from '${tag_name}'"
    exit 1;
  fi;
  echo "${version_prefix}"
}

get_version_number_from_tag() {
  local tag_name="$1"
  if [[ $tag_name =~ $TAG_VERSION_NUMBER_REGEX ]]; then
    local full_version=$BASH_REMATCH
  else
    echo "Error : Unable to determine version number from '${tag_name}'"
    exit 1;
  fi;
  #full stop delimited version number
  echo "$full_version"
}

get_next_version_number_from_tag() {
  local versioning_type=$1
  local tag_name=$2

  if [[ "$versioning_type" = "" ]]; then
    echo "Error : Versioning type required. eg. major"
    exit 1;
  fi;

  if [[ $tag_name = '' ]]; then
    #No original tag name for version prefix - start increment
    local tag_name="0.0.0"
  fi;

  if [[ $tag_name =~ $TAG_VERSION_NUMBER_REGEX ]]; then
    local full_version=$BASH_REMATCH
    local major_version="${BASH_REMATCH[1]}"
    local minor_version="${BASH_REMATCH[2]}"
    local patch_version="${BASH_REMATCH[3]}"
  else
    echo "Error : Unable to determine version number from '${tag_name}'"
    exit 1;
  fi;

  #Increment version
  case "$versioning_type" in
    'major' )
        major_version=$(( $major_version + 1 ));;
    'minor' )
        minor_version=$(( $minor_version + 1 ));;
    'patch' )
        patch_version=$(( $patch_version + 1 ));;
  esac

  echo "${major_version}.${minor_version}.${patch_version}"
}
