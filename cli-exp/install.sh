#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

RELEASE_CHANNEL=${1:-"stable"}
VERSION=${2:-"latest"}

if [[ $RELEASE_CHANNEL == "help" ]] || [[ $RELEASE_CHANNEL == "--help" ]] || [[ $RELEASE_CHANNEL == "-h" ]]; then
  echo "Liferay Cloud Platform CLI install script:

$0 [channel] [version] [dest]

Use $0 to install the CLI on your system."
  exit 1
fi

UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [[ $UNAME == *"windows"* ]] || [[ $UNAME == *"mingw"* ]] || [[ $UNAME == *"cygwin"* ]] ; then
  UNAME="win"
elif [ $UNAME == "darwin" ] ; then
  UNAME="macos"
fi

FILE=lcp-exp-$UNAME
EXECUTABLE_FILE=lcp-exp

if [[ $UNAME == *"win"* ]] ; then
  EXECUTABLE_FILE=$EXECUTABLE_FILE.exe
fi

TEMPDEST=$(mktemp 2>/dev/null || mktemp -t 'lcp-exp-cli')

ec=$(command -v $EXECUTABLE_FILE 2>/dev/null || true)

if [ -n "$ec" ] ; then
  DESTDIR=$(dirname "$(command -v $EXECUTABLE_FILE)")
elif [ $UNAME == "win" ] ; then
  IS_MINGWIN=${MSYSTEM:-""}
  if [ "$HOME" != "" ] && [[ -n $IS_MINGWIN ]] ; then
    DESTDIR="$HOME/AppData/Local/Programs/lcp-exp/bin"
  elif [[ $HOMEDRIVE$HOMEPATH != "" ]] ; then
    DESTDIR="$HOMEDRIVE$HOMEPATH\AppData\Local\Programs\lcp-exp\bin"
  else
    DESTDIR="$USERPROFILE\AppData\Local\Programs\lcp-exp\bin"
  fi
elif [[ :$PATH: == *:"$HOME/.local/bin":* ]] ; then
  DESTDIR="$HOME/.local/bin"
elif [[ :$PATH: == *:"$HOME/bin":* ]] ; then
  DESTDIR="$HOME/bin"
else
  DESTDIR="/usr/local/bin"
fi

DESTDIR=${3:-$DESTDIR}

function setupAlternateDir() {
  if [ ! -t 1 ] ; then
    echo "Can't install in $DESTDIR (default).\n"
    echo "Your \$PATH locations:"
    echo "${PATH//:/\n}"
    echo "See https://en.wikipedia.org/wiki/PATH_(variable) for more info on \$PATH.\n"
    echo "Run this script from terminal to install it somewhere else."
    exit 1
  fi

  echo "No permission to install in $DESTDIR"
  echo "Try again as root or run:"
  echo "curl https://cdn.liferay.cloud/cli-exp/installer/lcp-exp.sh -fsSL | sudo bash"
  read -r -p "Install in [current dir]: " DESTDIR < /dev/tty;
  DESTDIR=${DESTDIR:-$(pwd)}
  DESTDIR=${DESTDIR/"~"/$HOME}
}

if [ ! -w "$DESTDIR" ] ; then
  mkdir -p "$DESTDIR"
fi

if [ ! -w "$DESTDIR" ] ; then setupAlternateDir ; fi

echo "Trying to install in $DESTDIR"

function run() {
  URL=https://cdn.liferay.cloud/cli-exp/${RELEASE_CHANNEL}/$VERSION/$FILE.tgz

  if [ "$RELEASE_CHANNEL" != "stable" ] ; then
    echo "Downloading from $URL ($RELEASE_CHANNEL channel)."
  else
    echo "Downloading from $URL."
  fi

  curl -L -o "$TEMPDEST" "$URL" -f --progress-bar
  tar -xzf "$TEMPDEST" -C "$DESTDIR" $EXECUTABLE_FILE
  chmod +x "$DESTDIR/$EXECUTABLE_FILE"
  info
}

function info() {
  lcppath=$(command -v $EXECUTABLE_FILE 2>/dev/null) || true
  (command -v $EXECUTABLE_FILE >> /dev/null) && ec=$? || ec=$?
  if [[ $ec -ne 0 ]] || [[ ! $lcppath -ef "$DESTDIR/$EXECUTABLE_FILE" ]]; then
    echo "Installed, but not reachable by \"$EXECUTABLE_FILE\" (check your \$PATH)"
    echo "Run with $DESTDIR/$EXECUTABLE_FILE"
    return
  fi

  UNPRIVILEGED_USER=${SUDO_USER:-""}
  check

  echo "Installed, type '$EXECUTABLE_FILE --help' to start."
}

function check() {
  if [ -z "$UNPRIVILEGED_USER" ]; then
    $EXECUTABLE_FILE --help >/dev/null 2>&1
  else
    sudo --user "$UNPRIVILEGED_USER" $EXECUTABLE_FILE --help >/dev/null 2>&1
  fi
}

function cleanup() {
  rm $FILE.tgz 2>/dev/null || true
  rm "$TEMPDEST" 2>/dev/null || true
}

trap cleanup EXIT
run
