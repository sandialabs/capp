#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cmake -DCAPP_CMDLINE_ARGS="$(printf ';%q' "$@")" -P "$SCRIPT_DIR/capp.cmake"
