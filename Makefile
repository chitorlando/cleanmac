.PHONY: build test app dmg signing-dry-run run install strings clean

build:
	swift build

test:
	swift test

app:
	./scripts/build-app.sh release

dmg:
	./scripts/build-app.sh release arm64 x86_64
	./scripts/build-dmg.sh

signing-dry-run:
	./scripts/signing-dry-run.sh

run:
	./scripts/build-app.sh debug >/dev/null && open build/CleanMac.app

install: app
	rm -rf /Applications/CleanMac.app
	cp -R build/CleanMac.app /Applications/

strings:
	./scripts/sync-strings.sh

clean:
	rm -rf .build build
