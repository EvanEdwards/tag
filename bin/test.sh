#!/bin/bash


function err { echo "$@" ; exit ; }
[ -d "test/src" ] || cd "$(dirname "$0" )/.."  
[ -d "test/src" ] || err "Must be run from root of dist"

#####################################################################

function tagTest {
  id="$1"
  shift

  mkdir -p "test/temp/${id}"
  cp -R test/src/* "test/temp/${id}/."
  ./tag "$@" "test/temp/${id}"/* 
  diff "test/temp/${id}" "test/good/${id}" \
    && echo -e "$id\t: \e[42;30m Success \e[0m" \
    || echo -e "$id\t: \e[41;1m FAILURE \e[0m"
}

[ -d "test/temp" ] && rm -R "test/temp"

tagTest base --quiet +mytag -foo
tagTest clean --quiet --clean +mytag -foo
tagTest field --quiet --field --clean +1983 -foo
tagTest field2 --quiet --field=2 --clean +2007 -foo



if [ "$1" == "--reset" ]
then
  rm -R test/good
  mv test/temp test/good
fi



