## v1.2.2

* Loop detection: #24.
* Add test cases.
* Update documentation (Cookie issue.)
* Minor code improvements.
* Group with category support (#28, Thanks @LeeKevin)

## v1.2.1

* Fix bugs: #6 (compatibility issue),
    #13 (so large group),
    #16 (email exporting and third-party license issue)
* Fix script shebang.
* Google organization support.
* Ensure group name is in lowercase.
* Minor scripting improvements.

## v1.2.0

* Drop the use of `lynx` program. `wget` handles all download now.
* Accept `_WGET_OPTIONS` environment to control `wget` commands.
* Can work with private groups thanks to `_WGET_OPTIONS` environment.
* Rename script (`craw.sh` becomes `crawler.sh`.)
* Output important variables to the output script.
* Update documentation (`README.md`.)

## v1.0.1

* Provide fancy agent to `wget` and `lynx` command.
* Fix wrong URL of `rss` feed.
* Use `set -u` to avoid unbound variable.
* Fix display charset of `lynx` program. See #3.

## v1.0.0

* The first public version.
