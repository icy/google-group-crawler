#!/usr/bin/env bash

_test_viettug() {
  export _GROUP=viettug

  echo >&2 ":: --> Testing Public Group $_GROUP <--"
  crawler.sh -sh > "$_GROUP.sh" || return 1
  bash -n "$_GROUP.sh" || return 1
  bash -x "$_GROUP.sh" || return 1
  crawler.sh -rss || return 1

  grep "X-Received:" "$_GROUP/mbox/"m.*
}

_main() { :; }

export PATH="$PATH:$(dirname "${BASH_SOURCE[0]:-.}")/../"
cd "$(dirname "${BASH_SOURCE[0]:-.}")/../tests/" || exit 1

_test_viettug
