PWD=$(shell pwd)
NVIM=$(shell which nvim)

PLUGIN_NAME = iced
VITAL_MODULES = \
		Async.Promise \
		Data.Dict \
		Data.List \
		Data.String \
		Data.String.Interpolation \
		Locale.Message \
		Vim.Buffer \
		Vim.BufferManager \
		Vim.Message

.PHONY: help
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

.PHONY: vital
vital:
	\rm -rf autoload/vital*
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

.PHONY: test
test: themis themis_nvim python_doctest bb_script_test

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis
.vim-sexp:
	git clone https://github.com/guns/vim-sexp .vim-sexp

.PHONY: themis
themis: .vim-themis .vim-sexp
	./.vim-themis/bin/themis

.PHONY: themis_nvim
themis_nvim:
	THEMIS_VIM=$(NVIM) ./.vim-themis/bin/themis

.PHONY: document
document: doc/vim-iced.txt
	bash scripts/html.sh
	bash scripts/asciidoctor.sh

.PHONY: serve_document
serve_document:
	(cd target/html && clj -Sdeps '{:deps {nasus/nasus {:mvn/version "LATEST"}}}' -m http.server)

target/bin/vint:
	mkdir -p target
	pip3 install -r requirements.txt -t ./target

.PHONY: lint
lint: vim-lint clj-lint

.PHONY: vim-lint
vim-lint: target/bin/vint
	bash scripts/lint.sh

bin/clj-kondo:
	cd bin && bash ../installer/clj-kondo.sh

.PHONY: clj-lint
clj-lint: bin/clj-kondo
	./bin/clj-kondo --lint clj:test/clj

.PHONY: python_doctest
python_doctest:
	python3 -m doctest python/bencode.py

.PHONY: bb_script_test
bb_script_test:
	bash scripts/bb_script_test.sh

.PHONY: version_check
version_check:
	bash scripts/version_check.sh

.PHONY: deps_check
deps_check:
	bash scripts/deps_check.sh

.PHONY: check
check: version_check deps_check

.PHONY: coverage
coverage: target/bin/vint themis
	bash scripts/coverage.sh

.PHONY: clean
clean:
	\rm -rf target .cpcache .vim-sexp .vim-themis

.PHONY: clean-all
clan-all: clean
	\rm -rf autoload/vital*
	\rm -f bin/iced

.PHONY: bin
bin:
	clojure -M:jackin

.PHONY: outdated
outdated:
	clojure -M:outdated --upgrade

.PHONY: repl
repl:
	clojure -R:jackin:dev -m iced-repl

.PHONY: benchmark
benchmark:
	vim -u NONE -i NONE -n -N --cmd 'source scripts/bencode_benchmark.vim'
