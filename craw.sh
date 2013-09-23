#!/bin/bash
#
# Purpose: Make a backup of Google Group [Google Group Cralwer]
# Author : Anh K. Huynh
# Date   : 2013 Sep 22nd
# License: MIT license
#
# Copyright (c) 2013 Anh K. Huynh <kyanh@theslinux.org>
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
# Forum: https://groups.google.com/forum/?_escaped_fragment_=forum/archlinuxvn
# Topic: https://groups.google.com/forum/?_escaped_fragment_=topic/archlinuxvn/wXRTQFqBtlA
# Raw: https://groups.google.com/forum/message/raw?msg=archlinuxvn/_atKwaIFVGw/rnwjMJsA4ZYJ
#

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
_main() {
  mkdir -pv "$_D_OUTPUT" || exit 1
  _download_page "$_D_OUTPUT/threads" \
    "https://groups.google.com/forum/?_escaped_fragment_=forum/$_GROUP"
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
    _id="$(echo "$_url"| sed -e "s#.*=$_GROUP/##g" -e 's#/#.#g')"
    echo wget -c "$_url" -O "$_D_OUTPUT/mbox.${_id}"
  done
}

_help() {
  cat <<\EOF
### Hello, world.

I'm Google Group cralwer. I'm written by Anh K. Huynh <kyanh@theslinux.org>.
I'm was born and released under the terms of the MIT license. You see
'craw.sh' because Anh made a typo error as he always did.

As you know Google Group (v1 or v2) doesn't have any direct way to export
your group's archive. Your data doesn't belong to you! Google also doesn't
have any good support for their free stuff. Use Google at your own risk.

I'm your saver! You are listening to me because you've kicked me with
'-h' or '--help' option. If I am kicked by '-sh' or '--bash' option,
I will give a you bash script to download all *mbox* files of your group.
For example,

    export _GROUP="mygroup"       # specify your group
    ./craw.sh -sh                 # first run for testing
    ./craw.sh -sh > wget.sh       # save your script
    bash wget.sh                  # dowloading mbox files

In my example, the first run is to download all basic information, included
list of topics, list of emails sent to the group. This run will print
very verbose information, you may not be interested in them. Actually,
in the very last steps, the game comes: All 'wget' commands are printed
to your standard output. The second run (which is very fast) will capture
all commands and save them into the file 'wget.sh', that can be executed
via 'bash wget.sh'.

You are almost ready to kick me. I just want to say that I am not alone.
I can't live without some girls; they are: lynx, wget, awk, and bash.
Buy me some, otherwise I quit!

### My whispers...

All email addresses (foo@bar.com) are hidden from mbox file. This is
because mbox file is public, hence the addresses must be hidden from
the spammers. This is very sad news. Fortunately, you can always write
a wrapper, to replace all hidden addresses with the real ones.

I write all data to an output directory specified by your '_D_OUTPUT'
environment. If you don't mind, it's the same as your group name.

By default, I will skip any download if the previous output does exist.
To force me (really!?) to download all stuff, use '_FORCE' environment.
For example

    _FORCE="please_do_it" ./craw.sh -sh

For heavy list, any process may take a very long time. For example,
SaigonLUG (Saigon Linux Users Group) takes 47 minutes. Sure this also
depends on your network (aka your money).

### More whispers?

Okay, I was born after Anh tried many crazy stuff: nodejs, phantomjs,
Watir, Google Group features. Anh finally found that the 'hash bang'
(#!) could give all tricks. No explainatnion here. L00LE it for yourself.

New web technology just makes life harder, doesn't it?
EOF
}

_check() {
  which wget >/dev/null \
  && which lynx > /dev/null \
  && which awk > /dev/null
}

_check \
|| {
  echo >&2 ":: Some program is missing. Please install them"
  exit 127
}

case $1 in
 "-h"|"--help") _help; exit 1 ;;
"-sh"|"--bash") _main;;
             *) echo >&2 ":: Use '-h' or '--help' for more details";
                exit 1 ;;
esac
