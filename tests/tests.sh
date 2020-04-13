#!/usr/bin/env bash

_test_public_1() {
  export _GROUP="${_GROUP:-google-group-crawler-public}"
  export _D_OUTPUT="${_D_OUTPUT:-./${_ORG:+${_ORG}-}${_GROUP}/}"
  export _F_OUTPUT="${_F_OUTPUT:-./${_ORG:+${_ORG}-}${_GROUP}.sh}"
  export _GREP_MESSAGE="${_GREP_MESSAGE:-CICD passed}"

  echo >&2 ""
  echo >&2 ":: --> Testing Public Group $_GROUP (ORG: ${_ORG:-<empty>}) <--"
  echo >&2 ":: --> _CURL_OPTIONS: ${_CURL_OPTIONS:-<empty>}"
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

  grep -Ri "$_GREP_MESSAGE" "$_D_OUTPUT/mbox/" \
  || {
    echo >&2 ":: Unable to find string 'CICD passed' from $_D_OUTPUT/mbox/"
    return 1
  }
}

_test_reset() {
  unset _ORG
  unset _D_OUTPUT
  unset _F_OUTPUT
  unset _GREP_MESSAGE
  unset _CURL_OPTIONS
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
    _test_public_1
    [[ $? == 125 ]] \
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
    export _CURL_OPTIONS="--config curl-options.txt"
    export _GREP_MESSAGE="This is a public group from a private organization"
    _test_public_1
  )
}

_test_private_1() {
  (
    _test_reset
    export _GROUP="google-group-crawler-private"
    export _CURL_OPTIONS="--config curl-options.txt"
    _test_public_1
  )
}

_main() { :; }

set -u

cd "$(dirname "${BASH_SOURCE[0]:-.}")/../tests/" || exit 1
export PATH="$PATH:$(pwd -P)/../"

_test_public_1 || exit 1
_test_public_1_with_cat || exit 1
#_test_public_2_loop_detection || exit 1
_test_public_2_with_cookie || exit 2
_test_private_1 || exit 3
