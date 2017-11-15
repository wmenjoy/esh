SCRIPT_NAME := esh

DESTDIR := /
prefix := /usr/local
bindir := $(prefix)/bin

SED := sed
SHA1SUM := sha1sum

ifeq ($(shell uname -s),Darwin)
	SED := gsed
	SHA1SUM := shasum -a 1
endif

#: Update version in the script and README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" $(SCRIPT_NAME)
	$(SED) -E -i "s/^(:version:).*/\1 $(VERSION)/" README.adoc

#: Clean all temporary files.
clean:
	find tests -name '*.err' -delete

#: Install the script into $DESTDIR.
install:
	mkdir -p $(DESTDIR)$(bindir)
	install -m 755 $(SCRIPT_NAME) $(DESTDIR)$(bindir)/$(SCRIPT_NAME)

#: Update variable :script-sha1: in README.adoc with SHA1 checksum of the script.
readme-update-checksum:
	$(SED) -E -i \
		-e "s/^(:script-sha1:).*/\1 $(shell $(SHA1SUM) $(SCRIPT_NAME) | cut -d ' ' -f 1)/" \
		README.adoc

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version readme-update-checksum
	test -n "$(VERSION)"  # $$VERSION
	git add .
	git commit -m "Release version $(VERSION)"
	git tag -s v$(VERSION) -m v$(VERSION)

#: Run tests.
test:
	@./tests/run-tests

#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_LIST) \
		| while read label desc; do printf '%-30s %s\n' "$$label" "$$desc"; done

.check-git-clean:
	@test -z "$(shell git status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: bump-version clean install readme-update-checksum release test help \
	.check-git-clean
