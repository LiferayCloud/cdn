#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

RELEASE_CHANNEL=${1:-""}

if [[ $RELEASE_CHANNEL == "help" ]] || [[ $RELEASE_CHANNEL == "--help" ]] || [[ $RELEASE_CHANNEL == "-h" ]]; then
  echo "Liferay Cloud Platform CLI uninstall script:

$0

Use $0 to uninstall the CLI from your system."
  exit 1
fi

UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [[ $UNAME == *"windows"* ]] || [[ $UNAME == *"mingw"* ]] || [[ $UNAME == *"cygwin"* ]] ; then
  UNAME="win"
elif [ $UNAME == "darwin" ] ; then
  UNAME="macos"
fi

EXECUTABLE_FILE=lcp-exp

if [[ $UNAME == *"win"* ]] ; then
  EXECUTABLE_FILE=$EXECUTABLE_FILE.exe
fi

if [[ -f $(command -v $EXECUTABLE_FILE) ]] ; then
  echo "Do you want to uninstall Liferay Cloud Platform CLI?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) echo "Uninstall canceled"; exit;;
        esac
    done
else
  echo "Liferay Cloud Platform CLI not found on your system."
  exit 1
fi

rm "$(command -v $EXECUTABLE_FILE)" 2>/dev/null || (echo "Failed to uninstall Liferay Cloud Platform CLI."; exit 1);

echo "Liferay Cloud Platform CLI uninstalled successfully."