MOD := freetz
PKG := callmonitor

VERSION := $(shell cat .version)
NAME := $(PKG)-$(VERSION)
ARCHIVE := $(NAME)-$(MOD).tar.bz2
BUILD := build/$(MOD)
BNAME := $(BUILD)/$(NAME)
EXTRAS := README COPYING ChangeLog

TAR := tar
TAR_OWNER := --owner=root --group=root
SHSTRIP := tools/shstrip
BUSYBOX := busybox

.PHONY: $(ARCHIVE) build clean check collect

build: $(ARCHIVE)

$(NAME)-$(MOD).tar.bz2: collect
	$(TAR) cjf $@ $(TAR_OWNER) -C $(BUILD) $(NAME) \
	    || (rm $@ && false)

collect: check
	rm -rf $(BNAME)
	mkdir -p $(BNAME)/root
	$(TAR) c --exclude=.svn -C base . | $(TAR) x -C $(BNAME)/root
	$(TAR) c --exclude=.svn -C root . |  $(TAR) x -C $(BNAME)
	$(TAR) c --exclude=.svn docs | $(TAR) x -C $(BNAME)
	$(TAR) c --exclude=.svn src | $(TAR) x -C $(BNAME)
	echo $(VERSION) > $(BNAME)/root/etc/default.$(PKG)/.version
	echo $(MOD) > $(BNAME)/root/etc/default.$(PKG)/.subversion
	cp $(EXTRAS) $(BNAME)
	./feature-dep $(BNAME)/root
	find $(BNAME)/root -type f -print0 | xargs -0 $(SHSTRIP)
	if [ -e $(BNAME)/install ]; \
	    then $(SHSTRIP) $(BNAME)/install; \
	fi

check:
	find base -name .svn -prune \
	    -or -type f -not \( -name "*.sed" -or -name "*.txt" -or -name "*.cfg" \) -print0 \
	| xargs -0 -n1 -- $(BUSYBOX) ash -n

clean:
	-rm -f $(PKG)*.tar.bz2
	-rm -rf build
