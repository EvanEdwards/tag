#!/bin/bash


function err { echo "$@" ; exit ; }
[ -d "test/_src" ] || cd "$(dirname "$0" )/.."  
[ -d "test/_src" ] || err "Must be run from root of dist"

#####################################################################

function tagTest {
  id="$1"
  shift

  [ -e "test/temp" ] && rm -R "test/temp" &>/dev/null
  mkdir -p test/temp
  cp -R test/_src "test/temp/${id}"
  ./tag "$@" "test/temp/${id}"/* 
  diff "test/temp/${id}" "test/_good/${id}" \
    && echo -e "$id\t: \e[42;30m Success \e[0m" \
    || echo -e "$id\t: \e[41;1m FAILURE \e[0m"
  # rm -R "test/${id}"
}


tagTest base --quiet +mytag






