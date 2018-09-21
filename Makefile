.PHONY: all vital test themis lint clean ancient aspell circleci

PLUGIN_NAME = iced
VITAL_MODULES = Data.Dict \
		Data.List \
		Data.String \
		Locale.Message \
		Vim.Buffer \
		Vim.BufferManager \
		Vim.Message

all: vital test

vital:
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

test: themis lint

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis
.vim-sexp:
	git clone https://github.com/guns/vim-sexp .vim-sexp

themis: .vim-themis .vim-sexp
	./.vim-themis/bin/themis --runtimepath ./.vim-sexp --runtimepath ./test/helper

lint:
	find . -name "*.vim" | grep -v vital | grep -v .vim-themis | grep -v .vim-sexp | xargs vint

clean:
	/bin/rm -rf autoload/vital*

ancient:
	clojure -A:ancient

aspell:
	aspell -d en -W 3 -p ./.aspell.en.pws check README.md
	aspell -d en -W 3 -p ./.aspell.en.pws check README.adoc
	aspell -d en -W 3 -p ./.aspell.en.pws check doc/vim-iced.txt

circleci: _circleci-lint _circleci-test
_circleci-lint:
	circleci build --job lint
_circleci-test:
	\rm -rf .vim-sexp
	circleci build --job test
