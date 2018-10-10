.PHONY: all vital test themis html lint clean bin ancient aspell repl circleci

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

test: themis lint

.vim-themis:
	git clone https://github.com/thinca/vim-themis .vim-themis
.vim-sexp:
	git clone https://github.com/guns/vim-sexp .vim-sexp
.vimdoc:
	git clone https://github.com/vim-jp/vimdoc-ja-working .vimdoc

themis: .vim-themis .vim-sexp
	./.vim-themis/bin/themis --runtimepath ./.vim-sexp --runtimepath ./test/helper

html: doc/vim-iced.txt .vimdoc
	rm -rf target/html
	mkdir -p target/html/doc
	cp doc/vim-iced.txt target/html/doc
	-cd target/html/doc ; vim -eu ../../../.vimdoc/tools/buildhtml.vim -c "qall!"
	sed -i '1,4d' target/html/doc/vim-iced.html
	sed -i 's/vim-iced\.html/index\.html/g' target/html/doc/vim-iced.html
	cat doc/.head.html target/html/doc/vim-iced.html doc/.foot.html > target/index.html

lint:
	find . -name "*.vim" | grep -v vital | grep -v .vim-themis | grep -v .vim-sexp | grep -v .vimdoc | xargs vint

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
	clojure -Adev -m iced-repl

circleci: _circleci-lint _circleci-test
_circleci-lint:
	circleci build --job lint
_circleci-test:
	\rm -rf .vim-sexp
	circleci build --job test
