#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $SCRIPT_DIR; cd ..; pwd)

TEST_CP="${PROJECT_DIR}/clj/script:${PROJECT_DIR}/test/clj/script"

bb --classpath "${TEST_CP}" -m test-runner
