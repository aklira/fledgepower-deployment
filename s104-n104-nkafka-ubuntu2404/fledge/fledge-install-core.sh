#!/bin/bash
set -euo pipefail

VERSION=$1
SOURCE_DIR=/tmp/fledge

rm -rf "$SOURCE_DIR"
wget -q -O /tmp/fledge.zip "https://github.com/fledge-iot/fledge/archive/refs/tags/${VERSION}.zip"
unzip -q /tmp/fledge.zip -d /tmp
mv "/tmp/fledge-${VERSION#v}" "$SOURCE_DIR"

cd "$SOURCE_DIR"
./requirements.sh
