

Run it using `make test` and see `bin/test.sh` for a script.

- `_src` is where a set of files to be renamed is.
- `_good/<testname>` is where a set of files that should be the result of that test on `_src`.

Tests should exist for each option, and are run with --quiet by default (which probably means that there will be a --verbose at some point and the current --quiet version become default).

