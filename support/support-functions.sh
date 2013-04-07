#!/bin/bash -e

#Manifest to ensure correct loading of all files in order.
# Use to handle sourcing all required files.
# Loading example: . "${BASH_SOURCE[0]%/*}/../support/support-functions.sh"

. "${BASH_SOURCE[0]%/*}/git-functions.sh"
. "${BASH_SOURCE[0]%/*}/releaseable-functions.sh"
. "${BASH_SOURCE[0]%/*}/changelog-functions.sh"
