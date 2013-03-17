#!/bin/sh -e
set -e

############################################################
#####                  Releasable                      #####
### Pure bash script for handling git release versioning ###
############################################################


############################################################
#####                   DEFAULTS                       #####
############################################################

RELEASE_PREFIX='release'
VERSION_PREFIX='v'

USAGE_OUTPUT="Usage : $(basename "$0") -v 'opt' [-h] [-t] [-r 'opt'][-p 'opt'][-e 'opt'] --- create git release tags

options:
    -h  show this help text
    -v  [required] set the software versioning type (major or minor or patch)
    -t  test only (will not execute script)
    -r  set the release prefix (default: release)
    -p  set the version prefix (default: v)
    -e  set release environment (optional)

default examples:
    git release tag         : release/v1.0.4
    environment release tag : release/production/v1.0.4

usage example:
    Given the last release was at 1.0.4 :

    $(basename "$0") -h -v minor -r 'our-releases' -p 'REL-'

    Tag generated : our-releases/REL1.1.4
"

#Supporting functions
script_source=$( dirname "${BASH_SOURCE[0]}" )
source $script_source/support/releaseable.sh

############################################################
#####                  INPUT CAPTURE                   #####
############################################################

while getopts ht:v:r:p:e option
do
        case "${option}"
        in
                h)
                  echo "$USAGE_OUTPUT" >&2
                  exit 0
                  ;;
                t) SKIP_EXECUTE=true;;
                v) VERSION_TYPE="$OPTARG";;
                r) RELEASE_PREFIX="$OPTARG";;
                p) VERSION_PREFIX="$OPTARG";;
                e) APP_ENV="$OPTARG";;
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

  validate_version_type $VERSION_TYPE $USAGE_OUTPUT
  ensure_git_directory $VERSIONING_PREFIX
  #TODO : Error if git in dirty state

  ############################################################
  #####                   RELEASE                        #####
  ############################################################
  VERSIONING_PREFIX=$(versioning_prefix $RELEASE_PREFIX $VERSION_PREFIX)

  last_tag_name=$(get_last_tag_name $VERSIONING_PREFIX)
  next_tag_name=$(get_next_tag_name $VERSION_TYPE $VERSIONING_PREFIX)

  generate_changelog "$last_tag_name" "$next_tag_name"
  #TODO : Changelog generation (diff between last release)
  #     : Get pull request bodies or optionally all commit messages
  #     : TODO : Tagging for changelog generation

  #TODO : Add option for applying deploy (no new tag -> add deploy prefix + tag, regen changelog)
  #Maybe a seperate bash script? deploy-releaseable, pass in the successful deploy tag.
  # --> Create new tag with deploy prefix?
  # --> Generate changelog in the same way

  #     : TODO : Email deploy notificatiion with changelog generation

  #TODO : Ask for confirmation unless -f (force) is passed
  set +e #Allow commit to fail if no files have changed
  git add -A
  git commit -m "Release : ${next_tag_name}"
  set -e

  git tag $next_tag_name
  #TODO : Test mode should display process
fi;


#TODO : Refactor specs to pass set of tags to create, with optional commit messages
#       So it reduces the number of tags generated for each spec
