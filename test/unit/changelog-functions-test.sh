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

#get_github_repo_origin_url

it_uses_get_github_repo_origin_url_and_raises_error_with_no_remote_origin() {
  generate_git_repo

  should_fail $(get_github_repo_origin_url)

  local output=$(get_github_repo_origin_url 2>&1)
  local expected_error="Error : Unable to determine the remote origin."

  test $(search_substring "$output" "$expected_error") = 'found'
}

it_uses_get_github_repo_origin_url_with_git_remote() {
  generate_git_repo
  git remote add origin git@github.com:tommeier/git-release.git

  local output=$(get_github_repo_origin_url)

  test "$output" = "https://github.com/tommeier/git-release"
}

it_uses_get_github_repo_origin_url_with_http_remote() {
  generate_git_repo
  git remote add origin http://github.com/tommeier/git-release.git

  local output=$(get_github_repo_origin_url)

  test "$output" = "https://github.com/tommeier/git-release"
}

it_uses_get_github_repo_origin_url_with_https_remote() {
  generate_git_repo
  git remote add origin https://github.com/tommeier/git-release.git

  local output=$(get_github_repo_origin_url)

  test "$output" = "https://github.com/tommeier/git-release"
}

it_uses_get_github_repo_origin_url_with_git_remote_with_no_host() {
  generate_git_repo
  git remote add origin github.com/tommeier/git-release.git

  local output=$(get_github_repo_origin_url)

  test "$output" = "https://github.com/tommeier/git-release"
}

it_uses_get_github_repo_origin_url_with_git_remote_with_no_git_suffix() {
  generate_git_repo
  git remote add origin https://github.com/tommeier/git-release

  local output=$(get_github_repo_origin_url)

  test "$output" = "https://github.com/tommeier/git-release"
}

it_uses_get_github_repo_origin_url_and_raises_error_with_invalid_remote_origin() {
  generate_git_repo
  git remote add origin unknown://github.com/tommeier/git-release

  should_fail $(get_github_repo_origin_url)

  local output=$(get_github_repo_origin_url 2>&1)
  local expected_error="Error : Unable to determine the remote repo url with format: 'unknown://github.com/tommeier/git-release'."

  test $(search_substring "$output" "$expected_error") = 'found'
}

#set_github_url_suffix_to_changelog_lines

# it_uses_set_github_url_suffix_to_changelog_lines_and_raises_error_with_incorrect_url_type()
# it_uses_set_github_url_suffix_to_changelog_lines_and_raises_error_with_no_remote_origin()
# it_uses_set_github_url_suffix_to_changelog_lines_and_appends_commit_urls()
# it_uses_set_github_url_suffix_to_changelog_lines_and_appends_pull_request_urls()
# it_uses_set_github_url_suffix_to_changelog_lines_and_appends_urls_with_git_remote()
# it_uses_set_github_url_suffix_to_changelog_lines_and_appends_urls_with_https_remote()

#get_changelog_text_for_commits

it_uses_get_changelog_text_for_commits_to_return_titles_by_default() {
  local tags=(
    'random_tag_1'
    'releases/v1.0.5'
    'random_tag_2'
    'releases/v1.0.6'
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

  local commit_shas=$(get_commits_between_points "releases/v1.0.5" "releases/v1.0.6")

  output=$(get_changelog_text_for_commits "$commit_shas")

  test "$output" = "${commit_message_1}
${commit_message_2}
${commit_message_3}"
}

it_uses_get_changelog_text_for_commits_to_return_titles_with_a_custom_format() {
  local tags=(
    'random_tag_1'
    'releases/v1.0.5'
    'random_tag_2'
    'releases/v1.0.6'
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

  local commit_shas=$(get_commits_between_points "releases/v1.0.5" "releases/v1.0.6")
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
    'releases/v1.0.5'
    'random_tag_2'
    'releases/v1.0.6'
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
    'releases/v1.0.5'
    'random_tag_2'
    'releases/v1.0.6'
  )
  local commit_messages=(
    'Message For Random Tag 1'
    '[Any Old] Message for 1.0.5'
    'Lots of changes in this commit for random tag 2'
    'latest release to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  local custom_release_name="v1.0.7"
  local output=$(generate_changelog_content "$custom_release_name" ':all_commits' 'releases/v1.0.5' 'random_tag_2')

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
  Login field length

Fixing the login but no tag displayed.

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
