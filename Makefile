fmt:
	echo "formatting"
	stylua lua/ 

lint:
	echo "linting"
	luacheck lua/ --globals vim

unit:
	@echo "Run unit tests..."
	nvim --headless --noplugin -c 'packadd plenary.nvim' -c "PlenaryBustedDirectory lua/spec"
	@echo
