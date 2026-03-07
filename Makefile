SHELL := /bin/bash
.SHELLFLAGS := -eo pipefail -c

PROJECT := TrustCare.xcodeproj
SCHEME := TrustCare
CONFIGURATION := Debug
SIM_DEVICE ?= iPhone 15

.PHONY: verify verify-local localization-check ontology-audit taxonomy-v21-validate taxonomy-v21-build taxonomy-v21-import-locale taxonomy-v21-import-locale-dry-run xcode-build

verify: localization-check ontology-audit taxonomy-v21-validate xcode-build

verify-local: localization-check taxonomy-v21-validate xcode-build

localization-check:
	swift tools/localization_check.swift

ontology-audit:
	swift tools/ontology_audit.swift

taxonomy-v21-validate:
	swift tools/taxonomy_v21_validate.swift

taxonomy-v21-build:
	python3 scripts/taxonomy_v21_build.py

taxonomy-v21-import-locale:
	@if [[ -z "$(LOCALE)" || -z "$(INPUT)" ]]; then \
		echo "Usage: make taxonomy-v21-import-locale LOCALE=<locale> INPUT=<path-to-json>"; \
		exit 1; \
	fi
	python3 scripts/taxonomy_v21_import_locale.py --locale "$(LOCALE)" --input "$(INPUT)"

taxonomy-v21-import-locale-dry-run:
	@if [[ -z "$(LOCALE)" || -z "$(INPUT)" ]]; then \
		echo "Usage: make taxonomy-v21-import-locale-dry-run LOCALE=<locale> INPUT=<path-to-json>"; \
		exit 1; \
	fi
	python3 scripts/taxonomy_v21_import_locale.py --locale "$(LOCALE)" --input "$(INPUT)" --dry-run

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
