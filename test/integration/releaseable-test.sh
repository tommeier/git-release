#!/bin/bash -e

. ./test/test_helper.sh
. ./support/support-functions.sh

rup() { ./bin/git-release $@; }
sandbox_rup() { /bin/bash ../bin/git-release $@; }

usage_head="++ /bin/bash ../bin/git-release
incorrect versioning type: ''
Please set to one of 'major', 'minor' or 'patch'

usage : git-release $(arg_for $ARG_VERSION '<version>') [$(arg_for $ARG_RELEASE_PREFIX '<prefix>')] [$(arg_for $ARG_START '<start>')] [$(arg_for $ARG_FINISH '<finish>')]"

describe "git-release - integration"

after() {
  if [[ $MAINTAIN_SANDBOX != true ]]; then
    remove_sandbox
  fi;
}

### Failure Cases

it_will_fail_with_no_versioning_type() {
  ! rup
}

it_will_display_help_text_on_fail() {
  generate_git_repo

  local output=$(sandbox_rup 2>&1 | head -n 5 2>&1)
  test "$output" = "$usage_head"
}

it_will_display_error_when_no_git_directory_exists() {
  enter_sandbox

  local output=$(sandbox_rup $(arg_for $ARG_VERSION 'patch') 2>&1 | head -n 2 2>&1)
  local missing_git="Error - Not a git repository please run from the base of your git repo."

  test $(search_substring "$output" "$missing_git") = 'found'
}

it_will_error_if_git_is_in_a_dirty_state() {
  generate_git_repo

  should_succeed $(sandbox_rup $(arg_for $ARG_VERSION 'minor'))

  touch 'FileToMakeGitDirty'

  should_fail $(sandbox_rup $(arg_for $ARG_VERSION 'minor'))

  rm 'FileToMakeGitDirty'

  should_succeed $(sandbox_rup $(arg_for $ARG_VERSION 'minor'))
}

### Success cases

it_will_genereate_a_new_tag_for_next_release() {
  local tags=(
    "release/v1.0.5"
    "release/production/v3.1.9"
  )
  generate_sandbox_tags tags[@]

  should_succeed $(check_tag_exists "release/production/v3.1.9")
  should_fail $(check_tag_exists "release/production/v3.1.10")

  sandbox_rup $(arg_for $ARG_VERSION 'patch') $(arg_for $ARG_RELEASE_PREFIX 'release/production/v')

  should_succeed $(check_tag_exists "release/production/v3.1.10")
}

it_will_genereate_a_new_tag_for_next_release_with_defaults() {
  local tags=(
    "release/v1.0.5"
    "random_tag_2"
    "release/v1.0.6"
  )
  generate_sandbox_tags tags[@]

  should_succeed $(check_tag_exists "release/v1.0.6")
  should_fail $(check_tag_exists "release/v1.1.6")

  sandbox_rup $(arg_for $ARG_VERSION 'minor')

  should_succeed $(check_tag_exists "release/v1.1.6")
}

it_will_genereate_a_new_tag_for_next_release_when_none_exist() {
  generate_git_repo

  should_fail $(check_tag_exists "my-release/yay-1.0.0")
  should_fail $(check_tag_exists "my-release/yay-1.1.0")

  sandbox_rup $(arg_for $ARG_VERSION 'major') $(arg_for $ARG_RELEASE_PREFIX 'my-release/yay-')

  should_succeed $(check_tag_exists "my-release/yay-1.0.0")
  should_fail $(check_tag_exists "my-release/yay-1.1.0")

  sandbox_rup $(arg_for $ARG_VERSION 'minor') $(arg_for $ARG_RELEASE_PREFIX 'my-release/yay-')

  should_succeed $(check_tag_exists "my-release/yay-1.0.0")
  should_succeed $(check_tag_exists "my-release/yay-1.1.0")
}

it_will_generate_files_by_default_from_last_tag_to_head() {
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
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_VERSION 'major') $(arg_for $ARG_RELEASE_PREFIX 'release/v')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 2.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)
latest commit message to 1.0.6
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "2.0.6"
}

it_will_generate_a_changelog_for_a_set_starting_point() {
  local tags=(
    'random_commit_1'
    'release/v1.0.5'
    'random_commit_2'
    'release/v1.0.6'
  )
  local commit_messages=(
    'Message For Random Commit 1'
    '[Any Old] Message for 1.0.5'
    'Lots of changes in this commit for random commit 2'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_VERSION 'patch') $(arg_for $ARG_RELEASE_PREFIX 'release/v') $(arg_for $ARG_START 'release/v1.0.5')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.7
|| Released on $(get_current_release_date)
$(changelog_divider)
latest commit message to 1.0.6
Lots of changes in this commit for random commit 2
[Any Old] Message for 1.0.5
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "1.0.7"
}

