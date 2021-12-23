#!/bin/sh

# specify search path
if [ ! -z ${WOLFRAM_PATH} ]; then
  search_path=$WOLFRAM_PATH
else
  echo "WOLFRAM_PATH not specified"
  if [ $(uname) = "Linux" ]; then
    search_path=$(echo `realpath $(which math)` | sed -E 's/(.*)\/Executables.*/\1/')
    echo "search compilation tools at '$search_path'"
  elif [ $(uname) = "Darwin" ]; then
    search_path=$(echo `realpath $(which math)` | sed -E 's/(.*)\/Executables.*/\1/')
    echo "search compilation tools at '$search_path'"
  else
    echo "Unknown system, please specify WOLFRAM_PATH like:"
    echo "\tWOLFRAM_PATH=/path/to/wolframengine_or_mathematica $0"
    exit 1
  fi
fi

# find compilation additions in search path
export WSPATH=$(find ${search_path} -name CompilerAdditions | grep WSTP)
if [ ! -z $WSPATH ]; then
  make
else
  echo "CompilerAdditions not found, consider reporting a bug"
  exit 1
fi

