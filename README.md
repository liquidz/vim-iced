# vim-iced
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

Clojure Interactive Development Environment for Vim8.

**WARN**: This project is work in progress.

## Requirements

 * Clojure & Java
 * [vim-sexp](https://github.com/guns/vim-sexp)
 * No python!

## Features

 * Asynchronous evaluation
   * powered by `channel` in Vim8
 * Rich functions
   * powered by `cider-nrepl`, `refactor-nrepl`
 * ClojureScript support
   * `figwheel` and `nashorn` is supported currently

## Installation

### vim-plug

```
Plug 'guns/vim-sexp',    {'for': 'clojure'}
Plug 'liquidz/vim-iced', {'for': 'clojure'}
```

### key mappings

vim-iced is providing default key mappings.
To enable default key mappings, add folow line to your `.vimrc`.

```
let g:iced_enable_default_key_mappings = v:true
```

See [vim-iced.txt](./doc/vim-iced.txt) fot actual mappings.

### ~/.lein/profile.clj

```clj
{:user
 {:dependencies [[cider/cider-nrepl "0.17.0"]
                 [cljfmt  "0.6.0"]]
  :repl-options {:nrepl-middleware [cider.nrepl/wrap-complete
                                    cider.nrepl/wrap-format
                                    cider.nrepl/wrap-info
                                    cider.nrepl/wrap-macroexpand
                                    cider.nrepl/wrap-ns
                                    cider.nrepl/wrap-out
                                    cider.nrepl/wrap-spec
                                    cider.nrepl/wrap-test
                                    cider.nrepl/wrap-undef]}
  :plugins [[refactor-nrepl "2.4.0-SNAPSHOT"]]}}
```

**WARN** `cider.nrepl/wrap-trace` will cause vim's freeze

## Usage

Only 3 steps!!

  1. `lein repl`
  2. Open source file
  3. Evaluate forms (If not connected, vim-iced will connect automatically)

## Document

  * See [vim-iced.txt](./doc/vim-iced.txt).

## License

Copyright (c) 2018 [Masashi Iizuka](http://twitter.com/uochan)

Distributed under the MIT License.
