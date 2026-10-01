#!/bin/bash
set -euo pipefail
VERSION="$1"
cd /tmp
wget -q -O notify-systemsp.tar.gz "https://github.com/fledge-power/fledgepower-notify-systemsp/archive/refs/tags/${VERSION}.tar.gz"
tar -xf notify-systemsp.tar.gz
mv fledgepower-notify-systemsp-* fledgepower-notify-systemsp
cd fledgepower-notify-systemsp
chmod +x mkversion
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    -DFLEDGE_INCLUDE=/usr/local/fledge/include/ \
    -DFLEDGE_LIB=/usr/local/fledge/lib/ ..
make -j"$(nproc)"
install -D libsystemspn.so "${FLEDGE_ROOT}/plugins/notificationDelivery/systemspn/libsystemspn.so"
