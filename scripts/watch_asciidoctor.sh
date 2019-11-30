#!/bin/bash

find doc/pages -type f | entr bash scripts/asciidoctor.sh
