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

# requirements.sh changes to its SQLite source directory before invoking make.
# Build Fledge explicitly, then install its targets without the package-only
# schema pre-check, which requires an existing Fledge installation.
cd "$SOURCE_DIR"
make -j"$(nproc)"
mkdir -p /usr/local/fledge
make fledge_version_file_install c_install python_install python_requirements \
    scripts_install bin_install extras_install data_install
