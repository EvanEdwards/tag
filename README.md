# tag - File Tagger

version 0.0.2<img src="assets/identity/Logo.svg" width="128" align="right">

```
Usage:
  tag [options] [+tag|-tag|filename]
```

Takes a set of tags and filenames and inserts or removes them into the filenames
according to a common social standard, using square brackets.  This is useful
for organizing files and inserting hints into filenames for media identification 
by programs like Plex.

```
$ tag +OSR *.pdf   
```

Takes a directory of pdf files and tags them as being old school D&D files.

```
$ tag --field=1 +2007 -youtube The\ Guild*.mp4
```

Takes a directory full of episodes, removing the tag Youtube and adding [2007]
to the first - delimited field (typically the name of the series).



This is a working but brand new program.  See **Warning** below before picking up bad habits.  On the other hand, I am using it daily as a route toward replacing a 20+ year old 788 line awk script that automatically renames files in a predictable manner.  So I have incentive to keep improving it and will have plenty of testing.

*Important: This is for tagging* `[like this]` *in filenames, not the metadata in a file.*



## Build

If you have nim installed, simply clone and run `make`.

Also, `make clean` does the obvious and `make test` runs a (quick and dirty) test suite.

## Example of Usage

To add a tag, use `+tagname`.  To remove one, use `-tagname`.  By default, tags are added at the end of a file, before the extension.

`--clean` will do a basic cleanup of the rest of the filename, fixing extra spaces, capitalizing most words, etc.

Like Imagemagick or `find`, the entire commandline is not parsed for options and then executed*, but instead each term is considered in order.  This means that tag addition or removal (and options) only affect filenames given after them in the command line.

Consider the following example:

```
$ ls -1
File1 
File2 [hello].txt
File3 [hello][moon]
$ tag File1 +world "File2 [hello]" -moon "File3 [hello][moon]"
╭ File2 [hello].txt
╰ File2 [hello][world].txt
╭ File3 [hello][moon]
╰ File3 [hello][world]
$ ls -1
File1
File2 [hello][world].txt
File3 [hello][world]
```


\* Yes, I know the entire commandline is parsed first regardless of application.  I mean that *logically* they don't work that way, and neither does tag.


## Warning

Be warned, this is my first nim code, and I wrote this in part
to learn nim.  I am absolutely sure this is the kind of thing
where I will return, less ignorant, and be merciless in my 
review of my current (former?) self's choices.  

That's partially why it is a monolithic block with some iffy 
structure.  I learned as I went.  But the code does work and 
I have some ideas on extending it.  

The main tag.nim file literally started with the first example from the Nim Tutorial copied and pasted into it.  After an hour or so, I had a fully working application, which speaks volumes for the quality of nim, their documentation, and online community. 

In short: this is probably not good code to learn nim from.


# TODO

TODOs are phrased affirmatively.  When they are true, they are moved to the Changelog.

- [ ] Templates can be specified in a config file.  %name has been reserved for this purpose
- [ ] When -- is used, all following arguments are processed as filenames, which allows files starting with -, +, or %.
- [ ] Templates may have programmatic values, like YYYY-dd-mm or similar.
- [ ] A manpage is available.
- [ ] --force allows overwrite.
- [ ] --nodup allows overwrite iff both files are identical.
- [ ] --dry-run shows changes but does not actually rename files.
- [ ] Plugin system to autotag from metadata or online services.
- [ ] `--split=-` for alternate field definitions.
- [ ] `--clean=1,3` only cleans certain fields

# Changelog

## 2022-11-21
- Targets delimited segments with `--field=1`, like `The Guild - 01x04 - Cheesybeards.mp4` to `The Guild [2007] - 01x04 - Cheesybeards.mp4`  Defaults to `1` if `--field` is specified.
- Initial work toward fields.
- `--clean` passes all tests.
- `--clean` does a capitalization (with some articles excepted) of the filename.  Tags are left entirely alone.
- If a file has a numerical suffix, a la `(1).txt`, tags are placed prior to it.

## 2022-11-20
- Logo and Icon created (per my personal standards).
- Makefile and testing framework set up.
- `--help` shows basic help.
- `--quiet` silences normal output. Probably not the best method for options.
- Initial code, works and handles basic errors.