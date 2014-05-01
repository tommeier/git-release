#!/bin/bash -e

#Manifest to ensure correct loading of all files in order.
# Use to handle sourcing all required files.
# Loading example: . "${BASH_SOURCE[0]%/*}/../support/support-functions.sh"

. "${BASH_SOURCE[0]%/*}/language-bash.sh"
. "${BASH_SOURCE[0]%/*}/git-functions.sh"
. "${BASH_SOURCE[0]%/*}/git-release-functions.sh"
. "${BASH_SOURCE[0]%/*}/changelog-functions.sh"

if [[ "$STUB_ME" ]]; then
  #. "${BASH_SOURCE[0]%/*}/../test/test_helper.sh"
  #stub $STUB_ME;
fi
# if [[ $(declare -f stub > /dev/null; echo $?) -eq 0 ]]; then
  #stub open_changelog_for_edit
# fi;


