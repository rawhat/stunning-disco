#!/bin/sh
find . -type f \( -name "*.go" -o -name "*.tmpl" \) | \
      entr -r ./buildrun.sh
