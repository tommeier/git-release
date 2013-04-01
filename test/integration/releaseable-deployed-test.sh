#!/bin/bash -e

. ./test/test_helper.sh
. ./support/releaseable.sh

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




