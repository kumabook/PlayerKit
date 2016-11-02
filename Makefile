XCODEBUILD:=xcodebuild

default: build test

build:
	$(XCODEBUILD) -scheme PlayerKit-iOS
	$(XCODEBUILD) -scheme PlayerKit-macOS
	$(XCODEBUILD) -scheme PlayerKit-tvOS

test:
	$(XCODEBUILD) -scheme PlayerKit-macOS test

clean:
	$(XCODEBUILD) -scheme PlayerKit-iOS clean
	$(XCODEBUILD) -scheme PlayerKit-macOS clean
	$(XCODEBUILD) -scheme PlayerKit-tvOS clean

.PHONY: test clean default
