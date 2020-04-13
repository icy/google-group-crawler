#!/usr/bin/env bash
#
# Purpose: Make a backup of Google Group [Google Group Crawler]
# Author : Anh K. Huynh
# Date   : 2013 Sep 22nd
# License: MIT license
#
# Copyright (c) 2013 - 2018 Ky-Anh Huynh <kyanh@viettug.org>
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
# Forum, list of all threads (topics), LIFO
#   https://groups.google.com/forum/?_escaped_fragment_=forum/archlinuxvn
#
# Topic, list of all messages in a thread (topic), FIFO
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

_short_url() {
  printf '%s\n' "${*//https:\/\/groups.google.com${_ORG:+\/a\/$_ORG}\/forum\/\?_escaped_fragment_=/}"
}

_links_dump() {
  # shellcheck disable=2086
  curl \
    --user-agent "$_USER_AGENT" \
    $_CURL_OPTIONS \
    -Lso- "$@" \
  | sed -e "s#['\"]#\\"$'\n#g' \
  | grep -E '^https?://' \
  | sort -u
}

# $1: output file [/path/to/directory/prefix]
# $2: url
_download_page() {
  local _f_output
  local _url="$2"
  local _surl=
  local __

  _surl="$(_short_url "$_url")"
  __=0
  while :; do
    _f_output="$1.${__}"
    if [[ -f "$_f_output" ]]; then
      if [[ -n "${_FORCE:-}" ]]; then
        echo >&2 ":: Updating '$_f_output' with '${_surl}'"
      else
        echo >&2 ":: Skipping '$_f_output' (downloaded with '${_surl}')"
        if ! _url="$(grep -E -- "_escaped_fragment_=((forum)|(topic)|(categories))/$_GROUP" "$_f_output")"; then
          break
        fi
        (( __ ++ ))
        continue
      fi
    else
      echo >&2 ":: Creating '$_f_output' with '${_surl}'"
    fi

    {
      echo >&2 ":: Fetching data from '$_url'..."
      _links_dump "$_url"
    } \
    | grep "https://" \
    | grep "/$_GROUP" \
    | awk '{print $NF}' \
    > "$_f_output"

    # Loop detection. See also
    #   https://github.com/icy/google-group-crawler/issues/24
    # FIXME: 2020/04: This isn't necessary after Google has changed something
    if [[ $__ -ge 1 ]]; then
      if diff "$_f_output" "$1.$(( __ - 1 ))" >/dev/null 2>&1; then
        echo >&2 ":: =================================================="
        echo >&2 ":: Loop detected. Your cookie may not work correctly."
        echo >&2 ":: You may want to generate new cookie file"
        echo >&2 ":: and/or remove all '#HttpOnly_' strings from it."
        echo >&2 ":: =================================================="
        exit 125
      fi
    fi

    if ! _url="$(grep -E -- "_escaped_fragment_=((forum)|(topic)|(categories))/$_GROUP" "$_f_output")"; then
      break
    fi

    (( __ ++ ))
  done
}

# Main routine
_main() {
  mkdir -pv "$_D_OUTPUT"/{threads,msgs,mbox}/ 1>&2 || exit 1

  echo >&2 ":: Downloading all topics (thread) pages..."
  # Each page contains a bunch of
  # topics sorted by time (the latest updated topic comes first.)
  #
  #  t.0 the first page   (the latest update)
  #  t.1 the second page
  #  (and so on)
  #
  _download_page "$_D_OUTPUT/threads/t" \
    "https://groups.google.com${_ORG:+/a/$_ORG}/forum/?_escaped_fragment_=categories/$_GROUP"

  echo >&2 ":: Downloading list of all messages..."
  #
  # Each thread (topic) file (`t.<number>`) contains a list of messages
  # sorted by time (the latest updated message comes first.)
  #
  #   t.0
  #     msg/m.{topic_id}.0  (the latest update)
  #     msg/m.{topic_id}.1
  #     (and so on)
  #
  #   t.1
  #     msg/m.{topic_id}.0  (the latest update [in this topic])
  #     msg/m.{topic_id}.1
  #     (and so on)
  #
  find "$_D_OUTPUT"/threads/ -type f -iname "t.[0-9]*" -exec cat {} \; \
  | grep '^https://' \
  | grep "/d/topic/$_GROUP" \
  | sort -u \
  | sed -e 's#/d/topic/#/forum/?_escaped_fragment_=topic/#g' \
  | while read -r _url; do
      _topic_id="${_url##*/}"
      _download_page "$_D_OUTPUT/msgs/m.${_topic_id}" "$_url"
      #                                 <--+------->
    done #                                 |
  #                                       /
  # FIXME: Sorting issue here -----------'

  echo >&2 ":: Downloading all raw messages..."
  find "$_D_OUTPUT"/msgs/ -type f -iname "m.*" -exec cat {} \; \
  | grep '^https://' \
  | grep '/d/msg/' \
  | sort -u \
  | sed -e 's#/d/msg/#/forum/message/raw?msg=#g' \
  | while read -r _url; do
      _id="$(echo "$_url"| sed -e "s#.*=$_GROUP/##g" -e 's#/#.#g')"
      echo "__curl__ \"$_D_OUTPUT/mbox/m.${_id}\" \"$_url\""
    done
}

