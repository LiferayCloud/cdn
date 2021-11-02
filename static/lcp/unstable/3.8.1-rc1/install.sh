#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

RELEASE_CHANNEL=${1:-"unstable"}
VERSION=${2:-"latest"}

if [[ $RELEASE_CHANNEL == "help" ]] || [[ $RELEASE_CHANNEL == "--help" ]] || [[ $RELEASE_CHANNEL == "-h" ]]; then
  echo "Liferay Cloud Platform CLI install script:
$0 [channel] [version] [dest]
Use $0 to install the CLI on your system."
  exit 1
fi

UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [ $UNAME == "darwin" ] ; then
  UNAME="macos"
fi

EXECUTABLE_FILE=lcp
CDNHOST=https://cdn.liferay.cloud
CDNPATHBASE=lcp
FILE=$EXECUTABLE_FILE-$UNAME
TEMPDEST=$(mktemp 2>/dev/null || mktemp -t "'"${EXECUTABLE_FILE}-cli"'")

ec=$(command -v $EXECUTABLE_FILE 2>/dev/null || true)

if [ -n "$ec" ] ; then
  DESTDIR=$(dirname "$(command -v $EXECUTABLE_FILE)")
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
  echo "curl ${CDNHOST}/${CDNPATHBASE}/install.sh -fsSL | sudo bash"
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
  URL=${CDNHOST}/${CDNPATHBASE}/${RELEASE_CHANNEL}/$VERSION/$FILE.tgz

  if [ "$RELEASE_CHANNEL" != "unstable" ] ; then
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
