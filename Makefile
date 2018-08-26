.PHONY: all vital test themis lint clean ancient

PLUGIN_NAME = iced
VITAL_MODULES = Data.Dict \
		Data.List \
		Data.String \
		Locale.Message \
		Vim.Buffer \
		Vim.BufferManager \
		Vim.Message \
		Web.HTTP

all: vital test

vital:
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

test: themis lint

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis

themis: .vim-themis
	./.vim-themis/bin/themis

lint:
	find . -name "*.vim" | grep -v vital | grep -v .vim-themis | xargs vint

clean:
	/bin/rm -rf autoload/vital*

ancient:
	clojure -A:ancient

