#!/usr/bin/env bash

# Author  : Ky-Anh Huynh
# License : MIT

_file="${1:-}"
if [[ -z "${_file}" || ! -f "$_file" ]]; then
  echo >&2 ":: Missing original cookie file as the first argument."
  exit 127
fi

< "$_file" tail -n +3 \
| awk  -v OFS='\t' \
 'BEGIN {printf("# Netscape HTTP Cookie File\n\n")}
  {$1 = "groups.google.com"; printf("%s\n", $0)}'
