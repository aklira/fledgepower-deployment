# FledgePower IEC 104 / Kafka image

This image contains Fledge 3.1.0, the IEC 104 South and North plugins, the
Kafka North plugin, and the FledgePower SystemSP notification rule and delivery
plugins. The image is built by `publish.yml` and is intended to be published as
`ghcr.io/aklira/fledgepower/fledge`.

## Build

Generate the Containerfile, then build from the plugin directory:

```sh
cd s104-n104-nkafka-ubuntu2404/fledge
./buildContainerfile.sh
docker build -f fledge.dockerfile -t fledgepower/fledge:3.1.0-iec104 .
```

The immutable digest must be recorded from the produced image with:
`docker image inspect --format '{{index .RepoDigests 0}}' ...` after pushing.
The digest cannot be known from source alone.

## Startup order

`start.sh` starts Fledge, waits for the API health endpoint, logs in, and runs
`importModules.sh`. That script is transactional in ordering: it creates or
disables services, writes IEC 104 and storage categories, creates or replaces
the control pipeline, and only then enables South, North, and Kafka North.
Running it a second time is supported. Set `SOUTH_RTU_IP` and
`NORTH_CLIENT_IP` to override the bench defaults.

The North-to-South control pipeline is required for commands in this Fledge
3.1 deployment. The data pipelines are internal to the plugins and are not
needed for the minimal command route.

## Minimal IEC 104 configuration

The bootstrap uses protocol version `2`, one redundancy group `gr1`, one South
connection (`srv_ip`, port 2404), and one North client (`clt_ip`). The North
server binds `0.0.0.0:2404` and uses `cmd_dest: iec104south`. No catch-all
redundancy group is created. The North queue is 100 entries.

The South is considered connected only after the IEC 104 transport session is
established with the RTU. A completed GI additionally requires the RTU to
accept the interrogation and answer its activation confirmation, data, and
termination. A Fledge service being `running` only means its process is alive;
it does not prove either condition.

`south_monitoring.asset` identifies the Fledge asset used for connection
monitoring. `cnx_loss_status_id` is the status signal updated on connection
loss; it must exist in the RTU mapping when monitoring events are enabled.

## Kafka aliases and plugins

The build installs both aliases required by PluginManager:

```text
/usr/local/fledge/plugins/north/Kafka -> kafka
/usr/local/fledge/plugins/north/kafka/libkafka.so -> libKafka.so
```

The SystemSP plugins are built at `v2.0.0`. The IEC 104 plugins are built at
`v2.0.0`, Kafka at `v3.1.0`, lib60870 at `v2.3.6`, and the Fledge,
dispatcher, and notification sources at `v3.1.0`; these versions are declared
in `buildContainerfile.yml` and the corresponding build scripts.

## Verification

On a fresh container and volume, verify the API services, the IEC 104 session
and GI in the simulator logs, the absence of `Redundancy group not found`, the
North command confirmations, and Kafka publication to `ibtnm-s3-readings`.
Run `importModules.sh` twice and compare `/fledge/service`, the IEC 104
categories, and `/fledge/control/pipeline` to verify idempotence.