it_will_generate_a_changelog_for_a_set_range_with_start_and_end() {
  local tags=(
    'release/v1.0.4'
    'random_commit_1'
    'release/v1.0.5'
    'random_commit_2'
    'release/v1.0.6'
  )
  local commit_messages=(
    'Commit for last released start point 1.0.4'
    'Message For Random Commit 1'
    '[Any Old] Message for 1.0.5'
    'Lots of changes in this commit for random commit 2'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_VERSION 'minor') $(arg_for $ARG_RELEASE_PREFIX 'release/v') $(arg_for $ARG_START 'release/v1.0.5') $(arg_for $ARG_FINISH 'release/v1.0.6')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.1.6
|| Released on $(get_current_release_date)
$(changelog_divider)
latest commit message to 1.0.6
Lots of changes in this commit for random commit 2
[Any Old] Message for 1.0.5
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "1.1.6"
}


it_will_generate_files_with_optional_names() {
  local tags=(
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    '[Any Old] Message for 1.0.5'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_VERSION 'major') $(arg_for $ARG_CHANGELOG 'MYCHANGELOG') $(arg_for $ARG_VERSION_FILE 'VERSION_NUMBER')

  file_should_not_exist "CHANGELOG"
  file_should_not_exist "VERSION"
  file_should_exist "MYCHANGELOG"
  file_should_exist "VERSION_NUMBER"

  test "$(cat MYCHANGELOG)" = "$(changelog_divider)
|| Release: 2.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)
latest commit message to 1.0.6
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION_NUMBER)" = "2.0.6"
}


it_will_generate_a_changelog_file_scoped_to_pull_requests() {
  local tags=(
    'tag_with_pulls/1.0.0'
    'tag_witout_pull'
    'tag_with_pulls/2.0.0'
    'another_tag_without'
    'tag_with_pulls/3.0.0'
    'tag_with_pulls/4.0.0'
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

  sandbox_rup $(arg_for $ARG_VERSION 'minor') $(arg_for $ARG_PULL_REQUESTS)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 0.1.0
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
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "0.1.0"
}

it_will_overwrite_a_changelog_file_by_default() {
  local tags=(
    'release/v1.0.4'
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    'Commit for last released start point 1.0.4'
    '[Any Old] Message for 1.0.5'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_VERSION 'minor') $(arg_for $ARG_START 'release/v1.0.4') $(arg_for $ARG_FINISH 'release/v1.0.5')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.1.6
|| Released on $(get_current_release_date)
$(changelog_divider)
[Any Old] Message for 1.0.5
Commit for last released start point 1.0.4
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "1.1.6"

  sandbox_rup $(arg_for $ARG_VERSION 'major') $(arg_for $ARG_START 'release/v1.0.5') $(arg_for $ARG_FINISH 'release/v1.0.6')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 2.1.6
|| Released on $(get_current_release_date)
$(changelog_divider)
latest commit message to 1.0.6
[Any Old] Message for 1.0.5
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "2.1.6"
}

it_will_append_to_a_changelog_optionally(){
  local tags=(
    'release/v1.0.4'
    'release/v1.0.5'
  )
  local commit_messages=(
    'Commit for last released start point 1.0.4'
    '[Any Old] Message for 1.0.5'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_VERSION 'minor') $(arg_for $ARG_APPEND)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.1.5
|| Released on $(get_current_release_date)
$(changelog_divider)
[Any Old] Message for 1.0.5
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "1.1.5"

  sandbox_rup $(arg_for $ARG_VERSION 'major') $(arg_for $ARG_APPEND)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 2.1.5
|| Released on $(get_current_release_date)
$(changelog_divider)
Release : release/v1.1.5
$(changelog_divider)
$(changelog_divider)
|| Release: 1.1.5
|| Released on $(get_current_release_date)
$(changelog_divider)
[Any Old] Message for 1.0.5
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "2.1.5"
}


it_will_generate_in_an_opinionated_fashion(){
  #using defaults other than append
  generate_git_repo

  sandbox_rup $(arg_for $ARG_VERSION 'minor') $(arg_for $ARG_APPEND)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 0.1.0
|| Released on $(get_current_release_date)
$(changelog_divider)
Initial Commit
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "0.1.0"

  sandbox_rup $(arg_for $ARG_VERSION 'major') $(arg_for $ARG_APPEND)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.1.0
|| Released on $(get_current_release_date)
$(changelog_divider)
Release : release/v0.1.0
$(changelog_divider)
$(changelog_divider)
|| Release: 0.1.0
|| Released on $(get_current_release_date)
$(changelog_divider)
Initial Commit
$(changelog_divider)
$(changelog_footer)"

  test "$(cat VERSION)" = "1.1.0"
}

#TODO
# it_will_optionally_force_push_of_tag()


