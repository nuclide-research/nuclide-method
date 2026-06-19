# NuClide Method - verb layer.
# Run `make` or `make help` for the target list.

.DEFAULT_GOAL := help

# Public Go tools, installed via `go install`. Override on the command line if needed.
TOOLS ?= \
	github.com/nuclide-research/aimap@latest \
	github.com/nuclide-research/herald@latest \
	github.com/nuclide-research/JAXEN@latest \
	github.com/nuclide-research/VisorPlus@latest \
	github.com/nuclide-research/tiptoe@latest \
	github.com/nuclide-research/VisorLog@latest \
	github.com/nuclide-research/VisorScuba@latest \
	github.com/nuclide-research/VisorGoose@latest \
	github.com/nuclide-research/visor/cmd/visor@latest \
	github.com/nuclide-research/VisorBishop/cmd/visorbishop@latest \
	github.com/nuclide-research/VisorGraph/cmd/visorgraph@latest \
	github.com/nuclide-research/VisorCorpus/cmd/visorcorpus@latest \
	github.com/nuclide-research/VisorRAG/cmd/visor@latest

# IP-list argument for `make chain IPS=path/to/ips.txt`.
IPS ?=

.PHONY: help install bootstrap chain audit lint

help: ## Show this help.
	@echo "NuClide Method - make targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Example: make chain IPS=ips.txt"

install: ## go install the public NuClide tools (prints the list).
	@echo "Installing public NuClide tools:"
	@for tool in $(TOOLS); do echo "  $$tool"; done
	@for tool in $(TOOLS); do \
		echo "==> go install $$tool"; \
		go install "$$tool" || exit 1; \
	done
	@echo "Done. Ensure your Go bin dir is on PATH (go env GOBIN, or go env GOPATH)/bin)."

bootstrap: ## Run the environment bootstrap script.
	@./bootstrap.sh

chain: ## Run the assessment chain over an IP list: make chain IPS=ips.txt
	@if [ -z "$(IPS)" ]; then \
		echo "error: pass an IP list, e.g. make chain IPS=ips.txt"; exit 2; \
	fi
	@./chain/run-chain.sh "$(IPS)"

audit: ## Run the local boundary checks that mirror CI.
	@./scripts/boundary-audit.sh

lint: ## shellcheck the scripts and sweep for em-dashes.
	@echo "==> shellcheck"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name '*.sh' -not -path './.git/*' -print0 | xargs -0 -r shellcheck; \
	else \
		echo "shellcheck not installed; skipping (CI runs it on push)"; \
	fi
	@echo "==> em-dash sweep"
	@if grep -rnP '\x{2014}' --include='*.md' --include='*.sh' --include='*.cff' \
		--exclude-dir='.git' . ; then \
		echo "FAIL: em-dash found above. Replace with a comma, a period, or a spaced hyphen."; \
		exit 1; \
	else \
		echo "clean: no em-dashes."; \
	fi
