#!/bin/bash -e

. ./test/test_helper.sh
. ./support/support-functions.sh

rup() { ./bin/git-release-deployed $@; }
sandbox_rup() { /bin/bash ../bin/git-release-deployed $@; }

describe "git-release-deployed - integration"

after() {
  if [[ $MAINTAIN_SANDBOX != true ]]; then
    remove_sandbox
  fi;
}

### Failure Cases

it_will_fail_with_no_deployed_tag() {
  generate_git_repo

  should_fail $(sandbox_rup)
}

it_will_display_help_text_on_fail() {
  generate_git_repo

  # Ignore first "++ /bin/bash ../bin/git-release-deployed" line, as in git >= 1.8.5 it is "++/bin/bash ..."
  local output=$(sandbox_rup 2>&1 | head -n 4 2>&1 | tail -n 3 2>&1)
  test "$output" = "Required parameter: Please enter the deploy tag released.

usage : git-release-deployed $(arg_for $ARG_DEPLOYED_TAG '<deployed_tag>') [$(arg_for $ARG_RELEASE_PREFIX '<prefix>')] [$(arg_for $ARG_START '<start>')] [$(arg_for $ARG_FINISH '<finish>')]"
}

it_will_display_error_when_no_git_directory_exists() {
  enter_sandbox

  local output=$(sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'AnyDeployTag') 2>&1 | head -n 2 2>&1)
  local missing_git="Error - Not a git repository please run from the base of your git repo."

  test $(search_substring "$output" "$missing_git") = 'found'
}

it_will_error_if_git_is_in_a_dirty_state() {
  local tag_name='Myrelease/v1.0.3'
  local tags=("${tag_name}")
  generate_sandbox_tags tags[@]

  should_succeed $(sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "$tag_name"))

  touch 'FileToMakeGitDirty'

  should_fail $(sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "$tag_name"))

  rm 'FileToMakeGitDirty'

  should_succeed $(sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "$tag_name"))
}

it_will_forcibly_replace_existing_deploy_tags() {
  local tag_name="Myrelease/v1.0.3"
  local tags=("${tag_name}")
  generate_sandbox_tags tags[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "$tag_name")

  file_should_exist "CHANGELOG"
  file_should_not_exist "CHANGELOG2"

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "$tag_name") $(arg_for $ARG_CHANGELOG 'CHANGELOG2')

  file_should_not_exist "CHANGELOG"
  file_should_exist "CHANGELOG2"

  #Explicitly checkout the deploy tag in current state
  git checkout -f -B "deployed/Myrelease/v1.0.3"

  file_should_not_exist "CHANGELOG"
  file_should_exist "CHANGELOG2"
}

it_will_error_if_deploy_tag_cannot_be_found(){
  local tag_name='found/v1.0.3'
  local tags=("${tag_name}")
  generate_sandbox_tags tags[@]

  should_succeed $(sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "$tag_name"))
  should_fail $(sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'cannotFindThisTag'))
}

# ### Success cases

it_will_genereate_a_new_deploy_tag_for_each_release() {
  local tags=( "release/production/v3.1.9" )
  generate_sandbox_tags tags[@]

  should_succeed $(check_tag_exists "release/production/v3.1.9")
  should_fail $(check_tag_exists "deployed/release/production/v3.1.9")

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "release/production/v3.1.9")

  should_succeed $(check_tag_exists "deployed/release/production/v3.1.9")
}

it_will_genereate_a_new_deploy_tag_for_each_release_overwriting_any_existing() {
  local tags=( "release/production/v3.1.9" )
  generate_sandbox_tags tags[@]

  should_succeed $(check_tag_exists "release/production/v3.1.9")
  should_fail $(check_tag_exists "deployed/release/production/v3.1.9")

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/production/v3.1.9')

  should_succeed $(check_tag_exists "deployed/release/production/v3.1.9")
  file_should_exist 'CHANGELOG'
  file_should_not_exist 'DifferentFile'

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/production/v3.1.9') $(arg_for $ARG_CHANGELOG 'DifferentFile')

  should_succeed $(check_tag_exists "deployed/release/production/v3.1.9")
  file_should_not_exist 'CHANGELOG'
  file_should_exist 'DifferentFile'
}

