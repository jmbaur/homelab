FNL_SRCS := $(wildcard plugin/*.fnl) $(wildcard after/plugin/*.fnl) $(wildcard ftplugin/*.fnl)
LUA_SRCS := $(patsubst %.fnl,%.lua,$(FNL_SRCS))

.PHONY: all clean

all: $(LUA_SRCS)

clean:
	rm -f $(LUA_SRCS)

%.lua: %.fnl
	fennel --compile $< > $@
