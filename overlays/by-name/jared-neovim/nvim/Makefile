CUR_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

FNL_SRCS := $(wildcard plugin/*.fnl) $(wildcard after/plugin/*.fnl) $(wildcard ftplugin/*.fnl)
LUA_SRCS := $(patsubst %.fnl,%.lua,$(FNL_SRCS))

.PHONY: all install clean

all: $(LUA_SRCS)

install: $(LUA_SRCS)
	$(foreach lua_src,$(LUA_SRCS),install -Dm0644 $(lua_src) $(out)/$(lua_src);)

clean:
	rm -f $(LUA_SRCS)

%.lua: %.fnl
	fennel --compile $< > $@
