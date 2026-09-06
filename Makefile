.PHONY: test test-ocaml test-global validate

validate:
	devcontainer features test --skip-scenarios --skip-duplicated -f ocaml -i debian:bookworm .

test-ocaml:
	devcontainer features test -f ocaml .

test-global:
	devcontainer features test --global-scenarios-only .

test: test-ocaml test-global
