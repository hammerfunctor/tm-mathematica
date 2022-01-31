#!/bin/sh

# specify search path
if [ ! -z ${WOLFRAM_PATH} ]; then
  search_path=$WOLFRAM_PATH
else

  echo "WOLFRAM_PATH not specified"
  bindir=$(which WolframKernel)
  if [ -L $bindir ]; then
    realbinpath=`readlink -n $bindir`
  else
    realbinpath=$bindir
  fi

  if [ $(uname) = "Linux" ]; then
    search_path=$(echo $realbinpath | sed -E 's/(.*)\/Executables.*/\1/')
    echo "search compilation tools at '$search_path'"
  elif [ $(uname) = "Darwin" ]; then
    search_path=$(echo $realbinpath| sed -E 's/(.*)\/Contents.*/\1/')
    echo "search compilation tools at '$search_path'"
  else
    echo "Unknown system, please specify WOLFRAM_PATH like:"
    echo "\tWOLFRAM_PATH=/path/to/wolframengine_or_mathematica $0"
    exit 1
  fi
fi

# find compilation additions in search path
if [ $(uname)=="Darwin" ]; then
  if [ -z $(echo `uname -m` | grep x86) ]; then
    ARCH=ARM
  else
    ARCH=x86
  fi
fi

export WSPATH=$(find ${search_path} -name CompilerAdditions | grep WSTP | grep $ARCH)
echo "Use compilation stuffs in: $WSPATH"
if [ ! -z $WSPATH ]; then
  make
else
  echo "CompilerAdditions not found, consider reporting a bug"
  exit 1
fi

