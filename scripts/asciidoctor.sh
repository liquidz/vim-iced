#!/bin/bash

echo -n 'start ... '

docker run --rm -v $(pwd):/documents/ asciidoctor/docker-asciidoctor \
    asciidoctor -o target/html/index.html doc/pages/index.adoc

echo 'done'
