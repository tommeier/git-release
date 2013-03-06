#!/usr/bin/env roundup
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#rup() { /bin/sh "${DIR}/../../script/releaseable.sh" ; }
#rup() { /bin/sh "${DIR}/../../script/releaseable.sh" $1 $2 $3; } #Pass matching script to test

source ../../script/releaseable.sh
#/bin/sh ../../script/releaseable.sh test_something

describe "Unit : releaseable"

describe "Nested : releaseable"
it_passes() {
  usage=$(test_something)
  test "$usage" = "Howzat!"
}

it_will_fail_this_test() {
  usage=$(test_something)
  test "$usage" = "FailWhale!"
}
