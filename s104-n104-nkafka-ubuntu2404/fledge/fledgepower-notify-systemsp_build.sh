#!/bin/bash
set -euo pipefail
VERSION="$1"
cd /tmp
wget -q -O notify-systemsp.tar.gz "https://github.com/fledge-power/fledgepower-notify-systemsp/archive/refs/tags/${VERSION}.tar.gz"
tar -xf notify-systemsp.tar.gz
mv fledgepower-notify-systemsp-* fledgepower-notify-systemsp
cmake -S fledgepower-notify-systemsp -B fledgepower-notify-systemsp/build -DFLEDGE_INCLUDE=/usr/local/fledge/include/ -DFLEDGE_LIB=/usr/local/fledge/lib/
cmake --build fledgepower-notify-systemsp/build --parallel "$(nproc)"
install -D fledgepower-notify-systemsp/build/libsystemspn.so "${FLEDGE_ROOT}/plugins/notificationDelivery/systemspn/libsystemspn.so"
