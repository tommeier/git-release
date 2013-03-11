#!/usr/bin/env roundup
source ./spec/scripts/script_spec_helper.sh

script_source='./script/releaseable.sh'
rup() { /bin/sh $script_source $@; }
sandbox_rup() { /bin/sh ../$script_source $@; }

usage_head="++ /bin/sh ./script/releaseable.sh -h
Usage : releaseable.sh -v 'opt' [-h] [-t] [-r 'opt'][-p 'opt'][-e 'opt'] --- create git release tags"

describe "releaseable - integration"

### Failure Cases

it_will_fail_with_no_versioning_type() {
  ! rup
}

it_will_display_help_text_on_fail() {
  output=$(rup 2>&1 | head -n 2 2>&1 )

  test $(search_substring "$output" "$usage_output") = 'found'
}

it_will_display_error_when_no_git_directory_exists() {
  enter_sandbox

  output=$(sandbox_rup -v patch 2>&1 | head -n 2 2>&1)
  missing_git="Error - Not a git repository please run from the base of your git repo."

  test $(search_substring "$output" "$missing_git") = 'found'
}

### Success cases

it_will_genereate_a_new_tag_for_next_release() {
  generate_sandbox_tags

  #Last tag : 'release/production/v3.1.9'
  should_succeed $(check_tag_exists "release/production/v3.1.9")
  should_fail $(check_tag_exists "release/production/v3.1.10")

  output=$(sandbox_rup -v patch -r "release/production" -p "v" 2>&1)

  should_succeed $(check_tag_exists "release/production/v3.1.10")
}

it_will_genereate_a_new_tag_for_next_release_with_defaults() {
  generate_sandbox_tags

  #Last tag : 'release/v1.0.6'
  should_succeed $(check_tag_exists "release/v1.0.6")
  should_fail $(check_tag_exists "release/v1.1.6")

  output=$(sandbox_rup -v minor 2>&1)

  should_succeed $(check_tag_exists "release/v1.1.6")
}

it_will_genereate_a_new_tag_for_next_release_when_none_exist() {
  generate_git_repo

  should_fail $(check_tag_exists "my-release/yay-1.0.0")
  should_fail $(check_tag_exists "my-release/yay-1.1.0")

  output=$(sandbox_rup -v major -r "my-release" -p "yay-" 2>&1)

  should_succeed $(check_tag_exists "my-release/yay-1.0.0")
  should_fail $(check_tag_exists "my-release/yay-1.1.0")

  output=$(sandbox_rup -v minor -r "my-release" -p "yay-" 2>&1)

  should_succeed $(check_tag_exists "my-release/yay-1.0.0")
  should_succeed $(check_tag_exists "my-release/yay-1.1.0")
}


