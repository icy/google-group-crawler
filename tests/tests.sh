#!/usr/bin/env bash

_test_public_1() {
  export _GROUP="${_GROUP:-google-group-crawler-public}"
  export _D_OUTPUT="${_D_OUTPUT:-./${_ORG:+${_ORG}-}${_GROUP}/}"
  export _F_OUTPUT="${_F_OUTPUT:-./${_ORG:+${_ORG}-}${_GROUP}.sh}"

  echo >&2 ""
  echo >&2 ":: --> Testing Public Group $_GROUP (ORG: ${_ORG:-<empty>}) <--"
  echo >&2 ":: --> _WGET_OPTIONS: ${_WGET_OPTIONS:-<empty>}"
  echo >&2 ""
  echo >&2 ":: Removing $PWD/$_D_OUTPUT"
  rm -rf "$PWD/$_D_OUTPUT/"
  echo >&2 ":: Generating $_F_OUTPUT..."
  crawler.sh -sh > "$_F_OUTPUT" || return 1
  bash -n "$_F_OUTPUT" || return 1
  echo >&2 ":: Executing $_F_OUTPUT..."
  bash -x "$_F_OUTPUT" || return 1
  crawler.sh -rss || return 1

  grep -Ri "Message-Id:" "$_D_OUTPUT/mbox/" \
  || {
    echo >&2 ":: Unable to find any mail messages from $_D_OUTPUT/mbox/"
    return 1
  }

  grep -Ri "CICD passed" "$_D_OUTPUT/mbox/" \
  || {
    echo >&2 ":: Unable to find string 'CICD passed' from $_D_OUTPUT/mbox/"
    return 1
  }
}

_test_reset() {
  unset _ORG
  unset _D_OUTPUT
  unset _F_OUTPUT
}

_test_public_1_with_cat() {
  (
    _test_reset
    export _GROUP="google-group-crawler-public2"
    _test_public_1
  )
}
_test_public_2_loop_detection() {
  (
    _test_reset
    export _ORG="viettug.org"
    export _GROUP="google-group-crawler-public2"
    export _WGET_OPTIONS="--load-cookies /dev/null --keep-session-cookies"
    _test_public_1
    [[ $? == 1 ]] \
    || {
      echo >&2 ":: Unable to detect a loop."
      return 1
    }
    echo >&2 ":: Loop detected when no cookie is provided. Test passed."
  )
}

_test_public_2_with_cookie() {
  (
    _test_reset
    export _ORG="viettug.org"
    export _GROUP="google-group-crawler-public2"
    export _WGET_OPTIONS="--load-cookies $(pwd -P)/private-cookies.txt --keep-session-cookies"
    _test_public_1
  )
}

_test_private_1() {
  (
    _test_reset
    export _GROUP="google-group-crawler-private"
    export _WGET_OPTIONS="--load-cookies $(pwd -P)/private-cookies.txt --keep-session-cookies"
    _test_public_1
  )
}

_main() { :; }

set -u

cd "$(dirname "${BASH_SOURCE[0]:-.}")/../tests/" || exit 1
export PATH="$PATH:$(pwd -P)/../"

_test_public_1 || exit 1
_test_public_1_with_cat || exit 1
_test_public_2_loop_detection || exit 1
#_test_public_2_with_cookie || exit 2
# _test_private_1 || exit 3
