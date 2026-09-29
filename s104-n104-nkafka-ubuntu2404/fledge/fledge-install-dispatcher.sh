#!/bin/bash

##--------------------------------------------------------------------
## Copyright (c) 2022, RTE (https://www.rte-france.com)
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##--------------------------------------------------------------------

set -euo pipefail

VERSION=$1
TAG="v${VERSION#v}"
SOURCE_DIR=/tmp/fledge-service-dispatcher

rm -rf "$SOURCE_DIR"
wget -q -O /tmp/fledge-service-dispatcher.zip "https://github.com/fledge-iot/fledge-service-dispatcher/archive/refs/tags/${TAG}.zip"
unzip -q /tmp/fledge-service-dispatcher.zip -d /tmp
mv "/tmp/fledge-service-dispatcher-${VERSION#v}" "$SOURCE_DIR"

cmake -S "$SOURCE_DIR" -B "$SOURCE_DIR/build" \
    -DFLEDGE_SRC=/tmp/fledge \
    -DFLEDGE_INSTALL=/usr/local/fledge
cmake --build "$SOURCE_DIR/build" --parallel "$(nproc)"
cmake --install "$SOURCE_DIR/build"
