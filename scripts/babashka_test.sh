#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $SCRIPT_DIR; cd ..; pwd)

COMMAND_CP="${PROJECT_DIR}/clj/command:${PROJECT_DIR}/test/clj/command"

bb --classpath "${COMMAND_CP}" -m test-runner
