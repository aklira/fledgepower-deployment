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

##
## Author: Mark Riddoch, Akli Rahmoun
##

VERSION=$1

# Build and install librdkafka, required by the kafka plugin
git clone --branch v2.1.1 --depth 1 https://github.com/confluentinc/librdkafka.git
cd librdkafka
./configure --enable-ssl
make -j"$(nproc)"
make install
cd ..

# Download, build and install the kafka north plugin
wget -O ./fledge-north-kafka.tar.gz https://github.com/fledge-iot/fledge-north-kafka/archive/refs/tags/$VERSION.tar.gz
tar -xf fledge-north-kafka.tar.gz
mv fledge-north-kafka-* fledge-north-kafka
cd fledge-north-kafka
chmod +x mkversion
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DFLEDGE_INCLUDE=/usr/local/fledge/include/ -DFLEDGE_LIB=/usr/local/fledge/lib/ ..
make
if [ ! -d "${FLEDGE_ROOT}/plugins/north/kafka" ]
then
    mkdir -p $FLEDGE_ROOT/plugins/north/kafka
fi
cp libKafka.so $FLEDGE_ROOT/plugins/north/kafka/libkafka.so