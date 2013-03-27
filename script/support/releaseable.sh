#!/bin/sh -e

############################################################
#####               SUPPORT FUNCTIONS                  #####
############################################################

#Releaseable only
function validate_version_type() {
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
function validate_deploy_tag() {
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

function check_tag_exists() {
  local tag_find=$(git tag -l "$1")
  if [[ "$tag_find" = '' ]]; then
    return 1;
  else
    return 0;
  fi;
}

function ensure_git_directory() {
  if [[ ! -d  '.git' ]]; then
    echo "Error - Not a git repository please run from the base of your git repo." >&2
    exit 1
  fi;
}

function ensure_git_is_clean() {
  local result=$(git status --porcelain)

  if [[ "$result" != '' ]]; then
    result=$(git status)
    echo "Error - Current branch is in a dirty state, please commit your changes first."
    echo "$result"
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

#TODO: Share method for splitting up values in regex, function should return array
#Get the version prefix from the tag name
# (strip out version numbers from suffix)
function get_versioning_prefix_from_tag() {
  local existing_tag_name="$1"
  regex="^(.*)([0-9]+)\\.([0-9]+)\\.([0-9]+)$"
  if [[ $existing_tag_name =~ $regex ]]; then
    local full_tag_name=$BASH_REMATCH
    local version_prefix="${BASH_REMATCH[1]}"
    local major_version="${BASH_REMATCH[2]}"
    local minor_version="${BASH_REMATCH[3]}"
    local patch_version="${BASH_REMATCH[4]}"
  else
    echo "Error : Unable to determine version prefix from '${existing_tag_name}'"
    exit 1;
  fi;
  echo "$version_prefix"
}

function get_last_tag_name() {
  local versioning_prefix=$1

  tags=$(get_release_tags $versioning_prefix)
  echo "$tags" | tail -1
}

function get_next_version_number() {
  local versioning_type=$1
  local last_tag_name=$2

  if [[ "$versioning_type" = "" ]]; then
    echo "Error : Versioning type required. eg. major"
    exit 1;
  fi;

  if [[ $last_tag_name = '' ]]; then
    #No original tag name for version prefix - start increment
    last_tag_name="0.0.0"
  fi;

  regex="([0-9]+)\\.([0-9]+)\\.([0-9]+)$"
  if [[ $last_tag_name =~ $regex ]]; then
    local full_version=$BASH_REMATCH
    local major_version="${BASH_REMATCH[1]}"
    local minor_version="${BASH_REMATCH[2]}"
    local patch_version="${BASH_REMATCH[3]}"
  else
    echo "Error : Unable to determine version number from '${last_tag_name}'"
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

function get_sha_for_tag_name() {
  local result=$(git show-ref --tags --hash $1)
  echo "$result"
}

function get_sha_for_first_commit() {
  local filter=$1
  local result=$(git log --reverse --format="%H" $filter | head -1)
  echo "$result"
}

function get_commit_message_for_first_commit() {
  local filter=$1
  local result=$(git log --reverse --format="%s" $filter | head -1)
  echo "$result"
}

function get_commit_message_for_latest_commit() {
  local filter=$1
  local result=$(git log -n1 --format="%s" $filter)
  echo "$result"
}

function get_commits_between_points() {
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

############################################################
#####            CHANGELOG FUNCTIONS                   #####
############################################################

function get_current_release_date() {
  echo $( date "+%A %d %B, %Y %l:%M%p" )
}

function changelog_divider() {
  echo "+=========================================================+"
}

function changelog_footer() {
local output=""
! read -d '' output <<"EOF"
||    _____ _                            _               ||
||   / ____| |                          | |              ||
||  | |    | |__   __ _ _ __   __ _  ___| | ___   __ _   ||
||  | |    | '_ \\ / _` | '_ \\ / _` |/ _ \\ |/ _ \\ / _` |  ||
||  | |____| | | | (_| | | | | (_| |  __/ | (_) | (_| |  ||
||   \\_____|_| |_|\\__,_|_| |_|\\__, |\\___|_|\\___/ \\__, |  ||
||                             __/ |              __/ |  ||
||                            |___/              |___/   ||
||                                                       ||
EOF
echo "$(changelog_divider)
$output
$(changelog_divider)"
}

function get_changelog_text_for_commits() {
  #Pass in commits array of SHA's
  #Return formatted changelog text, with tags handled
  #Optional first argument for the format "--format=%H"
  #TODO : Make tagging dynamic with features/bugs at top
  #TODO : Make changelog read in optional template to apply logic to view

  local previous_shopt_extglob=$(shopt -p extglob)
  local existing_shopt_nocasematch=$(shopt -p nocasematch)
  shopt -s nocasematch
  shopt -s extglob

  local commit_shas=($@)

  local feature_tag_lines=""
  local bug_tag_lines=""
  local security_tag_lines=""
  local general_release_lines=""

  local log_format="--format=%s"
  local log_format_matcher="\-\-format\="

  #Capture line by line unless first argument provides a custom format
  for i in "${!commit_shas[@]}"; do
    if [[ "${i}" = '0' ]]; then
      if echo "${commit_shas[$i]}" | grep -q "${log_format_matcher}"; then
        log_format="${commit_shas[$i]}";
        continue;
      fi;
    fi;

    local body_result="`git show -s ${log_format} ${commit_shas[$i]}`"

    regex="^\s*\[(features?|bugs?|security)\]\s*(.*)\s*$"
    if [[ $body_result =~ $regex ]]; then
      #Tagged entry
      local full_tag=$BASH_REMATCH
      local tag_type="${BASH_REMATCH[1]}"
      #Remove leading spaces (regex in bash capturing always)
      local tag_content="${BASH_REMATCH[2]##*( )}"
      #Add leading 2 spaces with bullet point for tagged line prefix & remove trailing spaces
      tag_content="  ${tag_content%%*( )}\n"
      #Sort matching tags
      case "$tag_type" in
          [fF][eE][aA][tT][uU][rR][eE] | [fF][eE][aA][tT][uU][rR][eE][sS] )
              feature_tag_lines+="${tag_content}";;
          [bB][uU][gG] | [bB][uU][gG][sS] )
              bug_tag_lines+="$tag_content";;
          [sS][eE][cC][uU][rR][iI][tT][yY] )
              security_tag_lines+="$tag_content";;
          * )
              general_release_lines+="$tag_content";;
      esac;
    else
      #Normal entry
      general_release_lines+="$body_result\n"
    fi;
  done;

  #Return previous setup for bash
  eval $previous_shopt_extglob
  eval $existing_shopt_nocasematch

  if [[ $feature_tag_lines != '' ]]; then
    echo "Features:\n${feature_tag_lines}"
  fi;
  if [[ $security_tag_lines != '' ]]; then
    echo "Security:\n${security_tag_lines}"
  fi;
  if [[ $bug_tag_lines != '' ]]; then
    echo "Bugs:\n${bug_tag_lines}"
  fi;
  echo "$general_release_lines"
}

#generate_version_file "$version_number" "$optional_file_name"
function generate_version_file(){
  local version_number="$1"
  if [[ "$version_number" = "" ]]; then
    echo "Error : Version number required for version file generation."
    exit 1;
  fi;
  if [[ "$2" != '' ]]; then
    local version_file="$2"
  else
    local version_file="VERSION" #optional
  fi;

  touch $version_file
  echo "${version_number}" > $version_file
}

#generate_changelog_file "$changelog_content" ":overwrite/:append" "$optional_file_name"
function generate_changelog_file(){
  local changelog_content="$1"
  local generate_strategy="$2"

  if [[ "$changelog_content" = "" ]]; then
    echo "Error : Changelog content required for version file generation."
    exit 1;
  fi;
  if [[ "$3" != '' ]]; then
    local changelog_file="$3"
  else
    local changelog_file="CHANGELOG" #optional
  fi;

  case "$generate_strategy" in
    ':overwrite' | 'overwrite' )
      #Remove existing
      #rm -rf $changelog_file;
      echo "$changelog_content\n$(changelog_footer)" > $changelog_file;; #Overwrite;
    ':append' | 'append' )
      #Initialise new file
      if [[ ! -f $changelog_file ]]; then
        touch $changelog_file;
        echo "$changelog_content
$(changelog_footer)" > $changelog_file;
      else
        #Append to start of file
        echo "$changelog_content\n$(cat $changelog_file)" > $changelog_file
      fi;;
    * )
      echo "Error : Generate strategy required. Please specify :overwrite or :append."
      exit 1;;
  esac
}

#generate_changelog_content "$last_tag_name" "$next_tag_name" ":all/:pulls_only"
function generate_changelog_content() {
  local release_name="$1"
  local commit_filter="$2"         #all_commits or pulls_only
  local starting_point="$3"        #optional
  local end_point="$4"             #optional
  local changelog_format="--format=%s" #default -> display title

  if [[ "$release_name" = "" ]]; then
    echo "Error : Release name required for changelog generation."
    exit 1;
  fi;

  # echo "IN CHANGELOG CONTENT : "
  # echo "release_name : ${release_name}"
  # echo "commit_filter : ${commit_filter}"
  # echo "starting_point : ${starting_point}"
  # echo "end_point : ${end_point}"

  case "$commit_filter" in
    ':all_commits' | 'all_commits' )
      #No filter
      commit_filter='';;
    ':pulls_only' | 'pulls_only' )
      #Filter by merged pull requests only
      commit_filter=$'^Merge pull request #.* from .*';
      changelog_format="--format=%b";; #use body of pull requests
    * )
      echo "Error : Commit filter required. Please specify :all or :pulls_only."
      exit 1;;
  esac

  local commits=$(get_commits_between_points "$starting_point" "$end_point" "$commit_filter")
  local commit_output=$(get_changelog_text_for_commits "$changelog_format" $commits)
  local release_date=$(get_current_release_date)

  echo "$(changelog_divider)
|| Release: ${release_name}
|| Released on ${release_date}
$(changelog_divider)
${commit_output}
$(changelog_divider)"
}
