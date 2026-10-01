#!/bin/bash
set -euo pipefail
VERSION="$1"
cd /tmp
wget -q -O rule-systemsp.tar.gz "https://github.com/fledge-power/fledgepower-rule-systemsp/archive/refs/tags/${VERSION}.tar.gz"
tar -xf rule-systemsp.tar.gz
mv fledgepower-rule-systemsp-* fledgepower-rule-systemsp
cd fledgepower-rule-systemsp
chmod +x mkversion
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    -DFLEDGE_INCLUDE=/usr/local/fledge/include/ \
    -DFLEDGE_LIB=/usr/local/fledge/lib/ ..
make -j"$(nproc)"
install -D libsystemspr.so "${FLEDGE_ROOT}/plugins/notificationRule/systemspr/libsystemspr.so"
