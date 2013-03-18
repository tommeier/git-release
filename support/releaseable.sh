#!/bin/sh -e

############################################################
#####               SUPPORT FUNCTIONS                  #####
############################################################

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


function get_last_tag_name() {
  local versioning_prefix=$1

  tags=$(get_release_tags $versioning_prefix)
  echo "$tags" | tail -1
}

#get_next_tag_name major release/production/v 1.0.4.3
function get_next_tag_name() {
  local versioning_type=$1
  local version_prefix=$2
  local last_tag_name=$3

  if [[ "$versioning_type" = "" ]]; then
    echo "Error : Versioning type required. eg. major"
    exit 1;
  fi;

  if [[ $last_tag_name = '' ]]; then
    last_tag_name=$(get_last_tag_name $version_prefix)

    if [[ $last_tag_name = '' ]]; then
      #No original tag name for version prefix - start increment
      last_tag_name="0.0.0"
    fi;
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

  echo "${version_prefix}${major_version}.${minor_version}.${patch_version}"
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
  local starting_point="$1"
  local end_point="$2"
  local log_filter="$3" #optional

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
  else
    echo "Error : Require starting and end points to calculate commits between points."
    exit 1;
  fi;

  local result=`eval $git_command $log_options $git_range`
  echo "$result"
}

############################################################
#####            CHANGELOG FUNCTIONS                   #####
############################################################

function changelog_divider() {
  echo "+=========================================================+"
}

function changelog_header() {
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

  local commit_shas=($@)
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
    general_release_lines+="`git show -s ${log_format} ${commit_shas[$i]}`\n"
  done;


  #1. Get text of commmits with author in brackets and list
  #2. Group by fixed tags (Feature --> Bug --> Others)
  #3. Ignore size & shape differences of tags (case insensitive ignore optional s within square brackets)
  #4. Optional format ( allow it to pass the format so only print the body)
  #Test Test Test
  #Optional args for this method, assume everything is SHA unless -f is passed
  echo "$general_release_lines"
  #"HOWDY"
}

#generate_changelog "$last_tag_name" "$next_tag_name"
function generate_changelog() {
  local starting_point="$1"
  local end_point="$2"
  local changelog_file="CHANGELOG"

  if [[ "$3" != '' ]]; then
    changelog_file="$3"
  fi;

  if [[ "$end_point" = "" ]]; then
    echo "Error : End point for changelog generation required."
    exit 1;
  fi;

  local commits=$(get_commits_between_points $starting_point $end_point)
  local commit_output=$(get_changelog_text_for_commits $commits)

  #TAGS
  #[Feature]
  #[Bug]
  #[Security]


  #Replace file -> TODO: Make optional/append
  rm -rf $changelog_file
  touch $changelog_file

  echo "$(changelog_header)"    >> $changelog_file
  echo "* Generated on $(date)" >> $changelog_file
  echo "$(changelog_divider)"   >> $changelog_file

  # local output_lines=(
  #   "* Generated on $(date)"
  #   $commit_output
  #   )
  for line in "${commit_output[@]}"
  do
    echo "|| ${line}" >> $changelog_file
  done
  # echo "$(changelog_header)" >> $changelog_file



  #echo '' >> $changelog_file
  #Get commits between 2 points
  #Scope to only pull requests optionally
  #If scoped to pull requests:
  #   = Capture body of each commit
  #else
  #   # print raw title of each commit
  #fi/
  #Save output to CHANGELOG file (append to start)

}
