.PHONY: vital test themis lint clean

PLUGIN_NAME = iced
VITAL_MODULES = Data.List \
				Data.String \
				Vim.Buffer \
				Vim.BufferManager \
				Web.HTTP

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

