#!/bin/bash -e

. ./test/test_helper.sh
. ./support/support-functions.sh

rup() { ./bin/releaseable-deployed $@; }
sandbox_rup() { /bin/bash ../bin/releaseable-deployed $@; }

usage_head="++ /bin/bash ../bin/releaseable-deployed
Required parameter: Please enter the deploy tag released.
Usage : releaseable-deployed -d 'opt' [-p 'opt'] [-h] [-t] [-p 'opt'] [-s 'opt'][-f 'opt'][-A][-P][-C] --- create git release tag for a deployed releaseable with generated changelog."

describe "releaseable-deployed - integration"

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

  output=$(sandbox_rup 2>&1 | head -n 3 2>&1)
  test "$output" = "$usage_head"
}

it_will_display_error_when_no_git_directory_exists() {
  enter_sandbox

  output=$(sandbox_rup -d 'AnyDeployTag' 2>&1 | head -n 2 2>&1)
  missing_git="Error - Not a git repository please run from the base of your git repo."

  test $(search_substring "$output" "$missing_git") = 'found'
}

it_will_error_if_git_is_in_a_dirty_state() {
  local tag_name='MyReleases/v1.0.3'
  local tags=("${tag_name}")
  generate_sandbox_tags tags[@]

  should_succeed $(sandbox_rup -d "$tag_name")

  touch 'FileToMakeGitDirty'

  should_fail $(sandbox_rup -d "$tag_name")

  rm 'FileToMakeGitDirty'

  should_succeed $(sandbox_rup -d "$tag_name")
}

it_will_forcibly_replace_existing_deploy_tags() {
  local tag_name="MyReleases/v1.0.3"
  local tags=("${tag_name}")
  generate_sandbox_tags tags[@]

  result=$(sandbox_rup -d "$tag_name")
  file_should_exist "CHANGELOG"
  file_should_not_exist "CHANGELOG2"

  result=$(sandbox_rup -d "$tag_name" -C "CHANGELOG2")
  file_should_not_exist "CHANGELOG"
  file_should_exist "CHANGELOG2"

  #Explicitly checkout the deploy tag in current state
  git checkout -f -B "deployed/MyReleases/v1.0.3"

  file_should_not_exist "CHANGELOG"
  file_should_exist "CHANGELOG2"
}

it_will_error_if_deploy_tag_cannot_be_found(){
  local tag_name='found/v1.0.3'
  local tags=("${tag_name}")
  generate_sandbox_tags tags[@]

  should_succeed $(sandbox_rup -d "$tag_name")
  should_fail $(sandbox_rup -d "cannotFindThisTag")
}

# ### Success cases

it_will_genereate_a_new_deploy_tag_for_each_release() {
  local tags=( "release/production/v3.1.9" )
  generate_sandbox_tags tags[@]

  should_succeed $(check_tag_exists "release/production/v3.1.9")
  should_fail $(check_tag_exists "deployed/release/production/v3.1.9")

  output=$(sandbox_rup -d "release/production/v3.1.9")

  should_succeed $(check_tag_exists "deployed/release/production/v3.1.9")
}

it_will_genereate_a_new_deploy_tag_for_each_release_overwriting_any_existing() {
  local tags=( "release/production/v3.1.9" )
  generate_sandbox_tags tags[@]

  should_succeed $(check_tag_exists "release/production/v3.1.9")
  should_fail $(check_tag_exists "deployed/release/production/v3.1.9")

  output=$(sandbox_rup -d "release/production/v3.1.9")
  should_succeed $(check_tag_exists "deployed/release/production/v3.1.9")
  file_should_exist 'CHANGELOG'
  file_should_not_exist 'DifferentFile'

  output=$(sandbox_rup -d "release/production/v3.1.9" -C 'DifferentFile')
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

  output=$(sandbox_rup -d "release/v1.0.6")

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.6
|| Released on $(get_current_release_date)
$(changelog_divider)
latest commit message to 1.0.6
The last deployed release
$(changelog_divider)
$(changelog_footer)"

  output=$(sandbox_rup -d "release/v1.0.6" -C 'DiffChangeLog')
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

  output=$(sandbox_rup -d "release/v1.0.6")

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

  output=$(sandbox_rup -d "release/v1.0.6" -s "release/v1.0.5")

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

  output=$(sandbox_rup -d "release/v1.0.6" -s "release/v1.0.4" -f "release/v1.0.5")

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

  output=$(sandbox_rup -d "release/v1.0.6")

  file_should_exist "CHANGELOG"

  output=$(sandbox_rup -d "release/v1.0.6" -C 'NewChangelog')
  file_should_not_exist 'CHANGELOG'
  file_should_exist "NewChangelog"
}

it_will_generate_a_deploy_changelog_file_scoped_to_pull_requests() {
  local tags=(
    'tag_with_pulls/1'
    'tag_with_pulls/2'
    'tag_without_pulls/1'
    'tag_with_pulls/3'
    'tag_with_pulls/4'
    'releases/v0.0.1'
  )
  local commit_messages=(
    "Merge pull request #705 from Ferocia/bug/limit-payment-description-length

[BUG] Pay anyone from the accounts screen"
    "Merge pull request #722 from Ferocia/feature/running-balance-field (Anthony Langhorne, 18 hours ago)

[Features] This is a pull request merging a feature across multiple
lines and continuing"
    " A commit,that isn't a pull request"
    "Merge pull request #714 from Ferocia/fix-customer-login

Fixing the customer login but no tag displayed."
    "Merge pull request #685 from Ferocia/bug/modal-new-payee

[Security] Commit fixing the modal with security flaw"
  )

  generate_sandbox_tags tags[@] commit_messages[@]

  output=$(sandbox_rup -d "releases/v0.0.1" -P)

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
  Pay anyone from the accounts screen

Fixing the customer login but no tag displayed.
$(changelog_divider)
$(changelog_footer)"
}

it_will_append_to_a_deploy_changelog_optionally(){
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

  output=$(sandbox_rup -d "release/v1.0.4")

  test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.4
|| Released on $(get_current_release_date)
$(changelog_divider)
commit message for 1.0.4
Initial Commit
$(changelog_divider)
$(changelog_footer)"

  #Add current changelog to tag
  git checkout release/v1.0.5
  git merge deployed/release/v1.0.4
  git tag -f release/v1.0.5
  git checkout master

  output=$(sandbox_rup -d "release/v1.0.5" -A)

test "$(cat CHANGELOG)" = "$(changelog_divider)
|| Release: 1.0.5
|| Released on $(get_current_release_date)
$(changelog_divider)
Merge tag 'deployed/release/v1.0.4' into HEAD
[Any Old] Message for 1.0.5
Release deployed : release/v1.0.4
$(changelog_divider)
$(changelog_divider)
|| Release: 1.0.4
|| Released on $(get_current_release_date)
$(changelog_divider)
commit message for 1.0.4
Initial Commit
$(changelog_divider)
$(changelog_footer)"
}

#TODO
# it_will_optionally_force_push_of_tag()