_rss() {
  mkdir -pv "$_D_OUTPUT"/{threads,msgs,mbox}/ 1>&2 || exit 1

  {
    echo >&2 ":: Fetching RSS data..."
    # shellcheck disable=2086
    curl \
      --user-agent "$_USER_AGENT" \
      $_CURL_OPTIONS \
      -Lso- "https://groups.google.com${_ORG:+/a/$_ORG}/forum/feed/$_GROUP/msgs/rss.xml?num=${_RSS_NUM}"
  } \
  | grep '<link>' \
  | grep 'd/msg/' \
  | sort -u \
  | sed \
      -e 's#<link>##g' \
      -e 's#</link>##g' \
  | while read -r _url; do
      # shellcheck disable=SC2001
      _id_origin="$(sed -e "s#.*$_GROUP/##g" <<<"$_url")"
      _url="https://groups.google.com${_ORG:+/a/$_ORG}/forum/message/raw?msg=$_GROUP/$_id_origin"
      _id="${_id_origin//\//.}"
      echo "__curl__ \"$_D_OUTPUT/mbox/m.${_id}\" \"$_url\""
    done
}

# $1: Output File
# $2: The URL
__curl__() {
  if [[ ! -f "$1" ]]; then
    # shellcheck disable=2086
    curl -Ls \
      -A "$_USER_AGENT" \
      $_CURL_OPTIONS \
      "$2" -o "$1"
    __curl_hook "$1" "$2"
  fi
}

# $1: Output File
# $2: The URL
__curl_hook() {
  :
}

__sourcing_hook() {
  # shellcheck disable=1090
  source "$1" \
  || {
    echo >&2 ":: Error occurred when loading hook file '$1'"
    exit 1
  }
}

_ship_hook() {
  echo "#!/usr/bin/env bash"
  echo ""
  echo "export _ORG=\"\${_ORG:-$_ORG}\""
  echo "export _GROUP=\"\${_GROUP:-$_GROUP}\""
  echo "export _D_OUTPUT=\"\${_D_OUTPUT:-$_D_OUTPUT}\""
  echo "export _USER_AGENT=\"\${_USER_AGENT:-$_USER_AGENT}\""
  echo "export _CURL_OPTIONS=\"\${_CURL_OPTIONS:-$_CURL_OPTIONS}\""
  echo ""
  declare -f __curl_hook

  if [[ -f "${_HOOK_FILE:-}" ]]; then
    declare -f __sourcing_hook
    echo "__sourcing_hook $_HOOK_FILE"
  elif [[ -n "${_HOOK_FILE:-}" ]]; then
    echo >&2 ":: ${FUNCNAME[0]}: _HOOK_FILE ($_HOOK_FILE) does not exist."
    exit 1
  fi

  declare -f __curl__
}

_help() {
  echo "Please visit https://github.com/icy/google-group-crawler for details."
}

_has_command() {
  # well, this is exactly `for cmd in "$@"; do`
  for cmd do
    command -v "$cmd" >/dev/null 2>&1 || return 1
  done
}

_check() {
  local _requirements=
  _requirements="curl sort awk sed diff"
  # shellcheck disable=2086
  _has_command $_requirements \
  || {
    echo >&2 ":: Some program is missing. Please make sure you have $_requirements."
    return 1
  }

  if [[ -z "$_GROUP" ]]; then
    echo >&2 ":: Please use _GROUP environment variable to specify your google group"
    return 1
  fi
}

# An empty function. Can you tell me why is it?
__main__() { :; }

set -u

_ORG="${_ORG:-}"
_GROUP="${_GROUP:-}"
_D_OUTPUT="${_D_OUTPUT:-./${_ORG:+${_ORG}-}${_GROUP}/}"
# _GROUP="${_GROUP//+/%2B}"
_USER_AGENT="${_USER_AGENT:-Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0}"
_CURL_OPTIONS="${_CURL_OPTIONS:-}"
_RSS_NUM="${_RSS_NUM:-50}"

export _ORG _GROUP _D_OUTPUT _USER_AGENT _CURL_OPTIONS _RSS_NUM

_check || exit

case ${1:-} in
"-h"|"--help")    _help;;
"-sh"|"--bash")   _ship_hook; _main;;
"-rss")           _ship_hook; _rss;;
*)                echo >&2 ":: Use '-h' or '--help' for more details";;
esac
