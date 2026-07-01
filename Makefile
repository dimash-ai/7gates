# Verification gates for the two-agent pipeline.
#
# `make verify` runs all gates and is what Claude runs at Stage 5 and what the final
# handoff records at Stage 6. Each sub-target below is a STUB: it echoes a TODO and exits 0.
# Replace the `@echo "TODO ..."` line in each target with the real command for your stack.

.PHONY: test lint typecheck build verify

test:
	@echo "TODO(test): plug in your test runner here, e.g. 'pytest -q' / 'npm test' / 'go test ./...'"
	@exit 0

lint:
	@echo "TODO(lint): plug in your linter here, e.g. 'ruff check .' / 'eslint .' / 'golangci-lint run'"
	@exit 0

typecheck:
	@echo "TODO(typecheck): plug in your type checker here, e.g. 'mypy .' / 'tsc --noEmit'"
	@exit 0

build:
	@echo "TODO(build): plug in your build command here, e.g. 'npm run build' / 'go build ./...'"
	@exit 0

# verify is the umbrella gate: it depends on every sub-target above and fails if any fail.
verify: test lint typecheck build
	@echo "verify: OK"
