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

#git-release-deployed only
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

############################################################
#####                TAG FUNCTIONS                     #####
############################################################

get_release_tags() {
  local filter=""
  local tag_names=""
  local tag_prefix="$1"
  local sorted_tags=""

  if [[ "$tag_prefix" != '' ]]; then
    filter="${tag_prefix}*"
  fi;
  tag_names=$(git tag -l $filter)

  if [[ "$tag_prefix" != '' ]]; then
    # Strip tag prefix before sorting
    # Otherwise bash is unable to sort 0 leading padded versions and 0.x.10 boundaries
    local sortable_tag_lines=""
    IFS=$'\n'
    for tag_name in $tag_names
    do
      local version_without_prefix="${tag_name#$tag_prefix}"
      if [[ "$sortable_tag_lines" != "" ]]; then
          sortable_tag_lines="$sortable_tag_lines$IFS" # Add newline except on first item
        fi;
      sortable_tag_lines="$sortable_tag_lines${version_without_prefix}"
    done
    #sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4
    #gsort -V
    sorted_tag_versions=$(echo -e "$sortable_tag_lines" | gsort -V) #sort by number
    for sorted_tag_version in $sorted_tag_versions
    do
      if [[ "$sorted_tags" != "" ]]; then
        sorted_tags="$sorted_tags$IFS" # Add newline except on first item
      fi;
      sorted_tags="$sorted_tags${tag_prefix}${sorted_tag_version}" #reappend tag prefix
    done
    # sorted_tags="${sorted_tags%$'\n'}" #remove last newline
  else
    # -n -t. -k1,1 -k2,2 -k3,3
    sorted_tags=$(echo -e "$tag_names" | gsort -V) #sort by number
  fi;
  # echo "Sorted:"
  # echo "$sorted_tags"


  # for tag_name in $tag_names
  # do
  #   sortable_tag_lines="$sortable_tag_lines${tag_name#filter}\n"
  # done
  #<ref> tags/<release_prefix><version_number>

#   for item in `cat list.txt`
# do
#         echo "Item: $item"
# done
  # Sort by base version numbers (known issue with non-zero padded majors)
  # TODO: Remove 'filter' text before sorting, then reappend for accurate sort
  echo -e "$sorted_tags"
  # | gsort -V
  # sort -n -t. -k1,1 -k2,2 -k3,3
  #
}

get_last_tag_name() {
  local versioning_prefix=$1

  local tags=$(get_release_tags "$versioning_prefix")
  echo -e "$tags" | tail -1
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
        major_version=$(( $major_version + 1 ));
        minor_version="0";
        patch_version="0";;
    'minor' )
        minor_version=$(( $minor_version + 1 ));
        patch_version="0";;
    'patch' )
        patch_version=$(( $patch_version + 1 ));;
  esac

  echo "${major_version}.${minor_version}.${patch_version}"
}
