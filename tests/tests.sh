#!/usr/bin/env bash

_test_viettug() {
  export _GROUP=viettug

  echo >&2 ":: --> Testing Public Group $_GROUP <--"
  crawler.sh -sh > "$_GROUP.sh"
  bash -n "$_GROUP.sh"
  bash -x "$_GROUP.sh"
}

_main() { :; }

export PATH="$PATH:$(dirname "${BASH_SOURCE[0]:-.}")/../"
cd "$(dirname "${BASH_SOURCE[0]:-.}")" || exit 1

_test_viettug
