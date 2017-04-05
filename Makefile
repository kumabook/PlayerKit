XCODEBUILD:=xcodebuild

default: build test

build:
	$(XCODEBUILD) -scheme PlayerKit-iOS
	$(XCODEBUILD) -scheme PlayerKit-macOS
	$(XCODEBUILD) -scheme PlayerKit-tvOS

test:
	$(XCODEBUILD) -scheme PlayerKit-macOS test
coverage:
	slather coverage --html --scheme PlayerKit-macOS ./PlayerKit.xcodeproj

clean:
	$(XCODEBUILD) -scheme PlayerKit-iOS clean
	$(XCODEBUILD) -scheme PlayerKit-macOS clean
	$(XCODEBUILD) -scheme PlayerKit-tvOS clean
archive:
	carthage build --no-skip-current
	carthage archive PlayerKit

.PHONY: test clean default
