#!/bin/bash

echo -n 'start ... '

if [ -d target/html/assets ]; then
    echo -n 'copying assets ... '
    \rm -rf target/html/assets
    \cp -pr  doc/pages/assets target/html/assets
fi

docker run --rm -v $(pwd):/documents/ asciidoctor/docker-asciidoctor \
    asciidoctor -o target/html/index.html doc/pages/index.adoc

echo 'done'
