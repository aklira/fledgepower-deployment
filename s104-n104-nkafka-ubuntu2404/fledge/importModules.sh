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

# Services of the image:
# - IEC104 south service: pulls data from a field IEC104 master (client)
# - IEC104 north service: exposes the data as an IEC104 server (slave, port 2404)
# - Kafka north service: sends the data to an Apache Kafka broker (producer)

curl_wrapper() {
    if  [ ! -z "$TOKEN" ]; then
        curl "$@" -H "authorization: $TOKEN"
    else
        curl "$@"
    fi
}

# Connection token in case login is required to use the api
TOKEN=$1

south_service_name="iec104south"
north_104_service_name="iec104north"
north_kafka_service_name="kafkanorth"

# Create service south
curl_wrapper -sX POST http://localhost:8081/fledge/service -d '{"name":"'$south_service_name'","type":"south","plugin":"iec104","enabled":true}'

# Create service north
curl_wrapper -sX POST http://localhost:8081/fledge/service -d '{"name":"'$north_104_service_name'","type":"north","plugin":"iec104","enabled":true}'
curl_wrapper -sX POST http://localhost:8081/fledge/service -d '{"name":"'$north_kafka_service_name'","type":"north","plugin":"kafka","enabled":true}'