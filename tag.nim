
import std/re, std/os, std/strformat, std/strutils, std/sequtils, std/sugar

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
              version: "0.0.2", 
              author: "Evan Edwards <evan@cheshirehall.net>",
              url: "http://github.com/EvanEdwards/tag")

app.help= fmt"""
{app.name} - {app.description} (version {app.version})

Usage:
  tag [options] [+tag|-tag|filename]

Takes a set of tags and filenames and inserts or removes them into the filenames
according to a common social standard, using square brackets.  This is useful
for organizing files and inserting hints into filenames for media identification 
by programs like Plex.

  $ tag +OSR *.pdf   

    Takes a directory of pdf files and tags them as being old school D&D files.

  $ tag --field=1 +2007 -youtube The\ Guild*.mp4  

    Takes a directory full of episodes, removing the tag Youtube and adding [2007]
    to the first - delimited field (typically the name of the series).


# Options

  --field     Add tags to first field.
  --field=n   Add tags to field n, or the last field if n > number of fields.
  --clean     Do extra cleanup on the filename (spacing, capitals, etc).

  --help      This help.
  --quiet     Only display errors.
  --verbose   Show more information when run.


# Position Sensitive

Options, tags, and filenames are positional.  So:

  File1 +world "File2 [hello]" -moon "File3 [hello][moon]" --help File4

Results in: 
  
  "File1" "File2 [hello][world]" "File3 [hello][world]"

…followed by this help.  File4 is never even considered, as --help ends the run.


---
by {app.author} {app.url}"""


#### A global object. Meh. Is this the best way? Too new to nim to know the best practice here.

type
  opts = object
    quiet: bool
    verbose: bool
    clean: bool
    deepclean: bool
    force: bool
    dryrun: bool
    field: int

var opt = opts( quiet: false, verbose: false, clean: false, deepclean: false, force: false, dryrun: false, field: 0 )


#### The four core functions.  
# All take a filename and return a new filename except tagExists

type
  fileName = object
    path: string
    field: seq[string]

proc tagUnpack(name: string): fileName =
  # Path if it exists  
  var p: string 
  if name.contains("/"):
    p = name.replacef(re"/+[^/]*$","/")

  # Make a seq of basename with a empty [0] and trim all elements
  var s: seq[string] = @[""]
  var inTag: bool = false;
  var seqStart: int = 0
  for i, c in name:
    if(c=='/'): 
      s = @[""]
      seqStart=i
    if c=='[': inTag=true
    if c==']': inTag=false
    if c=='-' and inTag==false: 
      s.add(name[seqStart..i-1])
      seqStart=i+1

  s.add(name[seqStart..^1])

  s=s.map(x => strip(x))

  # Move ext to 0, remove from end
  if s[^1].contains("."):
    s[0] = s[^1].findAll(re"(?:\(\d+\))?\.[^.]*$")[0]
    s[^1] = s[^1].replacef(re"(?:\(\d+\))?\.?[^/.]*$","")

  return fileName(path: p, field: s)


proc tagPack(name: fileName): string =
  return name.path & name.field[1..^1].join(" - ") & name.field[0]


#proc tagExists(name: string, tag: string): bool =
#  return name.match(re(fmt"\[\s*{tag}\s*\]"))

proc tagClean(name: string): string =

  var oname:    string = name
  var nname:    string = oname.replacef(re".*/","")
  var dirname:  string = ""

  if(oname.contains("/")):
    oname = oname.replacef(re".*/","")
    dirname = name.replacef(re"/+[^/]*$","/")

  nname = oname.
    replacef( re"\[\s+",   "["  ).
    replacef( re"\s+\]",   "]"  ).
    replacef( re"\]\s*",   "] " ).
    replacef( re"\s*\[",   " [" ).
    replacef( re"\]\s+\.", "]." ).
    replacef( re"\[([^]]+)\s\s+([^]]+)\]", "[$1 $2]").
    replacef( re"\]\s*\[", "][" ).
    strip()

# Okay, a lot of this could be replaced if a replace could use \U.  Maybe it can.  But this is what I did.

  if opt.clean:
    nname = nname.splitWhitespace().join(" ")

    # Capitalize words, but leave everything in tags alone
    var nextCap:  bool = true
    var inTag:    bool = false
    for i, c in @nname:
      if c == '[':
        inTag=true
        continue
      if c == ']':
        inTag=false
        nextCap=false
        continue
      if inTag:
        continue
      if nextCap and c.isAlphaNumeric:
        nname[i] = c.toUpperAscii()
        nextCap=false
      if c == ' ': nextCap = true

    # English (and a touch of Spanish) title-casing
    for word in @["a","an","and","at","by","for","from","is","in","of","on","or","the","to","with","de","los","las"]:
      nname = nname.replaceWord(word.capitalizeAscii(), word)
      
    var n: fileName = nname.tagUnpack()
    for i, s in n.field:   # It's little things in nim that I am learning.  Like why map doesn't work here.
      n.field[i]=s.capitalizeAscii()
    n.field[0]=n.field[0].toLower()
    nname = n.tagPack()

  return dirname & nname


proc tagRm(oname: string, tag: string): string =
  var nname: string = oname;
  nname = oname.replacef(re(fmt"\[\s*{tag}\s*\]"), "").tagClean()
  return nname


proc tagAdd(oname: string, tag: string): string =
  # We do it this way so we can have an option in the future to remove and readd tags at the end.
  var name: fileName = oname.tagRm(tag).tagUnpack()

  # Okay, now add the tag to the field, or the last one.
  if(opt.field>0):
    try: 
      name.field[opt.field] = fmt"{name.field[opt.field]} [{tag}]"
    except: 
      name.field[^1] = fmt"{name.field[^1]} [{tag}]"
  else:
    name.field[^1] = fmt"{name.field[^1]} [{tag}]"

  return tagPack(name).tagClean()



#### Hereafter lies the main loop.

var tagsAdd: seq[string]
var tagsRm:  seq[string]
# TODO This is where we'll do an option to forego positional tags
#var files:  seq[string]

# Load args with commandline, or if nothing, --help
var args: seq[string] = @["--help"]
if(paramCount()>0):
  args=commandLineParams()

for arg in args:
  case arg[0]:
  of '+': 
    if(opt.verbose): echo "Add " & arg[1..^1]
    tagsAdd.add(arg[1..^1])
  of '-': 
    if arg[1] == '-':  # TODO Probably should break out
      var key = arg[2..^1].replacef(re"[=:].*$","")
      var val = arg[2..^1].replacef(re"^[^=:]*[=:]","")
      if val == arg: val=""

      case key:
      of "quiet": 
        opt.quiet=true 
      of "verbose": 
        opt.verbose=true 
      of "clean": 
        opt.clean=true 
      of "deepclean": 
        opt.deepclean=true 
      of "force": 
        opt.force=true 
      of "dry-run": 
        opt.dryrun=true     
      of "field": 
        opt.field= (try: parseInt(val)  except: 1)
      of "help":
        echo app.help
        quit(0) # Not sure why, but the manual recommends doAssert() over quit(0)
      else: echo "Unknown option: " & key

    else:
      if(opt.verbose): echo "Rm  " & arg[1..^1]
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

