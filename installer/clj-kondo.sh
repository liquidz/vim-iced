#!/bin/bash

set -e

bash <(curl -s https://raw.githubusercontent.com/borkdude/clj-kondo/master/script/install-clj-kondo) --dir $(pwd)