it_will_genereate_a_new_deploy_tag_for_next_release_with_defaults() {
  #From last deployed tag
  #With anything else in HEAD
  #Overwrite any existing tag

  local tags=(
    'release/v1.0.5'
    'deployed/release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    '[Any Old] Message for 1.0.5'
    'The last deployed release'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)

latest commit message to 1.0.6
The last deployed release

$(changelog_divider)
$(changelog_footer)"

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6') $(arg_for $ARG_CHANGELOG 'DiffChangeLog')
  file_should_not_exist 'CHANGELOG'

  test "$(cat DiffChangeLog)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)

latest commit message to 1.0.6
The last deployed release

$(changelog_divider)
$(changelog_footer)"
}

it_will_generate_a_deploy_changelog_for_a_set_starting_point() {
  local tags=(
    'release/v1.0.4'
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    'commit message for 1.0.4'
    '[Any Old] Message for 1.0.5'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)

latest commit message to 1.0.6
[Any Old] Message for 1.0.5
commit message for 1.0.4
Initial Commit

$(changelog_divider)
$(changelog_footer)"

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6') $(arg_for $ARG_START 'release/v1.0.5')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)

latest commit message to 1.0.6
[Any Old] Message for 1.0.5

$(changelog_divider)
$(changelog_footer)"
}

