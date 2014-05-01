#!/bin/bash -e

. ./test/test_helper.sh
. ./support/git-functions.sh
. ./support/changelog-functions.sh

describe "git-release - unit - changelog"

after() {
  if [[ $MAINTAIN_SANDBOX != true ]]; then
    remove_sandbox
  fi;
}

#escape_newlines

it_uses_escape_newlines_to_replace_all_newlines_in_single_line_string(){
  local commit_message="Some single line"

  output=$(escape_newlines "$commit_message")

  test "$output" = "${commit_message}"
}

it_uses_escape_newlines_to_replace_all_newlines_in_multiline_string(){
  local commit_message="Some line with
with values
across multiple lines
and trailing
"

  output=$(escape_newlines "$commit_message")

  test "$output" = "Some line with<#new_line#>with values<#new_line#>across multiple lines<#new_line#>and trailing<#new_line#>"
}

#unescape_newlines

it_uses_unescape_newlines_to_replace_all_wildcards_in_string_with_no_wildcards(){
  local commit_message="Unescaped single line"

  output=$(unescape_newlines "$commit_message")

  test "$output" = "${commit_message}"
}

it_uses_unescape_newlines_to_replace_all_wildcards_in_string_with_newlines_when_multiple_exist(){
  local commit_message="Some line with<#new_line#>with values<#new_line#>across multiple lines<#new_line#>and trailing<#new_line#>"

  output=$(unescape_newlines "$commit_message")

  test "$output" = "Some line with
with values
across multiple lines
and trailing"
}

#set_github_url_suffix_to_changelog_lines

it_uses_set_github_url_suffix_to_changelog_lines_and_raises_error_with_incorrect_url_type() {
  should_fail $(set_github_url_suffix_to_changelog_lines "12345" "any message" ":unknown_url_format")

  local output=$(set_github_url_suffix_to_changelog_lines "12345" "any message" ":unknown_url_format" 2>&1 | tail -n 1)
  local expected_error="Error : Url type required. Please specify :commit_urls or :pull_urls."

  test $(search_substring "$output" "$expected_error") = 'found'
}

