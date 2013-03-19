#!/usr/bin/env roundup
source ./spec/scripts/script_spec_helper.sh
source ./script/support/releaseable.sh

describe "releaseable - unit"

after() {
  if [[ $MAINTAIN_SANDBOX != true ]]; then
    remove_sandbox
  fi;
}
#validate_inputs()

it_fails_on_validate_inputs_with_no_version_type() {
  should_fail "$(validate_version_type)"
}

it_fails_on_validate_inputs_with_invalid_version_type() {
  should_fail "$(validate_version_type "invalid_type")"
}

it_passes_on_validate_inputs_with_major_version_type() {
  should_succeed $(validate_version_type "major")
}

it_passes_on_validate_inputs_with_minor_version_type() {
  should_succeed $(validate_version_type "minor")
}

it_passes_on_validate_inputs_with_patch_version_type() {
  should_succeed $(validate_version_type "patch")
}


#ensure_git_directory()

it_fails_on_ensure_git_directory_with_no_git() {
  enter_sandbox
  rm -rf .git

  should_fail "$(ensure_git_directory)"
}

it_passes_on_ensure_git_directory_with_git_directory() {
  enter_sandbox
  mkdir -p .git

  should_succeed $(ensure_git_directory)
}

#versioning_prefix()

it_uses_versioning_prefix_to_generate_concatenated_prefix() {
   output=$(versioning_prefix SomEthing VER)
   test "$output" = "SomEthing/VER"
}

it_uses_versioning_prefix_to_generate_singular_prefix() {
  output=$(versioning_prefix MY-RELEASES)
  test "$output" = "MY-RELEASES"
}

#get_release_tags()

it_uses_get_release_tags_to_return_all_tags_with_no_pattern_ordered_by_alpha() {
  generate_sandbox_tags

  output=$(get_release_tags)
  test "$output" = "random_tag_1
random_tag_2
random_tag_3
release/production/v1.0.9
release/production/v3.0.9
release/production/v3.1.9
release/staging/v1.0.2
release/staging/v2.0.3
release/v1.0.5
release/v1.0.6"
}

it_uses_get_release_tags_to_return_tags_matching_a_given_pattern() {
  generate_sandbox_tags

  output=$(get_release_tags random)
  test "$output" = "random_tag_1
random_tag_2
random_tag_3"

  output=$(get_release_tags release/production)
  test "$output" = "release/production/v1.0.9
release/production/v3.0.9
release/production/v3.1.9"
}

#get_last_tag_name()

it_uses_get_last_tag_name_to_find_the_last_tag_scoped_by_pattern() {
  generate_sandbox_tags

  output=$(get_last_tag_name "release/production/v")
  test "$output" = "release/production/v3.1.9"
}

it_uses_get_last_tag_name_to_return_nothing_with_no_tags() {
  output=$(get_last_tag_name "no/existing/tags")
  test "$output" = ""
}

it_uses_get_last_tag_name_to_return_nothing_with_no_matches() {
  generate_sandbox_tags

  output=$(get_last_tag_name "no/matches/atall")
  test "$output" = ""
}

#get_next_tag_name()

it_uses_get_next_tag_name_to_error_on_missing_version_type() {
  should_fail $(get_next_tag_name)
}

it_uses_get_next_tag_name_to_error_with_an_invalid_last_tag_name() {
  should_fail $(get_next_tag_name major releases invalidx.x.x)
  should_fail $(get_next_tag_name major '' invalid1.0)
  should_fail $(get_next_tag_name major '' invalid0)
}

it_uses_get_next_tag_name_to_succeed_with_an_empty_version_prefix() {
  should_succeed $(get_next_tag_name major '')
}

it_uses_get_next_tag_name_to_succeed_with_a_custom_version_prefix() {
  should_succeed $(get_next_tag_name major releases/production/v)
}

it_uses_get_next_tag_name_to_succeed_with_no_existing_tags() {
  should_succeed $(get_next_tag_name major releases/production/v 1.0.40)
}

it_uses_get_next_tag_name_to_succeed_with_no_matching_tags() {
  generate_sandbox_tags

  output=$(get_next_tag_name major releases/nomatches/v 1.0.40)
  test $output = "releases/nomatches/v2.0.40"
}

it_uses_get_next_tag_name_to_succeed_incrementing_with_no_last_version() {
  output=$(get_next_tag_name major release/no_prev_version/v)
  test $output = "release/no_prev_version/v1.0.0"
}

it_uses_get_next_tag_name_to_succeed_incrementing_with_found_last_version() {
  generate_sandbox_tags

  #Last tag : release/production/v3.1.9
  output=$(get_next_tag_name minor release/production/v)
  test $output = "release/production/v3.2.9"
}

