### Hello, world.

I'm Google Group crawler. I'm written by Anh K. Huynh <kyanh@theslinux.org>.
I'm was born and released under the terms of **the MIT license**. You see
`craw.sh` because Anh made a typo error as he always did.

As you know Google Group (v1 or v2) doesn't have any direct way to export
your group's archive. Your data doesn't belong to you! Google also doesn't
have any good support for their free stuff. Use Google at your own risk.

I'm your saver! You are listening to me because you've kicked me with
`-h` or `--help` option. If I am kicked by `-sh` or `--bash` option,
I will give a you bash script to download all *mbox* files of your group.
For example,

    export _GROUP="mygroup"       # specify your group
    ./craw.sh -sh                 # first run for testing
    ./craw.sh -sh > wget.sh       # save your script
    bash wget.sh                  # dowloading mbox files

In my example, the first run is to download all basic information, included
list of topics, list of emails sent to the group. This run will print
very verbose information, you may not be interested in them. Actually,
in the very last steps, the game comes: All `wget` commands are printed
to your standard output. The second run (which is very fast) will capture
all commands and save them into the file `wget.sh`, that can be executed
via `bash wget.sh`.

You are almost ready to kick me. I just want to say that I am not alone.
I can't live without some girls; they are: `lynx`, `wget`, `awk`, and `bash`.
Buy me some, otherwise I quit!

### Known problems

I don't work with some lists, for example, *archlinuxvn-dot* or
*archlinuxvn-security*.

### My whispers...

All email addresses (foo@bar.com) are hidden in *mbox* files. This is
because mbox file is public, hence the addresses must be hidden from
the spammers. This is very sad news. Fortunately, you can always write
a wrapper, to replace all hidden addresses with the real ones.

I write all data to an output directory specified by your `_D_OUTPUT`
environment. If you don't mind, it's the same as your group name.

By default, I will skip any download if the previous output does exist.
To force me (really!?) to download all stuff, use `_FORCE` environment.
For example

    _FORCE="please_do_it" ./craw.sh -sh

For heavy list, any process may take a very long time. For example,
SaigonLUG (Saigon Linux Users Group) takes 47 minutes. Sure this also
depends on your network (aka your money).

### More whispers?

Okay, I was born after Anh tried many crazy stuff: `nodejs`, `phantomjs`,
`Watir`, Google Group features (Luckily, notthing worked). Anh finally found
that the *hash bang* (`#!`) could give all tricks. No explanation here.
`L00LE` it for yourself.

New web technology just makes life harder, doesn't it?
