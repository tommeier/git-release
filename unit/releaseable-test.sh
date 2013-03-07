#!/usr/bin/env roundup
source ./spec/scripts/script_spec_helper.sh
source ./script/support/releaseable.sh

describe "releaseable - unit"

after() {
  remove_sandbox
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


