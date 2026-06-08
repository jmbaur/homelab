CUR_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

FNL_SRCS := $(wildcard *.fnl)
LUA_SRCS := $(patsubst %.fnl,%.lua,$(FNL_SRCS))

.PHONY: all install clean

all: swaybar.lua

install: swaybar.lua
	mkdir -p $(out)/bin
	echo "#!$(LUA)" >$(out)/bin/lua-swaybar
	cat $< >>$(out)/bin/lua-swaybar
	chmod +x $(out)/bin/lua-swaybar

clean:
	rm -f $(LUA_SRCS)

%.lua: %.fnl
	fennel --compile $< > $@
