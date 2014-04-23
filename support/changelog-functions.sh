#!/bin/bash -e

############################################################
#####            CHANGELOG FUNCTIONS                   #####
############################################################

get_current_release_date() {
  echo $( date "+%A %d %B, %Y %l:%M%p" )
}

changelog_divider() {
  echo "+=========================================================+"
}

changelog_footer() {
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

# Changelog individual lines must escape newlines to be able to loop over string array
escape_newlines() {
  local newline_escape="<#new_line#>"
  local newline=$'\n'
  echo "${1//$newline/$newline_escape}"
}

unescape_newlines() {
  local newline_escape="<#new_line#>"
  local newline=$'\n'
  echo "${1//$newline_escape/$newline}"
}

get_changelog_text_for_commits() {
  #Pass in commits array of SHA's
  #Return formatted changelog text with default or custom format
  #Optional first argument for the format "--format=%H"
  local commit_shas=($@)
  local log_format="--format=%s"
  local log_format_matcher="\-\-format\="

  #Capture line by line output with default or custom log format
  for i in "${!commit_shas[@]}"; do
    # Optional - First argument
    #   - --format=something (custom display log format)
    if [[ "${i}" = '0' ]]; then
      if echo "${commit_shas[$i]}" | grep -q "${log_format_matcher}"; then
        log_format="${commit_shas[$i]}";
        continue;
      fi;
    fi;

    local raw_log_line=`git show -s ${log_format} ${commit_shas[$i]}`
    local escaped_log_line=$(escape_newlines "$raw_log_line")
    echo "$escaped_log_line"
  done;
}

get_github_repo_origin_url() {
  # Capture remote
  local remote_origin_url=$(git config --get remote.origin.url)

  if [[ "$remote_origin_url" = '' ]]; then
    echo "Error : Unable to determine the remote origin."
    echo "      : Set origin url with 'git remote set-url origin git://new.url.here'"
    exit 1
  fi

  local repo_regex="^(https?:\/\/|git:\/\/|git\@)?github\.com[:/]([^.]*)(.git)?$"
  if [[ $remote_origin_url =~ $repo_regex ]]; then
    local github_repo_url="https://github.com/${BASH_REMATCH[2]}"
    echo "$github_repo_url"
  else
    echo "Error : Unable to determine the remote repo url with format: '${remote_origin_url}'."
    exit 1
  fi
}

# Loop over a list of commit shas and same ordered list of changelog formatted lines,
# add a github url prefix to the line
set_github_url_suffix_to_changelog_lines() {
  local commit_shas=($1)
  IFS=$'\n' read -rd '' -a changelog_lines <<<"$2"
  local url_type="$3"

  # Check to see if the commit message has a matching pull request
   # local unformatted_commit="`git show -s ${commit_shas[$i]}`"
   # pr_regex="Merge pull request #([0-9]+)"
   # if [[ $unformatted_commit =~ $pr_regex ]]; then
   #   local pr_url="${repo}/pull/${BASH_REMATCH[1]} - "
   # fi

  case "$url_type" in
    ':commit_url' | 'commit_url' )
      # Simple url for exact commit
      #commit_filter=''
      ;;
    ':pull_url' | 'pull_url' )
      # Pull request url

      #Filter by merged pull requests only
      #commit_filter=$'^Merge pull request #.* from .*';
      #changelog_format="--format=%b"
      ;; #use body of pull requests
    * )
      echo "Error : Url type required. Please specify :commit_url or :pull_url."
      exit 1;;
  esac

  # Capture remote
  local github_repo_url=$(get_github_repo_origin_url)

  # populate an array from that variable, as delimited by the IFS
  #local changelog_lines=($2)

  for sha_line_number in "${!commit_shas[@]}"; do
    #while read -r changelog_line; do

    #for line_number in "${!changelog_lines[@]}"; do
      local commit_sha="${commit_shas[$sha_line_number]}"
      local changelog_line="${changelog_lines[$sha_line_number]}"

      echo "$commit_sha::$changelog_line::$remote_origin_url"
    #done;
    #done <<< "$2"

  done;

}

group_and_sort_changelog_lines() {
  local previous_shopt_extglob=$(shopt -p extglob)
  local existing_shopt_nocasematch=$(shopt -p nocasematch)
  shopt -s nocasematch
  shopt -s extglob

  local feature_tag_lines=""
  local bug_tag_lines=""
  local security_tag_lines=""
  local general_release_lines=""

  local newline=$'\n'

  while read -r line; do
    local tag_regex="^\s*\[(features?|bugs?|security)\]\s*(.*)\s*$"
    if [[ $line =~ $tag_regex ]]; then
      #Tagged entry
      local full_tag=$BASH_REMATCH
      local tag_type="${BASH_REMATCH[1]}"
      #Remove leading spaces (regex in bash capturing always)
      local tag_content="${BASH_REMATCH[2]##*( )}"
      #Add leading 2 spaces with bullet point for tagged line prefix & remove trailing spaces
      tag_content="  ${tag_content%%*( )}${newline}"

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
      #Normal non-tagged entry
      general_release_lines+="${line}${newline}"
    fi;
  done <<< "$1";

  # Print out tagged content in order
  if [[ $feature_tag_lines != '' ]]; then
    echo "Features:
${feature_tag_lines}"
  fi;
  if [[ $security_tag_lines != '' ]]; then
    echo "Security:
${security_tag_lines}"
  fi;
  if [[ $bug_tag_lines != '' ]]; then
    echo "Bugs:
${bug_tag_lines}"
  fi;
  echo "$general_release_lines${newline}"

  #Return previous setup for bash
  eval $previous_shopt_extglob
  eval $existing_shopt_nocasematch
}

#generate_changelog_content "$last_tag_name" "$next_tag_name" ":all/:pulls_only"
generate_changelog_content() {
  local release_name="$1"
  local commit_filter="$2"         #all_commits or pulls_only
  local starting_point="$3"        #optional
  local end_point="$4"             #optional
  local changelog_format="--format=%s" #default -> display title

  if [[ "$release_name" = "" ]]; then
    echo "Error : Release name required for changelog generation."
    exit 1;
  fi;

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

  local escaped_commit_lines=$(get_changelog_text_for_commits "$changelog_format" "$commits")

  # if the append url option set in method
  #local escaped_commit_lines=$(set_github_url_suffix_to_changelog_lines "$commits" "$escaped_commit_lines" ":pull_url")
  local grouped_commit_output=$(group_and_sort_changelog_lines "$escaped_commit_lines")

  local unescaped_content=$(unescape_newlines "$grouped_commit_output")

  local release_date=$(get_current_release_date)

  echo "$(changelog_divider)
|| Release: ${release_name}
|| Released on ${release_date}
$(changelog_divider)

${unescaped_content}

$(changelog_divider)"
}

#generate_version_file "$version_number" "$optional_file_name"
generate_version_file(){
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
generate_changelog_file(){
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
      #Overwrite;
      echo "$changelog_content
$(changelog_footer)" > $changelog_file;;
    ':append' | 'append' )
      if [[ ! -f $changelog_file ]]; then
        #Initialise new file
        touch $changelog_file;
        echo "$changelog_content
$(changelog_footer)" > $changelog_file
      else
        #Append to start of file
        local existing_content=$(cat $changelog_file);

        echo "$changelog_content
$existing_content" > $changelog_file;
      fi;;
    * )
      echo "Error : Generate strategy required. Please specify :overwrite or :append."
      exit 1;;
  esac
}