it_will_generate_a_deploy_changelog_for_a_set_range_with_start_and_end() {
  local tags=(
    'release/v1.0.4'
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    'commit message for 1.0.4'
    '[Any Old] Message for 1.0.5'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6') $(arg_for $ARG_START 'release/v1.0.4') $(arg_for $ARG_FINISH 'release/v1.0.5')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)

[Any Old] Message for 1.0.5
commit message for 1.0.4

$(changelog_divider)
$(changelog_footer)"
}

it_will_generate_a_deploy_changelog_with_optional_names() {
  local tags=(
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    '[Any Old] Message for 1.0.5'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  file_should_not_exist "CHANGELOG"

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6')

  file_should_exist "CHANGELOG"

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG "release/v1.0.6") $(arg_for $ARG_CHANGELOG "NewChangeLog")

  file_should_not_exist 'CHANGELOG'
  file_should_exist "NewChangeLog"
}

it_will_generate_a_deploy_changelog_file_scoped_to_pull_requests() {
  local tags=(
    'tag_with_pulls/1'
    'tag_with_pulls/2'
    'tag_without_pulls/1'
    'tag_with_pulls/3'
    'tag_with_pulls/4'
    'release/v0.0.1'
  )
  local commit_messages=(
    "Merge pull request #705 from SomeOrg/bug/limit-field-description-length

[BUG] Login screen broken in firefox"
    "Merge pull request #722 from SomeOrg/feature/login-field-firefox (Bill Hoskings, 18 hours ago)

[Features] This is a pull request merging a feature across multiple
lines and continuing"
    " A commit,that isn't a pull request"
    "Merge pull request #714 from SomeOrg/fix-login

Fixing the login but no tag displayed."
    "Merge pull request #685 from SomeOrg/bug/modal-login

[Security] Commit fixing the modal with security flaw"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v0.0.1') $(arg_for $ARG_PULL_REQUESTS)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 0.0.1
|| Released on $(get_current_release_date)
$(changelog_divider)

Features:
  This is a pull request merging a feature across multiple
lines and continuing

Security:
  Commit fixing the modal with security flaw

Bugs:
  Login screen broken in firefox

Fixing the login but no tag displayed.

$(changelog_divider)
$(changelog_footer)"
}

it_will_generate_a_changelog_file_scoped_to_pull_requests_with_urls() {
  local tags=(
    'tag_with_pulls/1.0.0'
    'tag_with_pulls/2.0.0'
    'tag_with_pulls/3.0.0'
    'tag_with_pulls/4.0.0'
  )
  local commit_messages=(
    "Merge pull request #705 from SomeOrg/bug/limit-payment-description-length

[BUG] logout screen"
    "Merge pull request #722 from SomeOrg/feature/running-balance-field (Bill Hoskings, 18 hours ago)

[Features] This is a pull request merging a feature across multiple
lines and continuing"
    "Merge pull request #714 from SomeOrg/fix-login

Fixing the login but no tag displayed."
    "Merge pull request #685 from SomeOrg/bug/modal-new-login

[Bug] Fix cookie storing sensitive data"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'tag_with_pulls/4.0.0') $(arg_for $ARG_PULL_REQUESTS) $(arg_for $ARG_DISPLAY_URLS)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 4.0.0
|| Released on $(get_current_release_date)
$(changelog_divider)

Features:
  This is a pull request merging a feature across multiple
lines and continuing - https://github.com/organisation/repo-name/pull/722

Bugs:
  Fix cookie storing sensitive data - https://github.com/organisation/repo-name/pull/685
  logout screen - https://github.com/organisation/repo-name/pull/705

Fixing the login but no tag displayed. - https://github.com/organisation/repo-name/pull/714

$(changelog_divider)
$(changelog_footer)"
}

it_will_generate_a_changelog_file_scoped_to_commits_with_urls() {
  local tags=(
    'release/v1.0.5'
    'release/v1.0.6'
  )
  local commit_messages=(
    '[Any Old] Message for 1.0.5'
    'latest commit message to 1.0.6'
  )

  generate_sandbox_tags tags[@] commit_messages[@]
  local commit_sha=$(git log --format="%H" | head -1)

  local commit_sha_list=$(get_commits_between_points "" "release/v1.0.6")
  local commit_shas=($commit_sha_list)

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.6') $(arg_for $ARG_DISPLAY_URLS)

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)

latest commit message to 1.0.6 - https://github.com/organisation/repo-name/commit/${commit_shas[0]}
[Any Old] Message for 1.0.5 - https://github.com/organisation/repo-name/commit/${commit_shas[1]}
Initial Commit - https://github.com/organisation/repo-name/commit/${commit_shas[2]}

$(changelog_divider)
$(changelog_footer)"
}

it_will_append_to_a_deploy_changelog_optionally(){
  local tags=(
    'release/v1.0.7'
    'release/v1.0.8'
    'release/v1.0.9'
  )
  local commit_messages=(
    'commit message for 1.0.7'
    '[Any Old] Message for 1.0.8'
    'latest commit message to 1.0.9'
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.7')

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.7
|| Released on $(get_current_release_date)
$(changelog_divider)

commit message for 1.0.7
Initial Commit

$(changelog_divider)
$(changelog_footer)"

  #Add current changelog to tag
  git checkout release/v1.0.8
  git merge deployed/release/v1.0.7
  git tag -f release/v1.0.8
  git checkout master

  sandbox_rup $(arg_for $ARG_DEPLOYED_TAG 'release/v1.0.8') $(arg_for $ARG_APPEND)

test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.8
|| Released on $(get_current_release_date)
$(changelog_divider)

Merge tag 'deployed/release/v1.0.7' into HEAD
[Any Old] Message for 1.0.8
Release deployed : release/v1.0.7

$(changelog_divider)
$(changelog_divider)
|| Release: 1.0.7
|| Released on $(get_current_release_date)
$(changelog_divider)

commit message for 1.0.7
Initial Commit

$(changelog_divider)
$(changelog_footer)"
}

#TODO
# it_will_optionally_force_push_of_tag()
