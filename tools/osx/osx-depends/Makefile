BUILDDIR=/Users/Shared/xbmc-depends/osx-10.4_i386

SUBDIRS = \
	libsndfile

.PHONY: setup $(SUBDIRS)

all: setup $(SUBDIRS)

setup:
	mkdir -p $(BUILDDIR)/bin
	mkdir -p $(BUILDDIR)/lib
	mkdir -p $(BUILDDIR)/slib
	mkdir -p $(BUILDDIR)/share
	mkdir -p $(BUILDDIR)/include

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for d in $(SUBDIRS); do $(MAKE) -C $$d clean; done

distclean::
	for d in $(SUBDIRS); do $(MAKE) -C $$d distclean; done
	rm -rf $(BUILDDIR)
