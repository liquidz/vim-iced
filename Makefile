.PHONY: vital test themis themis_nvim html document pip_install lint vim-lint clj-lint
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

help:
	@echo "Defined tasks:\n\
  vital         Update vital modules\n\
  test          Run following tests\n\
                - themis\n\
                - themis_nvim\n\
                - python_doctest\n\
                - bb_script_test\n\
  document      Generate document html files to target/html\n\
  lint          Run following linters\n\
                - vim-lint\n\
                - clj-lint\n\
  bin           Generate bin/iced from clj/template/iced.bash\n\
  outdated      Check dependencies are outedated or not\n\
  "

vital:
	\rm -rf autoload/vital*
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

callbag:
	vim -c ":CallbagEmbed path=./autoload/iced/callbag.vim namespace=iced#callbag" -c q

test: themis themis_nvim python_doctest bb_script_test

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis
.vim-sexp:
	git clone https://github.com/guns/vim-sexp .vim-sexp

themis: .vim-themis .vim-sexp
	./.vim-themis/bin/themis

themis_nvim:
	THEMIS_VIM=$(NVIM) ./.vim-themis/bin/themis

document: doc/vim-iced.txt
	bash scripts/html.sh
	bash scripts/asciidoctor.sh

target/bin/vint:
	mkdir -p target
	pip3 install -r requirements.txt -t ./target

lint: vim-lint clj-lint

vim-lint: target/bin/vint
	bash scripts/lint.sh

bin/clj-kondo:
	cd bin && bash ../installer/clj-kondo.sh

clj-lint: bin/clj-kondo
	./bin/clj-kondo --lint clj:test/clj

python_doctest:
	python3 -m doctest python/bencode.py

bb_script_test:
	bash scripts/bb_script_test.sh

version_check:
	bash scripts/version_check.sh

deps_check:
	bash scripts/deps_check.sh

coverage: target/bin/vint themis
	bash scripts/coverage.sh

clean:
	\rm -rf target .vim-sexp .vim-themis

clan-all: clean
	\rm -rf autoload/vital*
	\rm -f bin/iced

bin:
	clojure -A:jackin -m iced-jackin

outdated:
	clojure -A:outdated --exclude 'nrepl/nrepl'

repl:
	clojure -R:jackin:dev -m iced-repl
