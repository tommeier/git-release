#!/bin/bash -e

. ./test/test_helper.sh
. ./support/releaseable.sh

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

#ensure_git_is_clean()

it_fails_on_ensure_git_is_clean_when_dirty(){
  generate_git_repo
  should_succeed $(ensure_git_is_clean)
  touch 'AnyOldFile'
  should_fail $(ensure_git_is_clean)

  test "$(ensure_git_is_clean)" = "Error - Current branch is in a dirty state, please commit your changes first.
# On branch master
# Untracked files:
#   (use \"git add <file>...\" to include in what will be committed)
#
#"$'\t'"AnyOldFile
nothing added to commit but untracked files present (use \"git add\" to track)"
}

it_passes_on_ensure_git_is_clean_when_clean(){
  generate_git_repo

  should_succeed $(ensure_git_is_clean)
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
  local tags=(
    "random_tag_1"
    "random_tag_2"
    "random_tag_3"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
  )
  generate_sandbox_tags tags[@]

  output=$(get_release_tags)
  test "$output" = "random_tag_1
random_tag_2
random_tag_3
release/production/v1.0.9
release/production/v3.0.9"
}

it_uses_get_release_tags_to_return_tags_matching_a_given_pattern() {
  local tags=(
    "random_tag_1"
    "random_tag_2"
    "random_tag_3"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
  )
  generate_sandbox_tags tags[@]

  output=$(get_release_tags random)
  test "$output" = "random_tag_1
random_tag_2
random_tag_3"

  output=$(get_release_tags release/production)
  test "$output" = "release/production/v1.0.9
release/production/v3.0.9"
}

#get_last_tag_name()

it_uses_get_last_tag_name_to_find_the_last_tag_scoped_by_pattern() {
  local tags=(
    "random_tag_1"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
  )
  generate_sandbox_tags tags[@]

  output=$(get_last_tag_name "release/production/v")
  test "$output" = "release/production/v3.0.9"
}

it_uses_get_last_tag_name_to_return_nothing_with_no_tags() {
  output=$(get_last_tag_name "no/existing/tags")
  test "$output" = ""
}

it_uses_get_last_tag_name_to_return_nothing_with_no_matches() {
  local tags=(
    "random_tag_1"
    "release/production/v3.0.9"
  )
  generate_sandbox_tags tags[@]

  output=$(get_last_tag_name "no/matches/atall")
  test "$output" = ""
}

#get_versioning_prefix_from_tag()

it_uses_get_versioning_prefix_from_tag_to_error_on_missing_tag() {
  should_fail $(get_versioning_prefix_from_tag)
}

it_uses_get_versioning_prefix_from_tag_with_an_invalid_tag_name() {
  should_fail $(get_versioning_prefix_from_tag invalidx.x.x)
  should_fail $(get_versioning_prefix_from_tag invalid0.0.x)
  should_fail $(get_versioning_prefix_from_tag invalid1.0)
  should_fail $(get_versioning_prefix_from_tag invalid0)
  should_fail $(get_versioning_prefix_from_tag invalidNoVersionNumber)
}

it_uses_get_versioning_prefix_from_tag_to_succeed_capturing_version_prefix() {
  test "$(get_versioning_prefix_from_tag 'releases/2.1.3')" = "releases/"
  test "$(get_versioning_prefix_from_tag 'r/v/2.1.3')" = "r/v/"
  test "$(get_versioning_prefix_from_tag 'some/old/release/v1.0.40')" = "some/old/release/v"
}

#get_version_number_from_tag()

it_uses_get_version_number_from_tag_to_error_on_missing_tag() {
  should_fail $(get_version_number_from_tag)
}

it_uses_get_version_number_from_tag_to_error_with_an_invalid_tag_name() {
  should_fail $(get_version_number_from_tag invalidx.x.x)
  should_fail $(get_version_number_from_tag invalid1.0)
  should_fail $(get_version_number_from_tag invalid0)
}

it_uses_get_version_number_from_tag_to_succeed_capturing_version_numbers() {
  test "$(get_version_number_from_tag 'releases/v102.29.20')" = "102.29.20"
  test "$(get_version_number_from_tag '1.22.33')" = "1.22.33"
  test "$(get_version_number_from_tag 'Release with Spaces40.50.60')" = "40.50.60"
}

#get_next_version_number_from_tag()

it_uses_get_next_version_number_from_tag_to_error_on_missing_version_type() {
  should_fail $(get_next_version_number_from_tag)
}

it_uses_get_next_version_number_from_tag_to_error_with_an_invalid_last_tag_name() {
  should_fail $(get_next_version_number_from_tag major invalidx.x.x)
  should_fail $(get_next_version_number_from_tag major invalid1.0)
  should_fail $(get_next_version_number_from_tag major invalid0)
}

it_uses_get_next_version_number_from_tag_to_succeed_with_an_empty_version_prefix() {
  should_succeed $(get_next_version_number_from_tag major)
}

it_uses_get_next_version_number_from_tag_to_succeed_with_no_existing_tags() {
  should_succeed $(get_next_version_number_from_tag major v1.0.40)
}

it_uses_get_next_version_number_from_tag_to_succeed_with_no_matching_tags() {
  output=$(get_next_version_number_from_tag major some/old/release/v1.0.40)
  test $output = "2.0.40"
}

it_uses_get_next_version_number_from_tag_to_succeed_incrementing_with_no_last_version() {
  output=$(get_next_version_number_from_tag major)
  test $output = "1.0.0"
}

it_uses_get_next_version_number_from_tag_to_succeed_incrementing_with_found_last_version() {
  output=$(get_next_version_number_from_tag minor release/production/v3.1.9)
  test $output = "3.2.9"
}

it_uses_get_next_version_number_from_tag_to_succeed_incrementing_each_type() {
  output=$(get_next_version_number_from_tag major release/production/v3.1.9)
  test $output = "4.1.9"

  output=$(get_next_version_number_from_tag minor release/staging/v2.0.3)
  test $output = "2.1.3"

  output=$(get_next_version_number_from_tag patch release/v1.0.6)
  test $output = "1.0.7"
}

#get_commits_between_points

it_uses_get_commits_between_points_to_list_all_commits_with_nothing_passed() {
  generate_git_repo

  test "$(get_commits_between_points)" = "$(get_sha_for_first_commit)"
}

it_uses_get_commits_between_points_to_list_all_commits_from_a_start_point() {
  local tags=(
    "random_tag_1"
    "release/v1.0.5"
    "random_tag_2"
    "release/v1.0.6"
    "random_tag_3"
  )
  generate_sandbox_tags tags[@]

  output=$(get_commits_between_points 'random_tag_2')
  test "$output" = "$(get_sha_for_tag_name 'random_tag_3')
$(get_sha_for_tag_name 'release/v1.0.6')
$(get_sha_for_tag_name 'random_tag_2')"
}

it_uses_get_commits_between_points_to_get_nothing_when_no_commits_exists() {
  generate_git_repo

  should_fail $(get_commits_between_points 'anyTagName' 'anotherTagName')
}

it_uses_get_commits_between_points_to_return_commits_with_no_start_point() {
  local tags=(
    "random_tag_1"
    "release/v1.0.5"
    "random_tag_2"
    "release/v1.0.6"
    "random_tag_3"
  )
  generate_sandbox_tags tags[@]

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
  local tags=(
    "random_tag_1"
    "random_tag_2"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
    "release/production/v3.1.9"
    "release/staging/v2.0.3"
  )
  generate_sandbox_tags tags[@]

  local start_point="release/production/v1.0.9"
  local end_point="release/production/v3.0.9"

  local commit_message=$(get_commit_message_for_latest_commit 'release/production/v3.0.9')
  local target_tag_sha=$(get_sha_for_tag_name 'release/production/v3.0.9')

  output=$(get_commits_between_points "$start_point" "$end_point" "$commit_message")

  test "$output" = "$target_tag_sha"
}

it_uses_get_commits_between_points_to_return_all_commits_with_no_start_point_with_filter() {
  local tags=(
    "random_tag_1"
    "random_tag_2"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
    "release/production/v3.1.9"
    "release/staging/v2.0.3"
  )
  generate_sandbox_tags tags[@]

  local start_point=""
  local end_point="release/production/v3.1.9"

  local commit_message=$(get_commit_message_for_latest_commit 'release/production/v3.1.9')
  local target_tag_sha=$(get_sha_for_tag_name 'release/production/v3.1.9')

  output=$(get_commits_between_points "$start_point" "$end_point" "$commit_message")

  test "$output" = "$target_tag_sha"
}

it_uses_get_commits_between_points_to_return_all_commits_between_points() {
  local tags=(
    'random_tag_1'
    'release/v1.0.5'
    'random_tag_2'
    'release/v1.0.6'
  )
  generate_sandbox_tags tags[@]

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

#get_changelog_text_for_commits

it_uses_get_changelog_text_for_commits_to_return_titles_by_default() {
  local tags=(
    'random_tag_1'
    'release/v1.0.5'
    'random_tag_2'
    'release/v1.0.6'
  )

  local commit_message_1="Release 1.0.6"
  local commit_message_2="Random Release 2"
  local commit_message_3="Older Release 1.0.5"

  local commit_messages=(
    "Random Release numero uno"
    "$commit_message_3"
    "$commit_message_2"
    "$commit_message_1"
  )
  generate_sandbox_tags tags[@] commit_messages[@]

  local commit_shas=$(get_commits_between_points "release/v1.0.5" "release/v1.0.6")

  output=$(get_changelog_text_for_commits "$commit_shas")

  test "$output" = "${commit_message_1}
${commit_message_2}
${commit_message_3}"
}

it_uses_get_changelog_text_for_commits_to_return_titles_with_a_custom_format() {
  local tags=(
    'random_tag_1'
    'release/v1.0.5'
    'random_tag_2'
    'release/v1.0.6'
  )

  local commit_message_1="Release 1.0.6"
  local commit_message_2="Random Release 2"
  local commit_message_3="Older Release 1.0.5"

  local commit_messages=(
    "Random Release numero uno"
    "$commit_message_3"
    "$commit_message_2"
    "$commit_message_1"
  )
  generate_sandbox_tags tags[@] commit_messages[@]

  local commit_shas=$(get_commits_between_points "release/v1.0.5" "release/v1.0.6")
  local sha_array=($commit_shas)

  output=$(get_changelog_text_for_commits "--format=%H--%s" "$commit_shas")

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
  local commit_shas=$(get_commits_between_points "${tags[0]}" "${tags[5]}")

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
  local commit_shas=$(get_commits_between_points "${tags[0]}" "${tags[2]}")

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
  local commit_shas=$(get_commits_between_points "${tags[0]}" "${tags[1]}")

  output=$(get_changelog_text_for_commits "$commit_shas")

  test "$output" = "Features:
  [Additonal Tag one] Another referenced feature

Bugs:
  [QC Some Reference][More Custom References] Fixed the tagged bugs"
}

#generate_changelog_content

it_uses_generate_changelog_content_to_exit_with_errors_without_release_name() {
  generate_git_repo

  should_fail $(generate_changelog_content)
  should_fail $(generate_changelog_content '')
}

it_uses_generate_changelog_content_to_exit_with_errors_with_invalid_commit_filter() {
  generate_git_repo

  should_fail $(generate_changelog_content 'AnyOldReleaseName')
  should_fail $(generate_changelog_content 'AnyOldReleaseName' '')
  should_fail $(generate_changelog_content 'AnyOldReleaseName' ':unknown')
  should_fail $(generate_changelog_content 'AnyOldReleaseName' ':anything')

  should_succeed $(generate_changelog_content 'AnyOldReleaseName' ':all_commits')
  should_succeed $(generate_changelog_content 'AnyOldReleaseName' ':pulls_only')
}

it_uses_generate_changelog_content_to_succeed_without_a_startpoint() {
  generate_git_repo

  should_succeed $(generate_changelog_content 'v0.0.5' ':all_commits' '' 'releases/end/v02.34')
}

it_uses_generate_changelog_content_to_succeed_without_an_endpoint() {
  generate_git_repo

  should_succeed $(generate_changelog_content 'v0.0.5' ':all_commits' 'releases/v1.0.45')
}

it_uses_generate_changelog_content_to_generate_with_all_commit_messages(){
  local tags=(
    'random_tag_1'
    'release/v1.0.5'
    'random_tag_2'
    'release/v1.0.6'
  )
  local commit_messages=(
    'Message For Random Tag 1'
    '[Any Old] Message for 1.0.5'
    'Lots of changes in this commit for random tag 2'
    'latest release to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local custom_release_name="v1.0.7"
  local output=$(generate_changelog_content "$custom_release_name" ':all_commits')

  test "$output" = "$(changelog_divider)
|| Release: ${custom_release_name}
|| Released on $(get_current_release_date)
$(changelog_divider)
${commit_messages[3]}
${commit_messages[2]}
${commit_messages[1]}
${commit_messages[0]}
$(get_commit_message_for_first_commit)
$(changelog_divider)"
}

it_uses_generate_changelog_content_to_generate_with_commit_messages_for_a_range(){
  local tags=(
    'random_tag_1'
    'release/v1.0.5'
    'random_tag_2'
    'release/v1.0.6'
  )
  local commit_messages=(
    'Message For Random Tag 1'
    '[Any Old] Message for 1.0.5'
    'Lots of changes in this commit for random tag 2'
    'latest release to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local custom_release_name="v1.0.7"
  local output=$(generate_changelog_content "$custom_release_name" ':all_commits' 'release/v1.0.5' 'random_tag_2')

  test "$output" = "$(changelog_divider)
|| Release: ${custom_release_name}
|| Released on $(get_current_release_date)
$(changelog_divider)
${commit_messages[2]}
${commit_messages[1]}
$(changelog_divider)"
}

it_uses_generate_changelog_content_to_generate_scoped_to_only_pull_requests(){
  local tags=(
    'tag_with_pulls_1'
    'tag_witout_pull'
    'tag_with_pulls_2'
    'another_tag_without'
    'tag_with_pulls_3'
    'tag_with_pulls_4'
  )
  local commit_messages=(
    "Merge pull request #705 from Ferocia/bug/limit-payment-description-length

[BUG] Pay anyone from the accounts screen"
    " This commit is not a pull request and should be ignored"
    "Merge pull request #722 from Ferocia/feature/running-balance-field (Anthony Langhorne, 18 hours ago)

[Features] This is a pull request merging a feature across multiple
lines and continuing"
    " Yet another commit,that isn't a pull request"
    "Merge pull request #714 from Ferocia/fix-customer-login

Fixing the customer login but no tag displayed."
    "Merge pull request #685 from Ferocia/bug/modal-new-payee

[Security] Commit fixing the modal with security flaw"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local custom_release_name="v2.0.5"
  local output=$(generate_changelog_content "$custom_release_name" ':pulls_only')

  test "$output" = "$(changelog_divider)
|| Release: ${custom_release_name}
|| Released on $(get_current_release_date)
$(changelog_divider)
Features:
  This is a pull request merging a feature across multiple
lines and continuing

Security:
  Commit fixing the modal with security flaw

Bugs:
  Pay anyone from the accounts screen

Fixing the customer login but no tag displayed.
$(changelog_divider)"
}

#generate_version_file

it_uses_generate_version_file_to_fail_with_no_version_number_passed() {
  should_fail $(generate_version_file)
}

it_uses_generate_version_file_to_create_a_version_file() {
  enter_sandbox

  file_should_not_exist "VERSION"

  output=$(generate_version_file 'v12.03.23')

  file_should_exist "VERSION"

  local contents=`cat VERSION`
  test "$contents" = "v12.03.23"
}

it_uses_generate_version_file_to_create_a_custom_version_file() {
  enter_sandbox

  file_should_not_exist "CUSTOM_VERSION"

  output=$(generate_version_file 'v12.03.23' 'CUSTOM_VERSION')

  file_should_exist "CUSTOM_VERSION"

  test "`cat CUSTOM_VERSION`" = "v12.03.23"
}

it_uses_generate_version_file_to_replace_any_existing_version_file() {
  enter_sandbox

  file_should_not_exist "VERSION"

  output=$(generate_version_file 'v12.03.23')

  file_should_exist "VERSION"

  test "`cat VERSION`" = "v12.03.23"

  output=$(generate_version_file 'v14.05.25')

  test "`cat VERSION`" = "v14.05.25"
}

#generate_changelog_file

it_uses_generate_changelog_file_to_fail_with_content_passed_or_strategy() {
  enter_sandbox

  should_fail $(generate_changelog_file)
  should_fail $(generate_changelog_file 'some content')
  should_fail $(generate_changelog_file 'some content' '')

  should_succeed $(generate_changelog_file 'some content' ':overwrite')
}

it_uses_generate_changelog_file_to_fail_with_invalid_strategy() {
  enter_sandbox

  should_fail $(generate_changelog_file 'some content' '')
  should_fail $(generate_changelog_file 'some content' ':anything')
  should_fail $(generate_changelog_file 'some content' ':unknown')


  should_succeed $(generate_changelog_file 'some content' ':overwrite')
  should_succeed $(generate_changelog_file 'some content' ':append')
}

it_uses_generate_changelog_file_file_to_create_a_changelog_file() {
  enter_sandbox

  file_should_not_exist "CHANGELOG"

  local content="
My Content
Is Here Across Multiple Lines
"
  local output=$(generate_changelog_file "$content" ':overwrite')

  file_should_exist "CHANGELOG"

  local contents=`cat CHANGELOG`
  test "$contents" = "$content
$(changelog_footer)"
}

it_uses_generate_changelog_file_file_to_create_a_custom_version_file() {
  enter_sandbox

  file_should_not_exist "CHANGELOG"
  file_should_not_exist "CUSTOM_CHANGELOG"

  local content="
My Content
Is Here Across Multiple Lines
"
  output=$(generate_changelog_file "$content" ':overwrite' 'CUSTOM_CHANGELOG')

  file_should_not_exist "CHANGELOG"
  file_should_exist "CUSTOM_CHANGELOG"

  test "`cat CUSTOM_CHANGELOG`" = "$content
$(changelog_footer)"
}

it_uses_generate_changelog_file_to_replace_any_existing_file_with_overwrite_strategy() {
  enter_sandbox

  file_should_not_exist "CHANGELOG"

  output=$(generate_changelog_file 'Original Content' ':overwrite')

  file_should_exist "CHANGELOG"

  test "`cat CHANGELOG`" = "Original Content
$(changelog_footer)"

  output=$(generate_changelog_file 'Updated Content' ':overwrite')

  test "`cat CHANGELOG`" = "Updated Content
$(changelog_footer)"
}

it_uses_generate_changelog_file_to_append_to_any_existing_file_with_append_strategy() {
  enter_sandbox

  file_should_not_exist "CHANGELOG"

  output=$(generate_changelog_file 'Original Content' ':append')

  file_should_exist "CHANGELOG"

  test "`cat CHANGELOG`" = "Original Content
$(changelog_footer)"

  output=$(generate_changelog_file 'Updated Content' ':append')

  test "`cat CHANGELOG`" = "Updated Content
Original Content
$(changelog_footer)"
}



