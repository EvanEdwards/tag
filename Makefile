

all: tag

tag: tag.nim
	nim c -d:release tag.nim && strip tag


####################################
.PHONY: clean test

clean:
	-rm tag
	-rm -R test/temp

test: tag
	@bin/test.sh
