.PHONY: all install clean

out ?= $(PWD)

DESIGNS := \
	   anker-usb-mount \
	   congatec-mount \
	   cti-smarc-mount \
	   de10nano-mount \
	   headphone-holder \
	   imx8mp-evk-mount \
	   orangepi5-mount \
	   ultra96-mount \

SOURCES := $(foreach design,$(DESIGNS),src/$(design).scad)
STLS := $(foreach source,$(SOURCES),$(patsubst %.scad,%.stl,$(source)))

all: $(STLS)

install: all
	install -Dm0644 -t $(out) $(STLS)

clean:
	rm -f $(STLS)

%.stl: %.scad
	openscad --export-format=binstl -o $@ $<
