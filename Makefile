.PHONY: build test app run install clean

build:
	swift build

test:
	swift test

app:
	./scripts/build-app.sh release

run:
	./scripts/build-app.sh debug >/dev/null && open build/CleanMac.app

install: app
	rm -rf /Applications/CleanMac.app
	cp -R build/CleanMac.app /Applications/

clean:
	rm -rf .build build
