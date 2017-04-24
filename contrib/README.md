
## Fix dot in email addresses

By default, emails exported by the tool are not original because
Google's anti-spam mechanism removes some characters from them, for e.g,

    this.is.my.email@example.net    --> this.....@example.net

The `discourse` has a great script to fix this problem, as seen at

https://github.com/discourse/discourse/blob/648bcb6432ee1fbca0fc9d45c25c3d114f2a0892/script/import_scripts/mbox.rb

This script was imported to the `google-group-crawler` project, but it
was removed on Apr 24th 2017 due to license problem as described here

https://github.com/icy/google-group-crawler/issues/16#issuecomment-292509711

Removing is the best way to avoid duplication and future confusion.
