#!/bin/sh -e
set -e

############################################################
#####              Releasable-Deployed                 #####
###   Pure bash script for handling deployed releases    ###
###       Providing a tag with generated changelog       ###
############################################################


#Psuedo =>
#Pass in tag released
#Pass in prefix for deployment tag
#Optional : append/overwrite CHANGELOG
#Optional : changelog scope
#Optional : Force push
#Optional : Start + End point

#Error ->
    #Not a GIT repo
    # Dirty git repo
    # Tag not found

#Checkout existing tag
#Generate new changelog
#Create tag with deploy prefix
#Push tag (optional)

############################################################
#####                   DEFAULTS                       #####
############################################################

DEPLOYED_PREFIX='deployed'
CHANGELOG_FILE='CHANGELOG'
CHANGELOG_SCOPE=':all_commits'
CHANGELOG_STRATEGY=':overwrite'

START_POINT=''
END_POINT=''

USAGE_OUTPUT="Usage : $(basename "$0") -d 'opt' [-p 'opt'] [-h] [-t] [-p 'opt'] [-s 'opt'][-f 'opt'][-A][-P][-C] --- create git release tag for a deployed releaseable with generated changelog.

options:
  required:
    -d set the deployed tag name
  optional:
    -p set the prefix for deployment tag (default: deployed)
  changelog:
    -s  set the start point (default: the last deployed tag)
    -f  set the end/finish point (default: HEAD)
    -A  append to changelog (default: overwrite)
    -P  set to only pull requests (default: all commits)
    -C  set the changelog filename (default: CHANGELOG)
  general:
  -h  show this help text
  -t  test only (will not execute script)


usage examples:

  1) Basic usage with defaults
    Given the last deployed release was 'releases/v1.1.4' :

    $(basename "$0") -d 'releases/v1.1.4' -p 'deploys/staging'

    Tag generated           : deploys/staging/our-releases/REL1.1.4
    CHANGELOG file contains : commit information for all commits between last deployed version and current release

  2) Pull requests only (changelog generated only with body of pull request titles)

    $(basename "$0") -d 'releases/v1.0.4' -P

  3) Generate custom changelog for deployed versions

   $(basename "$0") -d 'releases/v1.0.4' -C 'DEPLOYEDCHANGELOG''

"

#Supporting functions
script_source=$( dirname "${BASH_SOURCE[0]}" )
source $script_source/support/releaseable.sh

############################################################
#####                  INPUT CAPTURE                   #####
############################################################

while getopts htAPCd:s:f:p: option
do
  case "${option}"
  in
    d) DEPLOYED_TAG="$OPTARG";;
    p) DEPLOYED_PREFIX="$OPTARG";;
    s) START_POINT="$OPTARG";;
    f) END_POINT="$OPTARG";;
    A) CHANGELOG_STRATEGY=":append";;
    P) CHANGELOG_SCOPE=":pulls_only";;
    C) CHANGELOG_FILE="$OPTARG";;
    h)
      echo "$USAGE_OUTPUT" >&2
      exit 0
      ;;
    t) SKIP_EXECUTE=true;;
    ?)
      printf "illegal option: '%s'\n" "$OPTARG" >&2
      echo "$USAGE_OUTPUT" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))


if [ ! $SKIP_EXECUTE ]; then
  ############################################################
  #####                  VALIDATION                      #####
  ############################################################

  ensure_git_directory
  ensure_git_is_clean
  validate_deploy_tag "$DEPLOYED_TAG" "$USAGE_OUTPUT"

  #exit 0
  ############################################################
  #####                   RELEASE                        #####
  ############################################################
  # VERSIONING_PREFIX=$(versioning_prefix $RELEASE_PREFIX $VERSION_PREFIX)

  # last_tag_name=$(get_last_tag_name $VERSIONING_PREFIX);

  # if [[ "$START_POINT" = '' ]]; then
  #   START_POINT=$last_tag_name
  # fi;

  # next_version_number=$(get_next_version_number $VERSION_TYPE $last_tag_name)
  # next_tag_name="${VERSIONING_PREFIX}${next_version_number}"
  # generate_version_file "$next_version_number" "$VERSION_FILE"

  # changelog_content=$(generate_changelog_content "$next_version_number" "$CHANGELOG_SCOPE" "$START_POINT" "$END_POINT")

  # generate_changelog_file "$changelog_content" "$CHANGELOG_STRATEGY" "$CHANGELOG_FILE"

  # #TODO : Test mode should display process
  # #TODO : Verbose debug mode

  # #TODO : Split up functions and specs into more logical divisions (changelog, git)

  # #TODO : Add option for applying deploy (no new tag -> add deploy prefix + tag, regen changelog)
  # #Maybe a seperate bash script? deploy-releaseable, pass in the successful deploy tag.
  # # --> Create new tag with deploy prefix?
  # # --> Generate changelog in the same way

  # #TODO : Ask for confirmation unless -f (force) is passed
  # set +e #Allow commit to fail if no files have changed
  # git add -A
  # git commit -m "Release : ${next_tag_name}"
  # set -e

  # git tag $next_tag_name
fi;
