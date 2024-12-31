.PHONY: fmt lint test

fmt:
	echo "formatting"
	stylua lua/ 

lint:
	echo "linting"
	luacheck lua/ --globals vim

test:
	@echo "Run tests..."
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/gotest { minimal_init = './scripts/minimal_init.vim' }"
	@echo
