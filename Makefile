.PHONY: all vital test themis themis_nvim html document pip_install lint clj-lint
.PHONY: python_doctest bb_script_test version_check deps_check
.PHONY: clean clean-all bin outdated repl

PWD=$(shell pwd)
NVIM=$(shell which nvim)

PLUGIN_NAME = iced
VITAL_MODULES = \
		Async.Promise \
		Data.Dict \
		Data.List \
		Data.String \
		Locale.Message \
		Vim.Buffer \
		Vim.BufferManager \
		Vim.Message

all: vital bin test

vital:
	\rm -rf autoload/vital*
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

test: themis lint python_doctest version_check deps_check

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis
.vim-sexp:
	git clone https://github.com/guns/vim-sexp .vim-sexp

themis: .vim-themis .vim-sexp
	./.vim-themis/bin/themis

themis_nvim:
	THEMIS_VIM=$(NVIM) ./.vim-themis/bin/themis

html: doc/vim-iced.txt
	bash scripts/html.sh

document:
	bash scripts/asciidoctor.sh

pip_install:
	sudo pip3 install -r requirements.txt

lint:
	bash scripts/lint.sh

clj-lint:
	clj-kondo --lint clj:test/clj

python_doctest:
	python3 -m doctest python/bencode.py

bb_script_test:
	bash scripts/bb_script_test.sh

version_check:
	bash scripts/version_check.sh

deps_check:
	bash scripts/deps_check.sh

coverage: themis
	bash scripts/coverage.sh

clean:
	\rm -rf target .vim-sexp .vim-themis

clan-all: clean
	\rm -rf autoload/vital*
	\rm -f bin/iced

bin:
	clojure -A:jackin -m iced-jackin

outdated:
	clojure -A:outdated

repl:
	clojure -R:jackin:dev -m iced-repl
