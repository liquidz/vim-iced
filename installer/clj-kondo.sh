#!/bin/bash

set -e

bash <(curl -s https://raw.githubusercontent.com/clj-kondo/clj-kondo/master/script/install-clj-kondo) --dir $(pwd)
