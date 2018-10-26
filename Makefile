.PHONY: all vital test themis html lint python_doctest clean bin ancient aspell repl circleci

PLUGIN_NAME = iced
VITAL_MODULES = Data.Dict \
		Data.List \
		Data.String \
		Locale.Message \
		Vim.Buffer \
		Vim.BufferManager \
		Vim.Message

all: vital bin test

vital:
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

test: themis lint python_doctest

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis
.vim-sexp:
	git clone https://github.com/guns/vim-sexp .vim-sexp
.vimdoc:
	git clone https://github.com/vim-jp/vimdoc-ja-working .vimdoc

themis: .vim-themis .vim-sexp
	./.vim-themis/bin/themis

html: doc/vim-iced.txt .vimdoc
	bash scripts/html.sh

lint:
	bash scripts/lint.sh

python_doctest:
	python3 -m doctest python/bencode.py

clean:
	/bin/rm -rf autoload/vital*
	/bin/rm -f bin/iced
	/bin/rm -rf target

bin:
	clojure -A:jackin -m iced-jackin

ancient:
	clojure -A:ancient

aspell:
	aspell -d en -W 3 -p ./.aspell.en.pws check README.adoc
	aspell -d en -W 3 -p ./.aspell.en.pws check doc/vim-iced.txt

repl:
	clojure -R:jackin:dev -m iced-repl

circleci: _circleci-lint _circleci-test
_circleci-lint:
	circleci build --job lint
_circleci-test:
	\rm -rf .vim-sexp
	\rm -rf .vimdoc
	circleci build --job test
