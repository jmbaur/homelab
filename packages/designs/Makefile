.PHONY: all install clean

out ?= $(PWD)

SOURCES := src/orangepi5-mount.scad
STLS := $(foreach source,$(SOURCES),$(patsubst %.scad,%.stl,$(source)))

all: $(STLS)

install: all
	$(foreach stl,$(STLS),install -Dm0644 -t $(out) $(stl))

clean:
	$(foreach stl,$(STLS),rm -f $(stl))

%.stl: %.scad
	openscad --export-format=binstl -o $@ $<