it_uses_set_github_url_suffix_to_changelog_lines_and_appends_commit_urls() {
  local tags=(
    'normal-tag/2.0.0'
    'normal-tag/3.0.0'
    'normal-tag/4.0.0'
  )
  local commit_messages=(
    "commit message for 2.0.0"
    "[Any Old] Message for 3.0.0"
    "[Feature] Rails upgrade to 4.0.0"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local commit_sha_list=$(get_commits_between_points "normal-tag/2.0.0" "normal-tag/4.0.0")

  local commit_shas=($commit_sha_list)
  local commit_message_list=$(IFS=$'\n'; echo "${commit_messages[*]}")

  local output=$(set_github_url_suffix_to_changelog_lines "$commit_sha_list" "$commit_message_list" ":commit_urls")

  test "$output" = "commit message for 2.0.0 - https://github.com/organisation/repo-name/commit/${commit_shas[0]}
[Any Old] Message for 3.0.0 - https://github.com/organisation/repo-name/commit/${commit_shas[1]}
[Feature] Rails upgrade to 4.0.0 - https://github.com/organisation/repo-name/commit/${commit_shas[2]}"
}

it_uses_set_github_url_suffix_to_changelog_lines_and_appends_pull_urls() {
   local tags=(
    'tag_with_pulls/2.0.0'
    'tag_with_pulls/3.0.0'
    'tag_with_pulls/4.0.0'
  )
  local commit_messages=(
    "Merge pull request #722 from SomeOrg/feature/running-balance-field

[Features] This is a pull request merging a feature across multiple
lines and continuing"
    "Merge pull request #714 from SomeOrg/fix-login

Fixing the login but no tag displayed."
    "Merge pull request #685 from SomeOrg/bug/modal-new-login

[Security] Commit fixing the modal with security flaw"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local commit_sha_list=$(get_commits_between_points "tag_with_pulls/2.0.0" "tag_with_pulls/4.0.0")
  # Capture changelog text in same manner as core
  local commit_message_list=$(get_changelog_text_for_commits "--format=%b" "$commit_sha_list")

  local output=$(set_github_url_suffix_to_changelog_lines "$commit_sha_list" "$commit_message_list" ":pull_urls")

  test "$output" = "[Security] Commit fixing the modal with security flaw - https://github.com/organisation/repo-name/pull/685
Fixing the login but no tag displayed. - https://github.com/organisation/repo-name/pull/714
[Features] This is a pull request merging a feature across multiple<#new_line#>lines and continuing - https://github.com/organisation/repo-name/pull/722"
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

#group_and_sort_changelog_lines

it_uses_group_and_sort_changelog_lines_to_return_titles_grouped_by_tags() {
  local commit_messages="Start of the project
    [bugs]Argh, I fixed a bug here
    [feature] OMG. I had time to write something of use
    [features]Its so exciting writing useful things!!
    [bug] What comes up, must come down
    Some random tweak fix"

  output=$(group_and_sort_changelog_lines "$commit_messages")

  test "$output" = "Features:
  OMG. I had time to write something of use
  Its so exciting writing useful things!!

Bugs:
  Argh, I fixed a bug here
  What comes up, must come down

Start of the project
Some random tweak fix"
}

it_uses_group_and_sort_changelog_lines_to_return_titles_grouped_by_tags_case_insensitive() {
  local commit_messages="[Bug] Start of the project
    [BUGS]   Argh, I fixed a bug here
    [fEaTuRes]     OMG. I had time to write something of use"

  output=$(group_and_sort_changelog_lines "$commit_messages")

  test "$output" = "Features:
  OMG. I had time to write something of use

Bugs:
  Start of the project
  Argh, I fixed a bug here"
}

it_uses_group_and_sort_changelog_lines_to_return_titles_grouped_by_tags_with_multiple_brackets() {
  local commit_messages="[BUGS] [QC Some Reference][More Custom References] Fixed the tagged bugs
    [fEaTuRes][Additonal Tag one] Another referenced feature"

  output=$(group_and_sort_changelog_lines "$commit_messages")

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

  should_succeed $(generate_changelog_content 'AnyOldReleaseName' ':all_commits' ':no_urls')
  should_succeed $(generate_changelog_content 'AnyOldReleaseName' ':pulls_only' ':no_urls')
}

it_uses_generate_changelog_content_to_exit_with_errors_with_invalid_url_preference() {
  generate_git_repo

  should_fail $(generate_changelog_content 'AnyOldReleaseName' ':all_commits')
  should_fail $(generate_changelog_content 'AnyOldReleaseName' ':all_commits' '')
  should_fail $(generate_changelog_content 'AnyOldReleaseName' ':all_commits' ':unknown')

  should_succeed $(generate_changelog_content 'AnyOldReleaseName' ':all_commits' ':no_urls')
  should_succeed $(generate_changelog_content 'AnyOldReleaseName' ':all_commits' ':with_urls')
}

it_uses_generate_changelog_content_to_succeed_without_a_startpoint() {
  generate_git_repo

  should_succeed $(generate_changelog_content 'v0.0.5' ':all_commits' ':no_urls' '' 'releases/end/v02.34')
}

it_uses_generate_changelog_content_to_succeed_without_an_endpoint() {
  generate_git_repo

  should_succeed $(generate_changelog_content 'v0.0.5' ':all_commits' ':no_urls' 'release/v1.0.45')
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
  local output=$(generate_changelog_content "$custom_release_name" ':all_commits' ':no_urls')

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
  local output=$(generate_changelog_content "$custom_release_name" ':all_commits' ':no_urls' 'release/v1.0.5' 'random_tag_2')

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
    "Merge pull request #705 from SomeOrg/bug/change-field-length

[BUG] Login field length"
    " This commit is not a pull request and should be ignored"
    "Merge pull request #722 from SomeOrg/feature/login-firefox-fix (Bill Hoskings, 18 hours ago)

[Features] This is a pull request merging a feature across multiple
lines and continuing"
    " Yet another commit,that isn't a pull request"
    "Merge pull request #714 from SomeOrg/fix-login-on-opera

Fixing the login but no tag displayed."
    "Merge pull request #685 from SomeOrg/bug/modal-new-login

[Security] Commit fixing the modal with security flaw"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local custom_release_name="v2.0.5"
  local output=$(generate_changelog_content "$custom_release_name" ':pulls_only' ':no_urls')

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
  Login field length

Fixing the login but no tag displayed.

$(changelog_divider)"
}

it_uses_generate_changelog_content_to_list_pull_requests_with_urls(){
  local tags=(
    'tag_with_pulls_1'
    'tag_with_pulls_2'
  )
  local commit_messages=(
    "Merge pull request #705 from SomeOrg/bug/change-field-length

[BUG] Login field length"
    "Merge pull request #722 from SomeOrg/feature/login-firefox-fix

[Features] This is yet another pull request"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local custom_release_name="v2.0.5"
  local output=$(generate_changelog_content "$custom_release_name" ':pulls_only' ':with_urls')

  test "$output" = "$(changelog_divider)
|| Release: ${custom_release_name}
|| Released on $(get_current_release_date)
$(changelog_divider)

Features:
  This is yet another pull request - https://github.com/organisation/repo-name/pull/722

Bugs:
  Login field length - https://github.com/organisation/repo-name/pull/705

$(changelog_divider)"
}

it_uses_generate_changelog_content_to_list_commits_with_urls(){
  local tags=(
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    '[Any Old] Message for 1.0.5'
    'latest release to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local commit_sha_list=$(get_commits_between_points "release/v1.0.5" "release/v1.0.6")
  local commit_shas=($commit_sha_list)

  local custom_release_name="v1.0.7"
  local output=$(generate_changelog_content "$custom_release_name" ':all_commits' ':with_urls')

  test "$output" = "$(changelog_divider)
|| Release: ${custom_release_name}
|| Released on $(get_current_release_date)
$(changelog_divider)

${commit_messages[1]} - https://github.com/organisation/repo-name/commit/${commit_shas[0]}
${commit_messages[0]} - https://github.com/organisation/repo-name/commit/${commit_shas[1]}
$(get_commit_message_for_first_commit) - https://github.com/organisation/repo-name/commit/$(get_sha_for_first_commit)

$(changelog_divider)"
}

#generate_version_file

it_uses_generate_version_file_to_fail_with_no_version_number_passed() {
  should_fail $(generate_version_file)
}

it_uses_generate_version_file_to_create_a_version_file() {
  enter_sandbox

  file_should_not_exist "VERSION"

  generate_version_file 'v12.03.23'

  file_should_exist "VERSION"

  test "$(cat VERSION)" = "v12.03.23"
}

it_uses_generate_version_file_to_create_a_custom_version_file() {
  enter_sandbox

  file_should_not_exist "CUSTOM_VERSION"

  generate_version_file 'v12.03.23' 'CUSTOM_VERSION'

  file_should_exist "CUSTOM_VERSION"

  test "`cat CUSTOM_VERSION`" = "v12.03.23"
}

it_uses_generate_version_file_to_replace_any_existing_version_file() {
  enter_sandbox

  file_should_not_exist "VERSION"

  generate_version_file 'v12.03.23'

  file_should_exist "VERSION"

  test "`cat VERSION`" = "v12.03.23"

  generate_version_file 'v14.05.25'

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

  test "$(cat CHANGELOG)" = "$content
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

  generate_changelog_file 'Updated Content' ':overwrite'

  test "`cat CHANGELOG`" = "Updated Content
$(changelog_footer)"
}

it_uses_generate_changelog_file_to_append_to_any_existing_file_with_append_strategy() {
  enter_sandbox

  file_should_not_exist "CHANGELOG"

  generate_changelog_file 'Original Content' ':append'

  file_should_exist "CHANGELOG"

  test "`cat CHANGELOG`" = "Original Content
$(changelog_footer)"

  generate_changelog_file 'Updated Content' ':append'

  test "`cat CHANGELOG`" = "Updated Content
Original Content
$(changelog_footer)"
}

# open_changelog_for_edit

it_uses_open_changelog_for_edit_to_open_specific_changelog_file() {
  stub _open_editor

  # Ensure editor variable is set
  EDITOR=${EDITOR:-"vim"}

  local changelog_file="SOME_CHANGELOG_FILE"
  local output=$(open_changelog_for_edit "$changelog_file"; stub_last_called_with)
  local stub_output=$(echo "$output" | tail -n 1)

  unstub _open_editor

  test "$stub_output" = "Stub: _open_editor. Received: SOME_CHANGELOG_FILE"
}

it_uses_open_changelog_for_edit_to_raise_an_error_with_no_changelog_file_set() {
  should_fail $(open_changelog_for_edit)

  local output=$(open_changelog_for_edit 2>&1 | tail -n 2)
  local expected_error="Error : Changelog file location must be set."

  test $(search_substring "$output" "$expected_error") = 'found'
}

it_uses_open_changelog_for_edit_to_skip_sending_changelog_file_when_no_editor_set() {
  local original_editor="$EDITOR"
  unset EDITOR

  should_succeed $(open_changelog_for_edit 'CHANGELOG')
  local output=$(open_changelog_for_edit 'CHANGELOG' 2>&1 | tail -n 1)

  EDITOR="$original_editor"

  test "$output" = ">> Editor not present. Set '\$EDITOR' for any inline changelog changes."
}

it_uses_open_changelog_for_edit_by_passing_changelog_file_to_editor() {
  stub_script_variable EDITOR

  local changelog_file="NEW_CHANGELOG_FILE"
  open_changelog_for_edit "$changelog_file"
  local stub_output=$(stubbed_script_variable_last_called_with)

  unstub_script_variable

  test "$stub_output" = "stub: \$EDITOR. Received: Arg 1: NEW_CHANGELOG_FILE."
}


