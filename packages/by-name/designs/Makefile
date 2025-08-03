.PHONY: all install clean

out ?= $(PWD)

DESIGNS := orangepi5-mount \
	   anker-usb-mount \
	   headphone-holder \
	   de10nano-mount \

SOURCES := $(foreach design,$(DESIGNS),src/$(design).scad)
STLS := $(foreach source,$(SOURCES),$(patsubst %.scad,%.stl,$(source)))

all: $(STLS)

install: all
	install -Dm0644 -t $(out) $(STLS)

clean:
	rm -f $(STLS)

%.stl: %.scad
	openscad --export-format=binstl -o $@ $<
