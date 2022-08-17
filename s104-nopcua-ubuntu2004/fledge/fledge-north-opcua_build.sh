#!/usr/bin/env bash

##--------------------------------------------------------------------
## Copyright (c) 2020 Dianomic Systems
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

#git clone https://github.com/fledge-iot/fledge-north-opcua.git
#cd fledge-north-opcua
#chmod +x mkversion
#mkdir build
#./requirements.sh
#cd build
#cmake -DFLEDGE_INCLUDE=/usr/local/fledge/include/ -DFLEDGE_LIB=/usr/local/fledge/lib/ ..
#make
#if [ ! -d "${FLEDGE_ROOT}/plugins/north/opcua" ] 
#then
#    sudo mkdir -p $FLEDGE_ROOT/plugins/north/opcua
#fi
#sudo cp libopcua.so $FLEDGE_ROOT/plugins/north/opcua

wget --no-check-certificate http://archives.fledge-iot.org/nightly/ubuntu2004/x86_64/fledge-north-opcua_1.9.2-3_x86_64.deb
dpkg --unpack ./fledge-north-opcua_1.9.2-3_x86_64.deb
apt-get install -yf
apt-get clean -y
