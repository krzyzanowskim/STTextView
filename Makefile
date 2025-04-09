.PHONY: changelog

changelog:
	git-cliff -o CHANGELOG.md

help:
	@echo "Available commands:"
	@echo "  make changelog    Generate CHANGELOG.md using git-cliff"
