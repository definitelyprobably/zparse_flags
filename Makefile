SHELL = /bin/sh

ZPARSE_FLAGS = zparse_flags
LOADER_SCRIPT = $(ZPARSE_FLAGS)
TEMPLATE = $(ZPARSE_FLAGS).skeleton
SCRIPT = $(ZPARSE_FLAGS).zsh
VERSION != grep 'zparse_flags_version=' $(SCRIPT) | sed 's/zparse_flags_version=//'
SCRIPT_VERSIONED = $(ZPARSE_FLAGS).$(VERSION)

TAR = tar
TAR_FLAGS = cJhf
TAR_TARGET = $(ZPARSE_FLAGS)-$(VERSION).tar.xz
RM = rm -f --
RM_R = rm -fr --
MKDIR = mkdir -p --
LN_S = ln -s --
CP = cp -f --

SYSDIR ?= /usr/local/share/$(ZPARSE_FLAGS)
LOCALDIR ?= ~/.zsh/plugins/$(ZPARSE_FLAGS)

.PHONY: all help
all: help
help:
	@echo "please specify a target:"
	@echo "help               - print this help message."
	@echo "install            - print install info."
	@echo "install-system     - install the files system-wide."
	@echo "install-local      - install the files locally."
	@echo "tarball            - make a package tarball."
	@echo "clean              - remove the package tarball."
	@echo "version            - print zparse_flags version number."


.PHONY: install install-system install-local
install:
	@echo "to install system-wide (in $(SYSDIR)), run:"
	@echo "     $$ make install-system"
	@echo "to install locally (in $(LOCALDIR)), run:"
	@echo "     $$ make install-local"
	@echo "the paths can be modified as follows:"
	@echo "     $$ make install-system SYSDIR=/path"
	@echo "     $$ make install-local LOCALDIR=/path"


install-system:
	$(MKDIR) $(SYSDIR)
	$(CP) $(LOADER_SCRIPT) $(SYSDIR)
	$(CP) $(TEMPLATE) $(SYSDIR)
	$(CP) $(SCRIPT) $(SYSDIR)/$(SCRIPT_VERSIONED)

install-local:
	$(MKDIR) $(LOCALDIR)
	$(CP) $(LOADER_SCRIPT) $(LOCALDIR)
	$(CP) $(TEMPLATE) $(LOCALDIR)
	$(CP) $(SCRIPT) $(LOCALDIR)/$(SCRIPT_VERSIONED)


.PHONY: tarball
$(TAR_TARGET): tarball
tarball:
	$(MKDIR) $(ZPARSE_FLAGS)-$(VERSION)
	for i in $(SCRIPT) $(LOADER_SCRIPT) $(TEMPLATE) Makefile check ; do \
		$(LN_S) ../$$i $(ZPARSE_FLAGS)-$(VERSION)/$$i ;\
	done
	$(TAR) $(TAR_FLAGS) $(TAR_TARGET) -- $(ZPARSE_FLAGS)-$(VERSION)
	$(RM_R) $(ZPARSE_FLAGS)-$(VERSION)

.PHONY: clean
clean:
	$(RM_R) $(ZPARSE_FLAGS)-*.tar.* $(ZPARSE_FLAGS)-$(VERSION)

.PHONY: version
version:
	@echo $(VERSION)
