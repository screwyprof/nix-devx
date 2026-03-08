.PHONY: help test fmt lint clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

test: ## Run integration tests (requires bats)
	@command -v bats >/dev/null || { echo "bats not found. Install with: nix-shell -p bats"; exit 1; }
	bats dev/tests/templates.bats

fmt: ## Format all Nix files
	nix fmt

lint: ## Run linters (statix, deadnix)
	nix flake check

check: test fmt lint ## Run all checks (tests, formatting, linting)

clean: ## Remove build artifacts
	rm -rf result
