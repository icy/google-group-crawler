[![Build Status](https://travis-ci.org/icy/google-group-crawler.svg?branch=master)](https://travis-ci.org/icy/google-group-crawler)

## Download all messages from Google Group archive

`google-group-crawler` is a `Bash-4` script to download all (original)
messages from a Google group archive.
Private groups require some cookies file in Netscape format.
Groups with adult contents haven't been supported yet.

* [Installation](#installation)
* [Usage](#usage)
  * [The first run](#the-first-run)
  * [Update your local archive thanks to rss feed](#update-your-local-archive-thanks-to-rss-feed)
  * [Private group or Group hosted by an organization](#private-group-or-group-hosted-by-an-organization)
  * [The hook](#the-hook)
  * [What to do with your local archive](#what-to-do-with-your-local-archive)
  * [Rescan the whole local archive](#rescan-the-whole-local-archive)
  * [Known problems](#known-problems)
* [Contributions](#contributions)
* [Similar projects](#similar-projects)
* [License](#license)
* [Author](#author)
* [For script hackers](#for-script-hackers)

## Installation

The script requires `bash-4`, `sort`, `wget`, `sed`, `awk`.

Make the script executable with `chmod 755` and put them in your path
(e.g, `/usr/local/bin/`.)

The script may not work on `Windows` environment as reported in
https://github.com/icy/google-group-crawler/issues/26.

## Usage

### The first run

For private group, please
[prepare your cookies file](#private-group-or-group-hosted-by-an-organization).

    # export _WGET_OPTIONS="-v"       # use wget options to provide e.g, cookies
    # export _HOOK_FILE="/some/path"  # provide a hook file, see in #the-hook

    # export _ORG="your.company"      # required, if you are using Gsuite
    export _GROUP="mygroup"           # specify your group
    ./crawler.sh -sh                  # first run for testing
    ./crawler.sh -sh > wget.sh        # save your script
    bash wget.sh                      # downloading mbox files

You can execute `wget.sh` script multiple times, as `wget` will skip
quickly any fully downloaded files.

### Update your local archive thanks to RSS feed

After you have an archive from the first run you only need to add the latest
messages as shown in the feed. You can do that with `-rss` option and the
additional `_RSS_NUM` environment variable:

    export _RSS_NUM=50                # (optional. See Tips & Tricks.)
    ./crawler.sh -rss > update.sh     # using rss feed for updating
    bash update.sh                    # download the latest posts

It's useful to follow this way frequently to update your local archive.

### Private group or Group hosted by an organization

To download messages from private group or group hosted by your organization,
you need to provide cookies in legacy format.

1. Export cookies for `google` domains from your browser and
   save them as file. Please use a Netscape format, and you may want to
   edit the file to meet a few conditions:

   1. The first line should be `# Netscape HTTP Cookie File`
   2. The file must use tab instead of space.
   3. The first field of every line in the file must be `groups.google.com`.

   A simple script to process this file is as below

        $ cat original_cookies.txt \
          | tail -n +3 \
          | awk  -v OFS='\t' \
            'BEGIN {printf("# Netscape HTTP Cookie File\n\n")}
             {$1 = "groups.google.com"; printf("%s\n", $0)}'

    See the sample files in the `tests/` directory

    1. The original file: [tests/sample-original-cookies.txt](tests/sample-original-cookies.txt)
    1. The fixed file: [tests/sample-fixed-cookies.txt](tests/sample-fixed-cookies.txt)

2. Specify your cookie file by `_WGET_OPTIONS`:

        export _WGET_OPTIONS="--load-cookies /your/path/fixed_cookies.txt --keep-session-cookies"

   Now every hidden group can be downloaded :)

### The hook

If you want to execute a `hook` command after a `mbox` file is downloaded,
you can do as below.

1. Prepare a Bash script file that contains a definition of `__wget_hook`
   command. The first argument is to specify an output filename, and the
   second argument is to specify an URL. For example, here is simple hook

        # $1: output file
        # $2: url (https://groups.google.com/forum/message/raw?msg=foobar/topicID/msgID)
        __wget_hook() {
          if [[ "$(stat -c %b "$1")" == 0 ]]; then
            echo >&2 ":: Warning: empty output '$1'"
          fi
        }

    In this example, the `hook` will check if the output file is empty,
    and send a warning to the standard error device.

2. Set your environment variable `_HOOK_FILE` which should be the path
   to your file. For example,

        export _GROUP=archlinuxvn
        export _HOOK_FILE=$HOME/bin/wget.hook.sh

   Now the hook file will be loaded in your future output of commands
   `crawler.sh -sh` or `crawler.sh -rss`.

### What to do with your local archive

The downloaded messages are found under `$_GROUP/mbox/*`.

They are in `RFC 822` format (possibly with obfuscated email addresses)
and they can be converted to `mbox` format easily before being imported
to your email clients  (`Thunderbird`, `claws-mail`, etc.)

You can also use [mhonarc](https://www.mhonarc.org/) ultility to convert
the downloaded to `HTML` files.

See also https://github.com/icy/google-group-crawler/issues/15.

### Rescan the whole local archive

Sometimes you may need to rescan / redownload all messages.
This can be done by removing all temporary files

    rm -fv $_GROUP/threads/t.*    # this is a must
    rm -fv $_GROUP/msgs/m.*       # see also Tips & Tricks

or you can use `_FORCE` option:

    _FORCE="true" ./crawler.sh -sh

Another option is to delete all files under `$_GROUP/` directory.
As usual, remember to backup before you delete some thing.

### Known problems

1. Fails on group with adult contents (https://github.com/icy/google-group-crawler/issues/14)
1. This script may not recover emails from public groups.
  When you use valid cookies, you may see the original emails
  if you are a manager of the group. See also https://github.com/icy/google-group-crawler/issues/16.
2. When cookies are used, the original emails may be recovered
  and you must filter them before making your archive public.
3. Got `423 Request Entity Too Large` with some group:
  https://github.com/icy/google-group-crawler/issues/34

## Contributions

1. `parallel` support: @Pikrass has a script to download messages in parallel.
  It's discussed in the ticket https://github.com/icy/google-group-crawler/issues/32.
  The script: https://gist.github.com/Pikrass/f8462ff8a9af18f97f08d2a90533af31
2. `raw access denied`: @alexivkin mentioned he could use the `print` function
  to work-around the issue. See it here
  https://github.com/icy/google-group-crawler/issues/29#issuecomment-468810786

## Similar projects

* (website) [Google Takeout - Download all info for any groups you own](https://takeout.google.com/)
* (Shell/curl) [ggscrape - Download emails from a Google Group. Rescue your archives](https://git.scuttlebot.io/%25nkOkiGF0Dd321GmNqs6aW%2BWHaH9Uunq4m8dVfJuU%2Bps%3D.sha256)
* (Python/Webdriver) [scrape_google_groups.py  - A simple script to scrape a google group](https://gist.github.com/punchagan/7947337)
* (Python/webscraping.webkit) [gg-scrape - Liberate you data from google groups](https://github.com/jrholliday/gg-scrape)
* (Python/urllib) [gg_scraper](https://gitlab.com/mcepl/gg_scraper)
* (PHP/libcurl) [scraping-google-groups](http://saturnboy.com/2010/03/scraping-google-groups/)

## License

This work is released under the terms of a MIT license.

## Author

This script is written by Anh K. Huynh.

He wrote this script because he couldn't resolve the problem by using
`nodejs`, `phantomjs`, `Watir`.

New web technology just makes life harder, doesn't it?

## For script hackers

Please skip this section unless your really know to work with `Bash` and shells.

0. If you clean your files _(as below)_, you may notice that it will be
   very slow when re-downloading all files. You may consider to use
   the `-rss` option instead. This option will fetch data from a `rss` link.

   It's recommmeded to use the `-rss` option for daily update. By default,
   the number of items is 50. You can change it by the `_RSS_NUM` variable.
   However, don't use a very big number, because Google will ignore that.

1. Because Topics is a FIFO list, you only need to remove the last file.
   The script will re-download the last item, and if there is a new page,
   that page will be fetched.

        ls $_GROUP/msgs/m.* \
        | sed -e 's#\.[0-9]\+$##g' \
        | sort -u \
        | while read f; do
            last_item="$f.$( \
              ls $f.* \
              | sed -e 's#^.*\.\([0-9]\+\)#\1#g' \
              | sort -n \
              | tail -1 \
            )";
            echo $last_item;
          done

2. The list of threads is a LIFO list. If you want to rescan your list,
   you will need to delete all files under `$_D_OUTPUT/threads/`

3. You can set the time for `mbox` output files, as below

        ls $_GROUP/mbox/m.* \
        | while read FILE; do \
            date="$( \
              grep ^Date: $FILE\
              | head -1\
              | sed -e 's#^Date: ##g' \
            )";
            touch -d "$date" $FILE;
          done

    This will be very useful, for example, when you want to use the
    `mbox` files with `mhonarc`.
