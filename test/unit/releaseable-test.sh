#!/bin/bash -e

. ./test/test_helper.sh
. ./support/releaseable-functions.sh

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
