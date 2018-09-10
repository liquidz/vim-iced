# vim-iced
[![CircleCI](https://circleci.com/gh/liquidz/vim-iced.svg?style=svg)](https://circleci.com/gh/liquidz/vim-iced)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

Clojure Interactive Development Environment for Vim8.

**WARN**: This project is work in progress.

## Requirements

 * Vim 8.1 or later
 * Clojure & Java
 * [vim-sexp](https://github.com/guns/vim-sexp)
 * No python!

## Features

 * Asynchronous evaluation
   * powered by `channel` in Vim8
 * Rich functions
   * powered by [cider-nrepl](https://github.com/clojure-emacs/cider-nrepl), [refactor-nrepl](https://github.com/clojure-emacs/refactor-nrepl), and [iced-nrepl](https://github.com/liquidz/iced-nrepl)
 * ClojureScript support
   * `figwheel` and `nashorn` is supported currently

## Installation

### vim-plug

```
Plug 'ctrlpvim/ctrlp.vim'
Plug 'guns/vim-sexp',    {'for': 'clojure'}
Plug 'liquidz/vim-iced', {'for': 'clojure'}
```

[ctrlp.vim](https://github.com/ctrlpvim/ctrlp.vim) is required when selecting multiple candidates.

### key mappings

vim-iced is providing default key mappings.
To enable default key mappings, add following line to your `.vimrc`.

```
let g:iced_enable_default_key_mappings = v:true
```

See [vim-iced.txt](./doc/vim-iced.txt) for actual mappings.

### configuration

* ~/.lein/profile.clj
```clj
{:user
 {:dependencies [[nrepl "0.4.5"]
                 [iced-nrepl "0.1.0"]
                 [cider/cider-nrepl "0.18.0"]]
  :repl-options {:nrepl-middleware [cider.nrepl/wrap-complete
                                    cider.nrepl/wrap-debug
                                    cider.nrepl/wrap-format
                                    cider.nrepl/wrap-info
                                    cider.nrepl/wrap-macroexpand
                                    cider.nrepl/wrap-ns
                                    cider.nrepl/wrap-out
                                    cider.nrepl/wrap-pprint
                                    cider.nrepl/wrap-pprint-fn
                                    cider.nrepl/wrap-spec
                                    cider.nrepl/wrap-test
                                    cider.nrepl/wrap-trace
                                    cider.nrepl/wrap-undef
                                    iced.nrepl/wrap-iced]}
  :plugins [[refactor-nrepl "2.4.0"]]}}
```

[Boot](https://github.com/boot-clj/boot) configuration is also described in [vim-iced.txt](./doc/vim-iced.txt).

**WARN** `cider.nrepl/wrap-tracker` will cause vim's freezing.

## Usage

  1. Start repl
     - `lein repl`
     - `boot repl`
     - `clojure -Sdeps '{:deps {iced-repl {:git/url "https://github.com/liquidz/vim-iced" :sha "04ec7fb5bb1cecebec665f99e104d5f2791da73a"}}}' -m iced-repl`
  2. Open source file
  3. Evaluate forms (If not connected, vim-iced will connect automatically)

## Document

  * See [vim-iced.txt](./doc/vim-iced.txt).

## License

Copyright (c) 2018 [Masashi Iizuka](http://twitter.com/uochan)

Distributed under the MIT License.
