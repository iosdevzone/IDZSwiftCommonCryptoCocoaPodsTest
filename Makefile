.PHONY: docs build

XC=xctool
DESTINATION=-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3'

build:
	$(XC) build -scheme IDZSwiftCommonCryptoCocoaPodsTest $(DESTINATION) -workspace IDZSwiftCommonCryptoCocoaPodsTest.xcworkspace

pod_install:
	pod install --verbose
pod_clean:
	rm -rf Pods Podfile.lock
docs:
	jazzy

