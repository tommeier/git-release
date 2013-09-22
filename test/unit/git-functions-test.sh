#!/bin/bash -e

. ./test/test_helper.sh
. ./support/git-functions.sh

describe "git-release - unit - git functions"

after() {
  if [[ $MAINTAIN_SANDBOX != true ]]; then
    remove_sandbox
  fi;
}

it_uses_check_tag_exists_to_return_false_if_no_tags_exist() {
  generate_git_repo

  result=$(set +e ; check_tag_exists "not/found/anything" ; echo $?)
  test 1 -eq $result

  result=$(set +e ; check_tag_exists "" ; echo $?)
  test 1 -eq $result
}

it_uses_check_tag_exists_to_return_false_if_it_doesnt_exist() {
  local tags=(
    "releases/v1.0.5"
    "releases/v1.0.6"
  )
  generate_sandbox_tags tags[@]

  result=$(set +e ; check_tag_exists "not/found/anything" ; echo $?)
  test 1 -eq $result

  result=$(set +e ; check_tag_exists ""; echo $?)
  test 1 -eq $result
}

it_uses_check_tag_exists_to_return_true_if_tag_exists() {

  local tags=(
    "releases/v1.0.5"
    "releases/v1.0.6"
  )
  generate_sandbox_tags tags[@]

  result=$(set +e ; check_tag_exists "releases/v1.0.5" ; echo $?)
  test 0 -eq $result

  result=$(set +e ; check_tag_exists "releases/v1.0.6" ; echo $?)
  test 0 -eq $result
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

#ensure_git_is_clean()

it_fails_on_ensure_git_is_clean_when_dirty(){
  generate_git_repo
  should_succeed $(ensure_git_is_clean)
  touch 'AnyOldFile'
  should_fail $(ensure_git_is_clean)

  test "$(ensure_git_is_clean)" = "Error - Current branch is in a dirty state, please commit your changes first.
# On branch master
# Untracked files:
#   (use \"git add <file>...\" to include in what will be committed)
#
#"$'\t'"AnyOldFile
nothing added to commit but untracked files present (use \"git add\" to track)"
}

it_passes_on_ensure_git_is_clean_when_clean(){
  generate_git_repo

  should_succeed $(ensure_git_is_clean)
}

#get_commits_between_points

it_uses_get_commits_between_points_to_list_all_commits_with_nothing_passed() {
  generate_git_repo

  test "$(get_commits_between_points)" = "$(get_sha_for_first_commit)"
}

it_uses_get_commits_between_points_to_list_all_commits_from_a_start_point() {
  local tags=(
    "random_tag_1"
    "releases/v1.0.5"
    "random_tag_2"
    "releases/v1.0.6"
    "random_tag_3"
  )
  generate_sandbox_tags tags[@]

  local output=$(get_commits_between_points 'random_tag_2')
  test "$output" = "$(get_sha_for_tag_name 'random_tag_3')
$(get_sha_for_tag_name 'releases/v1.0.6')
$(get_sha_for_tag_name 'random_tag_2')"
}

it_uses_get_commits_between_points_to_get_nothing_when_no_commits_exists() {
  generate_git_repo

  should_fail $(get_commits_between_points 'anyTagName' 'anotherTagName')
}

it_uses_get_commits_between_points_to_return_commits_with_no_start_point() {
  local tags=(
    "random_tag_1"
    "releases/v1.0.5"
    "random_tag_2"
    "releases/v1.0.6"
    "random_tag_3"
  )
  generate_sandbox_tags tags[@]

  local start_point=""
  local end_point="releases/v1.0.6"
  local output=$(get_commits_between_points "$start_point" "$end_point")

  #Ordered by creation date
  local target_tag_sha=$(get_sha_for_tag_name 'releases/v1.0.6')
  local older_sha_1=$(get_sha_for_tag_name 'random_tag_2')
  local older_sha_2=$(get_sha_for_tag_name 'releases/v1.0.5')
  local older_sha_3=$(get_sha_for_tag_name 'random_tag_1')
  local initial_commit=$(get_sha_for_first_commit)

  test "$output" = "$target_tag_sha
$older_sha_1
$older_sha_2
$older_sha_3
$initial_commit"
}

it_uses_get_commits_between_points_to_return_all_commits_between_points_with_filter() {
  local tags=(
    "random_tag_1"
    "random_tag_2"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
    "release/production/v3.1.9"
    "release/staging/v2.0.3"
  )
  generate_sandbox_tags tags[@]

  local start_point="release/production/v1.0.9"
  local end_point="release/production/v3.0.9"

  local commit_message=$(get_commit_message_for_latest_commit 'release/production/v3.0.9')
  local target_tag_sha=$(get_sha_for_tag_name 'release/production/v3.0.9')

  local output=$(get_commits_between_points "$start_point" "$end_point" "$commit_message")

  test "$output" = "$target_tag_sha"
}

it_uses_get_commits_between_points_to_return_all_commits_with_no_start_point_with_filter() {
  local tags=(
    "random_tag_1"
    "random_tag_2"
    "release/production/v1.0.9"
    "release/production/v3.0.9"
    "release/production/v3.1.9"
    "release/staging/v2.0.3"
  )
  generate_sandbox_tags tags[@]

  local start_point=""
  local end_point="release/production/v3.1.9"

  local commit_message=$(get_commit_message_for_latest_commit 'release/production/v3.1.9')
  local target_tag_sha=$(get_sha_for_tag_name 'release/production/v3.1.9')

  local output=$(get_commits_between_points "$start_point" "$end_point" "$commit_message")

  test "$output" = "$target_tag_sha"
}

it_uses_get_commits_between_points_to_return_all_commits_between_points() {
  local tags=(
    'random_tag_1'
    'releases/v1.0.5'
    'random_tag_2'
    'releases/v1.0.6'
  )
  generate_sandbox_tags tags[@]

  local start_point="releases/v1.0.5"
  local end_point="releases/v1.0.6"
  local output=$(get_commits_between_points "$start_point" "$end_point")

  #Ordered by creation date
  local target_tag_sha=$(get_sha_for_tag_name 'releases/v1.0.6')
  local older_sha_1=$(get_sha_for_tag_name 'random_tag_2')
  local older_sha_2=$(get_sha_for_tag_name 'releases/v1.0.5')

  test "$output" = "$target_tag_sha
$older_sha_1
$older_sha_2"
}
