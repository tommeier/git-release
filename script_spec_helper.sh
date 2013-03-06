#Script spec helpers

function script_directory() {
  "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

#Search argument 1 for substring in argument 2
function search_substring() {
  if echo "$1" | grep -q "$2"; then
    echo 'found'
  else
    echo 'missing'
  fi;
}

function enter_sandbox() {
  __DIR__="$PWD"
  rm -rf .sandbox
  mkdir -p .sandbox
  cd .sandbox
}

