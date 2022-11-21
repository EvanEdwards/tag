#[
tag

TODO - Templates from a config file
]#

import std/re, std/os, std/strformat, std/strutils

#### Set up some basic data. 

type
  appDetails = object
    name: string
    description: string
    version: string
    author: string
    url: string
    help: string


var app = appDetails(name: "tag",
              description: "File Tagger",
              version: "0.0.1", 
              author: "Evan Edwards <evan@cheshirehall.net>",
              url: "http://github.com/EvanEdwards/tag")

app.help= fmt"""
{app.name} - {app.description} (version {app.version})

Usage:
  tag [options] [+tag|-tag|filename]

Options, tags, and filenames are positional.  So:

  File1 +world "File2 [hello]" -moon "File3 [hello][moon]" --help File4

Results in: 
  
  "File1" "File2 [hello][world]" "File3 [hello][world]"

…followed by this help.  File4 is never even considered.

  --help      This help.
  --quiet     Only display errors.
  --clean     Do extra cleanup on the filename (spacing, capitals, etc).

---
by {app.author} {app.url}"""


#### The four core functions.  
# All take a filename and return a new filename except tagExists

proc tagExists(name: string, tag: string): bool =
  return name.match(re(fmt"\[\s*{tag}\s*\]"))

proc tagClean(oname: string): string =
  var nname: string = oname;
  nname = oname.
    replacef( re"\[\s+",   "["  ).
    replacef( re"\s+\]",   "]"  ).
    replacef( re"\]\s*",   "] " ).
    replacef( re"\s*\[",   " [" ).
    replacef( re"\]\s+\.", "]." ).
    replacef( re"\[([^]]+)\s\s+([^]]+)\]", "[$1 $2]").
    replacef( re"\]\s*\[", "][" )
  return nname

proc tagRm(oname: string, tag: string): string =
  var nname: string = oname;
  nname = oname.replacef(re(fmt"\[\s*{tag}\s*\]"), "").tagClean()
  return nname

proc tagAdd(oname: string, tag: string): string =
  var nname: string = oname.tagRm(tag);
  # We do it this way so we can have an option in the future to remove and readd tags at the end.
  if not oname.tagExists(tag):
    if oname.replace(re".*/","").contains("."):
      nname = nname.replacef(re"(\.?[^/.]*$)"," [" & tag & "]$1").tagClean()
    else:
      nname = nname.replacef(re"$"," [" & tag & "]").tagClean()
  return nname


#### Meh.  Is this the best way?

type
  opts = object
    quiet: bool
    clean: bool

var opt = opts( quiet: false, clean: false )


#### Hereafter lies the main loop.

var tagsAdd: seq[string]
var tagsRm:  seq[string]
# TODO This is where we'll do an option to forego positional tags
#var files:  seq[string]

for arg in commandLineParams():
  case arg[0]:
  of '+': 
#    echo "Add " & arg[1..^1]
    tagsAdd.add(arg[1..^1])
  of '-': 
#    echo "Rm  " & arg[1..^1]
    if arg[1] == '-':  # TODO Probably should break out
      var key = arg[2..^1].replacef(re"[=:].*$","")
      var val = arg[2..^1].replacef(re"^[^=:]*[=:]","")
      if val == arg: val=""

      case key:
      of "quiet": 
        opt.quiet=true 
      of "clean": 
        opt.clean=true 
      of "help":
        echo app.help
        quit(0)
      else: echo "Unknown option: " & key

    else:
      tagsRm.add(arg[1..^1])
  of '%': 
    echo "Error: Formatting incomplete."  
    # TODO - This is where we will have the template system
    # tagsAdd.add(arg[1..^1])
  else: 
    if arg.fileExists(): 
      # TODO if non positional, save to files instead.
      var nname: string = arg
      for tag in tagsRm:
        nname=nname.tagRm(tag)
      for tag in tagsAdd:
        nname=nname.tagAdd(tag)
      if(arg != nname):
        if not nname.fileExists():
          moveFile(arg, nname)
          if not opt.quiet: 
            echo &"╭ {arg}\n╰ {nname}"
        else:
          if not opt.quiet: 
            echo &"╔ {arg}\n╚ SKIPPED: A file by the new name exists"
    else:
      echo &"╔ {arg}\n╚ ERROR: Not a file"

#[
for kind, key, val in getopt()
  case key[0]


Y - Year
i - iso date
I - iso date and time


]#