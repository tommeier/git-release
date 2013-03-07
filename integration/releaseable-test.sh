#!/usr/bin/env roundup
source ./spec/scripts/script_spec_helper.sh

script_source='./script/releaseable.sh'
rup() { /bin/sh $script_source $1 $2 $3; }
sandbox_rup() { /bin/sh ../$script_source $1 $2 $3; }

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
  rm -rf .git

  output=$(sandbox_rup -v patch 2>&1 | head -n 2 2>&1)
  missing_git="Error - Not a git repository please run from the base of your git repo."

  test $(search_substring "$output" "$missing_git") = 'found'
}


### Success cases

