.PHONY: all install clean

out ?= $(PWD)

SOURCES := $(wildcard src/*.scad)
STLS := $(foreach source,$(SOURCES),$(patsubst %.scad,%.stl,$(source)))

all: $(STLS)

install: all
	install -Dm0644 -t $(out) $(STLS)

clean:
	rm -f $(STLS)

%.stl: %.scad
	openscad --export-format=binstl -o $@ $<
