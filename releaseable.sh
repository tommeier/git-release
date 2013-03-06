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

############################################################
#####                  FUNCTIONS                       #####
############################################################

function validate_inputs() {
  #Confirm version type is in the accepted types
  local v="${VERSION_TYPE}"

  if [[ $v != 'major' && $v != 'minor' && $v != 'patch' ]]; then
    printf "incorrect versioning type: '%s'\n" "$v" >&2
    echo "Please set to one of 'major', 'minor' or 'patch'" >&2
    echo "$USAGE_OUTPUT" >&2
    exit 1
  fi;
}

function ensure_git_directory() {
  if [[ ! -d  '.git' ]]; then
    echo "Error - Not a git repository please run from the base of your git repo." >&2
    exit 1
  fi;
}

############################################################
#####                  INPUT CAPTURE                   #####
############################################################

while getopts htv:rpe option
do
        case "${option}"
        in
                h)
                  echo "$USAGE_OUTPUT" >&2
                  exit 0
                  ;;
                t) SKIP_EXECUTE=true;;
                v) VERSION_TYPE=$OPTARG;;

                ?)
                  printf "illegal option: '%s'\n" "$OPTARG" >&2
                  echo "$USAGE_OUTPUT" >&2
                  exit 1
                  ;;
        esac
done
shift $((OPTIND - 1))

############################################################
#####                TAG FUNCTIONS                     #####
############################################################

function get_release_tags() {
  # refs=`git log --date-order --simplify-by-decoration --pretty=format:%H`
  # ref_list=$(IFS=' '; echo "${refs[*]}")
  tag_pattern="${RELEASE_PREFIX}${VERSION_PREFIX}"
  tag_names=`git tag -l $tag_pattern*`
  #git name-rev --tags --all
  #00003b0ff9826fc1a8a2e6cd904e8a7d3ef5b9c6 tags/20110818_1_ultimate_warrior~1^2
  #0800aaa7cf30a6645108800931291b2bbff0be2e tags/20120213_1103_hulk_hogan~5^2
  #0900e412938f81238593e59247536ce116379d7c tags/20110812_1_release_ultimate_warrior~73

  #<ref> tags/<release_prefix>/<version_prefix><version_number>
  echo $tag_names
}

if [ ! $SKIP_EXECUTE ]; then

  ############################################################
  #####                  VALIDATION                      #####
  ############################################################

  validate_inputs
  ensure_git_directory

  echo 'Script Run'
fi;

