

Run it using `make test` and see `bin/test.sh` for a script.

- `src` is where a set of files to be renamed is.
- `good/<testname>` is where a set of files that should be the result of that test on `src`.
- `temp` is results and also in `.gitignore`

Tests should exist for each option, and are run with --quiet by default (which probably means that there will be a --verbose at some point and the current --quiet version become default).

`test.sh --reset` will take all test results and turn them into the new standard.  This can also be called with `make testreset`.
