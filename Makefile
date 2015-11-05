.PHONY: docs
pod_clean:
	rm -rf Pods Podfile.lock
docs:
	jazzy
