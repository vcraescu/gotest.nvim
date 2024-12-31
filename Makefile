.PHONY: fmt lint test

fmt:
	@echo "Formatting..."
	stylua lua/ tests/gotest/*.lua
	@echo

lint:
	@echo "Linting..."
	luacheck lua/ tests/gotest/*.lua --globals vim
	@echo

test:
	@echo "Run tests..."
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/gotest { minimal_init = './scripts/minimal_init.vim' }"
	@echo
