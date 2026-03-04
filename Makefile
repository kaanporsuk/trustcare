SHELL := /bin/bash
.SHELLFLAGS := -eo pipefail -c

PROJECT := TrustCare.xcodeproj
SCHEME := TrustCare
CONFIGURATION := Debug
SIM_DEVICE ?= iPhone 15

.PHONY: verify verify-local localization-check ontology-audit xcode-build

verify: localization-check ontology-audit xcode-build

verify-local: localization-check xcode-build

localization-check:
	swift tools/localization_check.swift

ontology-audit:
	swift tools/ontology_audit.swift

xcode-build:
	DEST_NAME="$$(xcrun simctl list devices available | grep -o "iPhone 15" | head -n1)"; \
	if [[ -z "$$DEST_NAME" ]]; then \
		DEST_NAME="$$(xcrun simctl list devices available | grep -o "iPhone 14" | head -n1)"; \
	fi; \
	if [[ -z "$$DEST_NAME" ]]; then \
		echo "No iPhone 15/14 simulator available. Falling back to generic iOS Simulator destination."; \
		xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination 'generic/platform=iOS Simulator' build; \
	else \
		echo "Using simulator: $$DEST_NAME"; \
		xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination "platform=iOS Simulator,name=$$DEST_NAME" build; \
	fi
