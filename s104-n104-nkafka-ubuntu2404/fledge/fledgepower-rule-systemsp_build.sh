#!/bin/bash
set -euo pipefail
VERSION="$1"
cd /tmp
wget -q -O rule-systemsp.tar.gz "https://github.com/fledge-power/fledgepower-rule-systemsp/archive/refs/tags/${VERSION}.tar.gz"
tar -xf rule-systemsp.tar.gz
mv fledgepower-rule-systemsp-* fledgepower-rule-systemsp
cmake -S fledgepower-rule-systemsp -B fledgepower-rule-systemsp/build -DFLEDGE_INCLUDE=/usr/local/fledge/include/ -DFLEDGE_LIB=/usr/local/fledge/lib/
cmake --build fledgepower-rule-systemsp/build --parallel "$(nproc)"
install -D fledgepower-rule-systemsp/build/libsystemspr.so "${FLEDGE_ROOT}/plugins/notificationRule/systemspr/libsystemspr.so"
