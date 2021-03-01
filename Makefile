PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max

default: test

test:
	xcodebuild test \
		-scheme AppRouter \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild \
		-scheme LinkDemo \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild \
		-scheme SheetDemo \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild \
		-scheme TabDemo \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild \
		-scheme TabLinkDemo \
		-destination platform="$(PLATFORM_IOS)"

format:
	swift format --in-place --recursive \
		./Examples ./Package.swift ./Sources ./Tests

.PHONY: format
