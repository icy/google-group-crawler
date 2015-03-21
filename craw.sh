#!/bin/bash
#
# Purpose: Make a backup of Google Group [Google Group Crawler]
# Author : Anh K. Huynh
# Date   : 2013 Sep 22nd
# License: MIT license
#
# Copyright (c) 2013 - 2014 Anh K. Huynh <kyanh@theslinux.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# For your hack ;)
#
# Forum, list of all threads, LIFO
#   https://groups.google.com/forum/?_escaped_fragment_=forum/archlinuxvn
#
# Topic, list of all messages in a thread, FIFO
#   https://groups.google.com/forum/?_escaped_fragment_=topic/archlinuxvn/wXRTQFqBtlA
#
# Raw, a MH mail message:
#   https://groups.google.com/forum/message/raw?msg=archlinuxvn/_atKwaIFVGw/rnwjMJsA4ZYJ
#
# Atom link
#
#   https://groups.google.com/forum/feed/archlinuxvn/msgs/atom.xml?num=100
#   https://groups.google.com/forum/feed/archlinuxvn/topics/atom.xml?num=50
#
#   Don't use a very big `num`. Google knows that and changes to 16.
#   The bad thing is that Google doesn't provide a link to a post.
#   It only provides link to a topic. Hence for two links above you
#   would get the same result: links to your topics...
#
# Rss link
#
#   https://groups.google.com/forum/feed/archlinuxvn/msgs/rss.xml?num=50
#   https://groups.google.com/forum/feed/archlinuxvn/topics/rss.xml?num=50
#
#   Rss link contains link to topic. That's great.
#

set -u

_GROUP="${_GROUP:-}"
_D_OUTPUT="${_D_OUTPUT:-./$_GROUP/}"
_USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:34.0) Gecko/20100101 Firefox/34.0"

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
      if [[ -n "${_FORCE:-}" ]]; then
        echo >&2 ":: Updating '$_f_output' with '$(_short_url $_url)'"
      else
        echo >&2 ":: Skipping '$_f_output' (downloaded with '$(_short_url $_url)')"
        if ! _url="$(grep -E '_escaped_fragment_=.*false%5D' "$_f_output")"; then
          break
        fi
        (( __ ++ ))
        continue
      fi
    else
      echo >&2 ":: Creating '$_f_output' with '$(_short_url $_url)'"
    fi

    {
      echo >&2 ":: Fetching data from '$_url'..."
      lynx -display_charset UTF-8 -useragent="$_USER_AGENT" --dump "$_url"
    } \
    | grep " https://" \
    | grep "/$_GROUP" \
    | awk '{print $NF}' \
    > "$_f_output"

    if ! _url="$(grep -E '_escaped_fragment_=.*false%5D' "$_f_output")"; then
      break
    fi

    (( __ ++ ))
  done
}

# Main routine
_main() {
  mkdir -pv "$_D_OUTPUT"/{threads,msgs,mbox}/ 1>&2 || exit 1

  _download_page "$_D_OUTPUT/threads/t" \
    "https://groups.google.com/forum/?_escaped_fragment_=forum/$_GROUP"

  # Download list of all topics
  cat $_D_OUTPUT/threads/t.[0-9]* \
  | grep '^https://' \
  | grep "/d/topic/$_GROUP" \
  | sort -u \
  | sed -e 's#/d/topic/#/forum/?_escaped_fragment_=topic/#g' \
  | while read _url; do
      _topic_id="${_url##*/}"
      _download_page "$_D_OUTPUT/msgs/m.${_topic_id}" "$_url"
    done

  # Download list of all raw messages
  cat $_D_OUTPUT/msgs/m.* \
  | grep '^https://' \
  | grep '/d/msg/' \
  | sort -u \
  | sed -e 's#/d/msg/#/forum/message/raw?msg=#g' \
  | while read _url; do
      _id="$(echo "$_url"| sed -e "s#.*=$_GROUP/##g" -e 's#/#.#g')"
      echo "__wget__ \"$_D_OUTPUT/mbox/m.${_id}\" \"$_url\""
    done
}

_rss() {
  mkdir -pv "$_D_OUTPUT"/{threads,msgs,mbox}/ 1>&2 || exit 1

  {
    echo >&2 ":: Fetching RSS data..."
    wget --user-agent="$_USER_AGENT" -O- "https://groups.google.com/forum/feed/$_GROUP/msgs/rss.xml?num=${_RSS_NUM:-50}"
  } \
  | grep '<link>' \
  | grep 'd/msg/' \
  | sort -u \
  | sed \
      -e 's#<link>##g' \
      -e 's#</link>##g' \
  | while read _url; do
      _id_origin="$(echo "$_url"| sed -e "s#.*$_GROUP/##g")"
      _url="https://groups.google.com/forum/message/raw?msg=$_GROUP/$_id_origin"
      _id="$(echo "$_id_origin" | sed -e 's#/#.#g')"
      echo "__wget__ \"$_D_OUTPUT/mbox/m.${_id}\" \"$_url\""
    done
}

# $1: Output File
# $2: The URL
__wget__() {
  if [[ ! -f "$1" ]]; then
    wget --user-agent="$_USER_AGENT" "$2" -O "$1"
    __wget_hook "$1" "$2"
  fi
}

# $1: Output File
# $2: The URL
__wget_hook() {
  :
}

__sourcing_hook() {
  source "$1" \
  || {
    echo >&2 ":: Error occurred when loading hook file '$1'"
    exit 1
  }
}

_ship_hook() {
  echo "#!/usr/bin/env bash"
  declare -f __wget_hook

  if [[ -f "${_HOOK_FILE:-/x/y/z/t/u/v/m}" ]]; then
    declare -f __sourcing_hook
    echo "__sourcing_hook $_HOOK_FILE"
  fi

  declare -f __wget__
}

_help() {
  echo "Please visit https://github.com/icy/google-group-crawler for details."
}

_check() {
  which wget >/dev/null \
  && which lynx > /dev/null \
  && which awk > /dev/null \
  || {
    echo >&2 ":: Some program is missing. Please make sure you have lynx, wget and awk"
    return 1
  }

  if [[ -z "$_GROUP" ]]; then
    echo >&2 ":: Please use _GROUP environment variable to specify your google group"
    return 1
  fi
}

_check || exit

case $1 in
"-h"|"--help")    _help;;
"-sh"|"--bash")   _ship_hook; _main;;
"-rss")           _ship_hook; _rss;;
*)                echo >&2 ":: Use '-h' or '--help' for more details";;
esac
