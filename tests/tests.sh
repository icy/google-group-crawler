#!/usr/bin/env bash

_test_public_1() {
  export _GROUP="${_GROUP:-google-group-crawler-public}"

  echo >&2 ":: --> Testing Public Group $_GROUP <--"
  crawler.sh -sh > "$_GROUP.sh" || return 1
  bash -n "$_GROUP.sh" || return 1
  bash -x "$_GROUP.sh" || return 1
  crawler.sh -rss || return 1
  grep -Ri "Message-Id:" "$_GROUP/mbox/"
}

_main() { :; }

cd "$(dirname "${BASH_SOURCE[0]:-.}")/../tests/" || exit 1
export PATH="$PATH:$(pwd -P)/../"

_test_public_1
