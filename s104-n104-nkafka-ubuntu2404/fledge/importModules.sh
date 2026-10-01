#!/bin/bash
set -euo pipefail

# Services stay disabled until their categories and control route are ready.
# All writes are PUT-or-create so running this script again is safe.
API=${FLEDGE_API:-http://localhost:8081/fledge}
TOKEN=${1:-}
auth=()
[[ -n "$TOKEN" ]] && auth=(-H "authorization: $TOKEN")
api() { curl --fail --silent --show-error "${auth[@]}" "$@"; }
wait_api() { for _ in {1..60}; do curl -fsS "$API/ping" >/dev/null && return 0; sleep 1; done; return 1; }
service() {
    local name=$1 type=$2 plugin=$3
    if ! api "$API/service/$name" >/dev/null 2>&1; then
        api -X POST "$API/service" -H 'content-type: application/json' \
            -d "{\"name\":\"$name\",\"type\":\"$type\",\"plugin\":\"$plugin\",\"enabled\":false}" >/dev/null
    else
        api -X PUT "$API/service/$name" -H 'content-type: application/json' -d '{"enabled":false}' >/dev/null
    fi
}
category() { api -X PUT "$API/category/$1" -H 'content-type: application/json' -d "$2" >/dev/null; }
enable() { api -X PUT "$API/service/$1" -H 'content-type: application/json' -d '{"enabled":true}' >/dev/null; }

wait_api
service iec104south south iec104
service iec104north north iec104
service kafkanorth north kafka

south_ip=${SOUTH_RTU_IP:-172.30.0.13}
north_client=${NORTH_CLIENT_IP:-172.30.0.21}
category iec104south "$(jq -n --arg ip "$south_ip" '{protocol_stack:{protocol_stack:{name:"C_104_S3",version:"2",transport_layer:{redundancy_groups:[{connections:[{srv_ip:$ip,port:2404,conn:true,start:true}],rg_name:"gr1",tls:false,k_value:12,w_value:8,t0_timeout:30,t1_timeout:10,t2_timeout:10,t3_timeout:11}]},application_layer:{orig_addr:0,ca_asdu_size:2,ioaddr_size:3,asdu_size:0,gi_cycle:86400,gi_all_ca:true,gi_time:60,time_sync:0},south_monitoring:{asset:"CONSTAT-S3",cnx_loss_status_id:"S3_TS-SYST_PRT.INFA"}}}}')"
category iec104north "$(jq -n --arg ip "$north_client" '{protocol_stack:{protocol_stack:{name:"S_104_S3",version:"2",transport_layer:{redundancy_groups:[{connections:[{clt_ip:$ip}],rg_name:"gr1"}],bind_on_ip:false,srv_ip:"0.0.0.0",port:2404,tls:false,k_value:12,w_value:8,t0_timeout:30,t1_timeout:15,t2_timeout:5,t3_timeout:20,mode:"accept_if_south_connx_started"},application_layer:{ca_asdu_size:2,ioaddr_size:3,asdu_size:0,asdu_queue_size:100,time_sync:0,cmd_exec_timeout:20,cmd_recv_timeout:0,cmd_dest:"iec104south",accept_cmd_with_time:1,filter_list:[]},south_monitoring:[{asset:"CONSTAT-S3"}]}}}')"
category Storage '{"readingPlugin":"sqlitememory"}'

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
echo "FledgePower services and IEC 104 categories configured"
