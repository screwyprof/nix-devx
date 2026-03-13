# Hello - Go project with nix-devx
MODULE := $(shell go list -m)
BINARY := $(notdir $(MODULE))

# Build configuration
TEST_FLAGS := -race -parallel 4 -v
PACKAGES := ./...

# Coverage
COVERPKG_PACKAGES := $(shell go list $(PACKAGES) | tr '\n' ',' | sed 's/,$$//')

# Colors
OK_COLOR := \033[32;01m
NO_COLOR := \033[0m
MAKE_COLOR := \033[33;01m%-20s\033[0m

MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := all

.PHONY: help fmt lint check test coverage coverage-html build run clean all

help: ## Show this help screen
	@echo -e "$(OK_COLOR)$(BINARY)$(NO_COLOR)\n"
	@awk 'BEGIN {FS = ":.*?## "} \
	      /^[a-zA-Z_-]+:.*?## / { \
	          printf "$(MAKE_COLOR)  %s\n", $$1, $$2 \
	      }' $(MAKEFILE_LIST)

#
# Code Quality
#

fmt: ## Format Go code
	@echo -e "$(OK_COLOR)--> Formatting Go code$(NO_COLOR)"
	@gofumpt -l -w .
	@golines -w --max-len=120 .
	@gci write . -s standard -s default -s "prefix($(MODULE))"

lint: ## Run golangci-lint static analysis
	@echo -e "$(OK_COLOR)--> Running static analysis$(NO_COLOR)"
	@golangci-lint run $(PACKAGES)

test: ## Run all tests with race detection
	@echo -e "$(OK_COLOR)--> Running tests$(NO_COLOR)"
	@go test $(TEST_FLAGS) $(PACKAGES)

check: fmt lint test ## Run format, lint, and test

coverage: ## Run tests with coverage
	@echo -e "$(OK_COLOR)--> Running coverage$(NO_COLOR)"
	@rm -rf coverage && mkdir -p coverage
	@go test -v -covermode=atomic -coverprofile=coverage/coverage.out \
		-coverpkg=$(COVERPKG_PACKAGES) $(PACKAGES)
	@go tool cover -func=coverage/coverage.out | grep "total:"

coverage-html: coverage ## Generate HTML coverage report
	@go tool cover -html=coverage/coverage.out -o coverage/coverage.html
	@echo -e "$(OK_COLOR)--> Report: coverage/coverage.html (open with Live Server)$(NO_COLOR)"

#
# Build and Run
#

build: ## Build the binary
	@echo -e "$(OK_COLOR)--> Building$(NO_COLOR)"
	@go build -trimpath -o bin/$(BINARY) .

run: ## Run the application
	@go run .

#
# Maintenance
#

clean: ## Clean build artifacts
	@echo -e "$(OK_COLOR)--> Cleaning$(NO_COLOR)"
	@go clean
	@rm -rf bin/ coverage/

all: check build ## Complete workflow (check + build)
