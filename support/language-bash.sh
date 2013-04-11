#!/bin/sh -e

#Language specific naming, to be overridden by whichever language is being used

ARG_ASSIGNER=" " #Argument assigner. space or = for assigning arguments
ARG_PREFIX="-" #Argument prefix (used in help text display such as '-' for '-v')
#Arguments for running script
ARG_VERSION="v"
ARG_DEPLOYED_TAG="d"
ARG_RELEASE_PREFIX="p"
ARG_START="s"
ARG_FINISH="f"
ARG_APPEND="A"
ARG_PULL_REQUESTS="P"
ARG_CHANGELOG="C"
ARG_VERSION_FILE="V"
ARG_HELP_TEXT="h"

#Display arg with language specific assigner and prefix
arg_for() {
  local arg="$1"
  local val="$2"
  if [[ $val != '' ]]; then
    echo "${ARG_PREFIX}${1}${ARG_ASSIGNER}${2}"
  else
    echo "${ARG_PREFIX}${1}"
  fi;
}

