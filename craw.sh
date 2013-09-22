#!/bin/bash
#
# Purpose: Make a backup of Google Group
# Author : Anh K. Huynh
# Date   : 2013 Sep 22nd
# License: MIT license

# Forum: https://groups.google.com/forum/?_escaped_fragment_=forum/archlinuxvn
# Topic: https://groups.google.com/forum/?_escaped_fragment_=topic/archlinuxvn/wXRTQFqBtlA
# Raw: https://groups.google.com/forum/message/raw?msg=archlinuxvn/_atKwaIFVGw/rnwjMJsA4ZYJ

_GROUP="${_GROUP:-archlinuxvn}"
_D_OUTPUT="${_D_OUTPUT:-./$_GROUP/}"

_short_url() {
  echo "$@" | sed -e 's#https://groups.google.com/forum/?_escaped_fragment_=##g'
}
# $1: output file [/path/to/directory/prefix]
# $2: url
_download_page() {
  local _f_output
  local _url="$2"
  local __
  __=0
  while :; do
    _f_output="$1.${__}"
    if [[ -f "$_f_output" ]]; then
      if [[ -n "$_FORCE" ]]; then
        echo >&2 ":: Updating '$_f_output' with '$(_short_url $_url)'"
      else
        echo >&2 ":: Skipping '$_f_output' (downloaded with '$(_short_url $_url)')"
        if ! _url="$(grep '?_escaped_fragment_=' "$_f_output")"; then
          break
        fi
        (( __ ++ ))
        continue
      fi
    else
      echo >&2 ":: Creating '$_f_output' with '$(_short_url $_url)'"
    fi
    lynx --dump "$_url" \
      | grep "https://" \
      | grep "/$_GROUP" \
      | awk '{print $NF}' \
        > "$_f_output"
    if ! _url="$(grep '?_escaped_fragment_=' "$_f_output")"; then
      break
    fi
    (( __ ++ ))
  done
}

# Main routine

mkdir -pv "$_D_OUTPUT" || exit 1
_download_page "$_D_OUTPUT/threads" "https://groups.google.com/forum/?_escaped_fragment_=forum/$_GROUP"
cat $_D_OUTPUT/threads.[0-9]* \
| grep "/d/topic/$_GROUP" \
| sed -e 's#/d/topic/#/forum/?_escaped_fragment_=topic/#g' \
| while read _url; do
  _topic_id="${_url##*/}"
  _download_page "$_D_OUTPUT/msgs.${_topic_id}" "$_url"
done
cat $_D_OUTPUT/msgs.* \
| grep '/d/msg/' \
| sed -e 's#/d/msg/#/forum/message/raw?msg=#g' \
| while read _url; do
  curl -Ls "$_url" > "$_D_OUTPUT/mbox.${_url##*/}"
done
