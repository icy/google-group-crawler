#!/usr/bin/env bash

_test_public_1() {
  export _GROUP="${_GROUP:-google-group-crawler-public}"

  echo >&2 ":: --> Testing Public Group $_GROUP <--"
  crawler.sh -sh > "$_GROUP.sh" || return 1
  bash -n "$_GROUP.sh" || return 1
  bash -x "$_GROUP.sh" || return 1
  crawler.sh -rss || return 1
  grep -Ri "Message-Id:" "$_GROUP/mbox/" \
  || {
    echo >&2 ":: Unable to find any mail messages from $_GROUP/mbox/"
    return 1
  }
}

_test_public_2() {
  (
    export _ORG="viettug.org"
    export _GROUP="google-group-crawler-public2"
    export _WGET_OPTIONS="--load-cookies $(pwd -P)/private-cookies.txt --keep-session-cookies"
    _test_public_1
  )
}

_test_private_1() {
  (
    export _GROUP="google-group-crawler-private"
    export _WGET_OPTIONS="--load-cookies $(pwd -P)/private-cookies.txt --keep-session-cookies"
    _test_public_1
  )
}

_main() { :; }

cd "$(dirname "${BASH_SOURCE[0]:-.}")/../tests/" || exit 1
export PATH="$PATH:$(pwd -P)/../"

_test_public_1 || exit 1
_test_public_2 || exit 2
_test_private_1 || exit 3
