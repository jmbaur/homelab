CHICKEN ?= chicken
CHICKEN_PREFIX ?= $(abspath $(dir $(shell command -v $(CHICKEN)))/..)
CHICKEN_FLAGS ?= -optimize-level 2 -debug-level 1

CFLAGS ?= -O2
CPPFLAGS += -DHAVE_CHICKEN_CONFIG_H -DC_ENABLE_PTABLES -I$(CHICKEN_PREFIX)/include/chicken
LDFLAGS += -L$(CHICKEN_PREFIX)/lib
LDLIBS += -lchicken -lm

PREFIX ?= $(out)
PROGRAMS ?= copy homelab-backup-recv homelab-garage-door macgen networkd-dhcpv6-client-prefix nix-key nixos-kexec pb pomo swaybar-status

MAKEFLAGS += --no-builtin-rules

.PHONY: all install clean
.SECONDARY: $(PROGRAMS:=.c)

all: $(PROGRAMS)

# Embedded at compile time.
homelab-garage-door.c: garage-door.html

homelab-backup-recv: homelab-backup-recv.h

%.c: %.scm
	$(CHICKEN) $< -output-file $@ $(CHICKEN_FLAGS)

%: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fno-strict-aliasing -fwrapv $< -o $@ $(LDFLAGS) $(LDLIBS)

install: $(PROGRAMS)
	install -Dm755 -t $(DESTDIR)$(PREFIX)/bin $^

clean:
	rm -f $(PROGRAMS) $(PROGRAMS:=.c)
