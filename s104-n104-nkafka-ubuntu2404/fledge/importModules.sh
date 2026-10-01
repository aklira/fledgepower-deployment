#!/bin/bash
set -euo pipefail

# Services stay disabled until their categories and control route are ready.
# A service is reconciled before its categories are written so an interrupted
# bootstrap can be resumed without leaving a category-only reservation behind.
API=${FLEDGE_API:-http://localhost:8081/fledge}
TOKEN=${1:-}
auth=()
[[ -n "$TOKEN" ]] && auth=(-H "authorization: $TOKEN")
api() { curl --fail --silent --show-error "${auth[@]}" "$@"; }
wait_api() { for _ in {1..60}; do curl -fsS "$API/ping" >/dev/null && return 0; sleep 1; done; return 1; }
cleanup() {
    # Delete dependants before their categories. Fledge may release a name
    # asynchronously, so verify each service URL is gone before returning.
    api -X DELETE "$API/control/pipeline/iec104north_to_iec104south" >/dev/null 2>&1 || true
    for name in kafkanorth iec104north iec104south; do
        api -X PUT "$API/service/$name" -H 'content-type: application/json' \
            -d '{"enabled":false}' >/dev/null 2>&1 || true
        api -X DELETE "$API/service/$name" >/dev/null 2>&1 || true
    done
    for name in kafkanorth iec104north iec104south; do
        api -X DELETE "$API/category/$name" >/dev/null 2>&1 || true
    done
    for _ in {1..30}; do
        local remaining=0
        for name in kafkanorth iec104north iec104south; do
            api "$API/service/$name" >/dev/null 2>&1 && remaining=1
        done
        if (( remaining == 0 )); then
            return 0
        fi
        sleep 1
    done
    echo "bootstrap cleanup: service names are still reserved" >&2
    return 1
}
if [[ "${2:-}" == "--clean" ]]; then
    wait_api
    cleanup
    echo "FledgePower bootstrap state removed"
    exit 0
fi
service() {
    local name=$1 type=$2 plugin=$3 payload
    payload=$(jq -cn --arg name "$name" --arg type "$type" --arg plugin "$plugin" \
        '{name:$name,type:$type,plugin:$plugin,enabled:false}')

    if api "$API/service/$name" >/dev/null 2>&1; then
        # PUT the complete identity as well as enabled=false. This repairs an
        # existing service created with an obsolete plugin or service type.
        if api -X PUT "$API/service/$name" -H 'content-type: application/json' -d "$payload" >/dev/null; then
            return
        fi
        # Older Fledge API versions do not allow changing type/plugin with
        # PUT. Recreate the service in that case, after disabling it first.
        api -X PUT "$API/service/$name" -H 'content-type: application/json' \
            -d '{"enabled":false}' >/dev/null 2>&1 || true
        api -X DELETE "$API/service/$name" >/dev/null
        sleep 2
        api -X DELETE "$API/category/$name" >/dev/null 2>&1 || true
        api -X POST "$API/service" -H 'content-type: application/json' -d "$payload" >/dev/null
        return
    fi

    if ! api -X POST "$API/service" -H 'content-type: application/json' -d "$payload" >/dev/null; then
        # Fledge can retain a category reservation after an interrupted
        # service creation. Remove only the conflicting category, then retry.
        api -X DELETE "$API/category/$name" >/dev/null 2>&1 || true
        sleep 2
        api -X POST "$API/service" -H 'content-type: application/json' -d "$payload" >/dev/null
    fi
}
category() { api -X PUT "$API/category/$1" -H 'content-type: application/json' -d "$2" >/dev/null; }
enable() { api -X PUT "$API/service/$1" -H 'content-type: application/json' -d '{"enabled":true}' >/dev/null; }
verify_service() {
    local name=$1 type=$2 plugin=$3 service_json
    service_json=$(api "$API/service/$name")
    jq -e --arg type "$type" --arg plugin "$plugin" \
        '(.type == $type) and (.plugin == $plugin)' <<<"$service_json" >/dev/null || {
        echo "bootstrap: service $name has an unexpected type or plugin" >&2
        return 1
    }
}
wait_running() {
    local name=$1 service_json
    for _ in {1..60}; do
        service_json=$(api "$API/service/$name")
        if jq -e '(.status == "running") or (.state == "running")' <<<"$service_json" >/dev/null; then
            return 0
        fi
        sleep 1
    done
    echo "bootstrap: service $name did not reach running state" >&2
    api "$API/service/$name" >&2 || true
    return 1
}

wait_api
service iec104south south iec104
service iec104north north iec104
service kafkanorth north kafka

south_ip=${SOUTH_RTU_IP:-172.30.0.13}
north_client=${NORTH_CLIENT_IP:-172.30.0.21}
category iec104south "$(jq -n --arg ip "$south_ip" '{protocol_stack:{protocol_stack:{name:"C_104_S3",version:"2",transport_layer:{redundancy_groups:[{connections:[{srv_ip:$ip,port:2404,conn:true,start:true}],rg_name:"gr1",tls:false,k_value:12,w_value:8,t0_timeout:30,t1_timeout:10,t2_timeout:10,t3_timeout:11}]},application_layer:{orig_addr:0,ca_asdu_size:2,ioaddr_size:3,asdu_size:0,gi_cycle:86400,gi_all_ca:true,gi_time:60,time_sync:0},south_monitoring:{asset:"CONSTAT-S3",cnx_loss_status_id:"S3_TS-SYST_PRT.INFA"}}}}')"
category iec104north "$(jq -n --arg ip "$north_client" '{protocol_stack:{protocol_stack:{name:"S_104_S3",version:"2",transport_layer:{redundancy_groups:[{connections:[{clt_ip:$ip}],rg_name:"gr1"}],bind_on_ip:false,srv_ip:"0.0.0.0",port:2404,tls:false,k_value:12,w_value:8,t0_timeout:30,t1_timeout:15,t2_timeout:5,t3_timeout:20,mode:"accept_if_south_connx_started"},application_layer:{ca_asdu_size:2,ioaddr_size:3,asdu_size:0,asdu_queue_size:100,time_sync:0,cmd_exec_timeout:20,cmd_recv_timeout:0,cmd_dest:"iec104south",accept_cmd_with_time:1,filter_list:[]},south_monitoring:[{asset:"CONSTAT-S3"}]}}}')"
category Storage '{"readingPlugin":"sqlitememory"}'

verify_service iec104south south iec104
verify_service iec104north north iec104
verify_service kafkanorth north kafka

# Fledge 3.1 requires a control pipeline for North IEC 104 commands.
pipeline='{"execution":"Shared","source":{"type":2,"name":"iec104north"},"destination":{"type":2,"name":"iec104south"},"filters":[],"enabled":true,"name":"iec104north_to_iec104south"}'
if api "$API/control/pipeline/iec104north_to_iec104south" >/dev/null 2>&1; then
    api -X PUT "$API/control/pipeline/iec104north_to_iec104south" -H 'content-type: application/json' -d "$pipeline" >/dev/null
else
    api -X POST "$API/control/pipeline" -H 'content-type: application/json' -d "$pipeline" >/dev/null
fi

enable iec104south
enable iec104north
enable kafkanorth

for name in iec104south iec104north kafkanorth; do
    wait_running "$name"
done
echo "FledgePower services and IEC 104 categories configured"