it_uses_get_next_tag_name_to_succeed_incrementing_each_type() {
  generate_sandbox_tags

  #Last tag : release/production/v3.1.9
  output=$(get_next_tag_name major release/production/v)
  test $output = "release/production/v4.1.9"

  #Last tag : release/staging/v2.0.3
  output=$(get_next_tag_name minor release/staging/v)
  test $output = "release/staging/v2.1.3"

  #Last tag : release/v1.0.6
  output=$(get_next_tag_name patch release/v)
  test $output = "release/v1.0.7"
}

#get_commits_between_points

it_uses_get_commits_between_points_to_raise_an_error_with_nothing_passed() {
  enter_sandbox
  should_fail $(get_commits_between_points)
}

it_uses_get_commits_between_points_to_raise_an_error_with_no_end_point() {
  enter_sandbox
  local output=""
  should_fail output=$(get_commits_between_points 'somestartpoint')
}

it_uses_get_commits_between_points_to_get_nothing_when_no_commits_exists() {
  generate_git_repo
  should_succeed $(get_commits_between_points 'anyTagName' 'anotherTagName')
}

it_uses_get_commits_between_points_to_return_commits_with_no_start_point() {
  generate_sandbox_tags

  local start_point=""
  local end_point="release/v1.0.6"
  output=$(get_commits_between_points "$start_point" "$end_point")

  #Ordered by creation date
  local target_tag_sha=$(get_sha_for_tag_name 'release/v1.0.6')
  local older_sha_1=$(get_sha_for_tag_name 'random_tag_2')
  local older_sha_2=$(get_sha_for_tag_name 'release/v1.0.5')
  local older_sha_3=$(get_sha_for_tag_name 'random_tag_1')
  local initial_commit=$(get_sha_for_first_commit)

  test "$output" = "$target_tag_sha
$older_sha_1
$older_sha_2
$older_sha_3
$initial_commit"
}

it_uses_get_commits_between_points_to_return_all_commits_between_points_with_filter() {
  generate_sandbox_tags

  local start_point="release/production/v1.0.9"
  local end_point="release/production/v3.0.9"

  local commit_message=$(get_commit_message_for_latest_commit 'release/production/v3.0.9')
  local target_tag_sha=$(get_sha_for_tag_name 'release/production/v3.0.9')

  output=$(get_commits_between_points "$start_point" "$end_point" "$commit_message")

  test "$output" = "$target_tag_sha"
}

it_uses_get_commits_between_points_to_return_all_commits_with_no_start_point_with_filter() {
  generate_sandbox_tags

  local start_point=""
  local end_point="release/production/v3.0.9"

  local commit_message=$(get_commit_message_for_latest_commit 'release/production/v3.1.9')
  local target_tag_sha=$(get_sha_for_tag_name 'release/production/v3.1.9')

  output=$(get_commits_between_points "$start_point" "$end_point" "$commit_message")

  test "$output" = "$target_tag_sha"
}

it_uses_get_commits_between_points_to_return_all_commits_between_points() {
  generate_sandbox_tags

  local start_point="release/v1.0.5"
  local end_point="release/v1.0.6"
  output=$(get_commits_between_points "$start_point" "$end_point")

  #Ordered by creation date
  local target_tag_sha=$(get_sha_for_tag_name 'release/v1.0.6')
  local older_sha_1=$(get_sha_for_tag_name 'random_tag_2')
  local older_sha_2=$(get_sha_for_tag_name 'release/v1.0.5')

  test "$output" = "$target_tag_sha
$older_sha_1
$older_sha_2"
}


#generate_changelog

it_uses_generate_changelog_to_exit_with_errors_without_endpoint() {
  enter_sandbox

  should_fail $(generate_changelog)
  should_fail $(generate_changelog 'anything')
}

it_uses_generate_changelog_to_succeed_without_a_startpoint() {
  enter_sandbox

  should_succeed $(generate_changelog '' 'anything')
}

it_uses_generate_changelog_to_create_a_custom_changelog_file() {
  enter_sandbox

  file_should_not_exist "MYCHANGELOG"

  output=$(generate_changelog 'anything' 'anything' 'MYCHANGELOG')

  file_should_exist "MYCHANGELOG"
}

it_uses_generate_changelog_to_create_a_default_changelog_file() {
  enter_sandbox

  file_should_not_exist "CHANGELOG"

  output=$(generate_changelog 'anything' 'anything')

  file_should_exist "CHANGELOG"
}

# MAINTAIN_SANDBOX=true
# it_uses_generate_changelog_to_create_a_changelog_file_with_commit_messages(){
#   generate_sandbox_tags
#   file_should_not_exist "CHANGELOG"

#   local start_point="release/v1.0.5"
#   local end_point="release/v1.0.6"

#   local output=$(generate_changelog "$start_point" "$end_point")
#   local contents=`cat CHANGELOG`

#   file_should_exist "CHANGELOG"
#   test "$contents" = "$(changelog_header)
# || Generated on $(date)
# $(changelog_divider)"

