.PHONY: docs build

XC=xcodebuild
XCP=xcpretty

IOS_VERSION=10.0
DESTINATION=-destination 'platform=iOS Simulator,name=iPhone 6,OS=$(IOS_VERSION)'

build:
	$(XC) build -scheme IDZSwiftCommonCryptoCocoaPodsTest $(DESTINATION) -workspace IDZSwiftCommonCryptoCocoaPodsTest.xcworkspace | $(XCP)

pod_install:
	pod repo update
	pod install --verbose
pod_clean:
	rm -rf Pods Podfile.lock
docs:
	jazzy

