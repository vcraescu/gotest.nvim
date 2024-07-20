fmt:
	echo "formatting"
	stylua lua/ 

lint:
	echo "linting"
	luacheck lua/ --globals vim