# #   #Ordered by creation date
# #   local target_tag_sha=$(get_sha_for_tag_name 'release/v1.0.6')
# #   local older_sha_1=$(get_sha_for_tag_name 'random_tag_2')
# #   local older_sha_2=$(get_sha_for_tag_name 'release/v1.0.5')

# #   test "$output" = "$target_tag_sha
# # $older_sha_1
# # $older_sha_2"
# }

# it_uses_generate_changelog_create_create_a_changelog_file_scoped_to_pull_requests(){

# }

it_uses_get_changelog_text_for_commits_to_return_titles_by_default() {
  generate_sandbox_tags

  local start_point="release/v1.0.5"
  local end_point="release/v1.0.6"

  local commit_shas=$(get_commits_between_points "$start_point" "$end_point")

  local commit_message_1=$(get_commit_message_for_latest_commit 'release/v1.0.6')
  local commit_message_2=$(get_commit_message_for_latest_commit 'random_tag_2')
  local commit_message_3=$(get_commit_message_for_latest_commit 'release/v1.0.5')

  output=$(get_changelog_text_for_commits "$commit_shas")


  test "$output" = "${commit_message_1}
${commit_message_2}
${commit_message_3}"
}

it_uses_get_changelog_text_for_commits_to_return_titles_with_a_custom_format() {
  generate_sandbox_tags

  local start_point="release/v1.0.5"
  local end_point="release/v1.0.6"

  local commit_shas=$(get_commits_between_points "$start_point" "$end_point")

  local commit_message_1=$(get_commit_message_for_latest_commit 'release/v1.0.6')
  local commit_message_2=$(get_commit_message_for_latest_commit 'random_tag_2')
  local commit_message_3=$(get_commit_message_for_latest_commit 'release/v1.0.5')

  output=$(get_changelog_text_for_commits "--format=%H--%s" "$commit_shas")

  local sha_array=($commit_shas)
  test "$output" = "${sha_array[0]}--${commit_message_1}
${sha_array[1]}--${commit_message_2}
${sha_array[2]}--${commit_message_3}"
}

it_uses_get_changelog_text_for_commits_to_return_titles_grouped_by_tags() {
  local tags=(
    "releases/v0.0.3"
    "releases/v0.0.4"
    "releases/v0.1.4"
    "releases/v1.1.4"
    "releases/v1.1.5"
    "releases/v1.1.6"
  )
  local commit_messages=(
    "Start of the project"
    "[bugs]Argh, I fixed a bug here"
    "[feature] OMG. I had time to write something of use"
    "[features]Its so exciting writing useful things!!"
    "[bug] What comes up, must come down"
    "Some random tweak fix"
  )
  generate_sandbox_tags tags[@] commit_messages[@]

  local start_point="releases/v0.0.3"
  local end_point="releases/v1.1.6"

  local commit_shas=$(get_commits_between_points "$start_point" "$end_point")

  output=$(get_changelog_text_for_commits "$commit_shas")

  local sha_array=($commit_shas)
  test "$output" = "Features:
  Its so exciting writing useful things!!
  OMG. I had time to write something of use

Bugs:
  What comes up, must come down
  Argh, I fixed a bug here

Some random tweak fix
Start of the project"
}

it_uses_get_changelog_text_for_commits_to_return_titles_grouped_by_tags_case_insensitive() {
  local tags=(
    "releases/v0.0.3"
    "releases/v1.1.5"
    "releases/v1.1.6"
  )
  local commit_messages=(
    "[Bug] Start of the project"
    "[BUGS]   Argh, I fixed a bug here"
    "[fEaTuRes]     OMG. I had time to write something of use"
  )
  generate_sandbox_tags tags[@] commit_messages[@]

  local start_point="releases/v0.0.3"
  local end_point="releases/v1.1.6"

  local commit_shas=$(get_commits_between_points "$start_point" "$end_point")

  output=$(get_changelog_text_for_commits "$commit_shas")

  local sha_array=($commit_shas)
  test "$output" = "Features:
  OMG. I had time to write something of use

Bugs:
  Argh, I fixed a bug here
  Start of the project"
}

it_uses_get_changelog_text_for_commits_to_return_titles_grouped_by_tags_with_multiple_brackets() {
  local tags=(
    "releases/v0.0.3"
    "releases/v1.1.6"
  )
  local commit_messages=(
    "[BUGS] [QC Some Reference][More Custom References] Fixed the tagged bugs"
    "[fEaTuRes][Additonal Tag one] Another referenced feature"
  )
  generate_sandbox_tags tags[@] commit_messages[@]

  local start_point="releases/v0.0.3"
  local end_point="releases/v1.1.6"

  local commit_shas=$(get_commits_between_points "$start_point" "$end_point")

  output=$(get_changelog_text_for_commits "$commit_shas")

  test "$output" = "Features:
  [Additonal Tag one] Another referenced feature

Bugs:
  [QC Some Reference][More Custom References] Fixed the tagged bugs"
}

