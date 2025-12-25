.PHONY: changelog format format-check

changelog:
	GITHUB_TOKEN=$$(gh auth token) git-cliff -o CHANGELOG.md

format:
	swiftformat .

format-check:
	swiftformat --lint .

help:
	@echo "Available commands:"
	@echo "  make changelog      Generate CHANGELOG.md using git-cliff"
	@echo "  make format         Format Swift code using SwiftFormat"
	@echo "  make format-check   Check Swift formatting without making changes"
