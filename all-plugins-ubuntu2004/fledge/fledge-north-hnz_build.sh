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
## Author: Akli Rahmoun
##

VERSION=$1

wget -O ./fledge-north-hnz.tar.gz https://github.com/fledge-power/fledge-north-hnz/archive/refs/tags/$VERSION.tar.gz
tar -xf fledge-north-hnz.tar.gz
mv fledge-north-hnz-* fledge-north-hnz
cd fledge-north-hnz
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DFLEDGE_INCLUDE=/usr/local/fledge/include/ -DFLEDGE_LIB=/usr/local/fledge/lib/ ..
make
if [ ! -d "${FLEDGE_ROOT}/plugins/north/hnz" ] 
then
    sudo mkdir -p $FLEDGE_ROOT/plugins/north/hnz
fi
sudo cp libhnz.so $FLEDGE_ROOT/plugins/north/hnz
