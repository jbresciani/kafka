#!/bin/bash
JMX_PORT=KAFKA_JMX_PORT

sed -i "s/^hostPort:.*/hostPort:\ 127.0.0.1:${KAFKA_JMX_PORT}/g" "/etc/kafka/jmx_prometheus_exporter.yml"

# this will update /etc/kafka/server.properties with any ENV vars that start KAFKA_
# the remaining part of the ENV var name should be the kafka properties in upper case
# with .'s replaced by _
#
# i.e.
# KAFKA_BROKER_ID=1 
# will be added as
# broker.id=1
# in /etc/kafka/server.properties
/usr/local/bin/update-server-properties.py

# -------- start SASL-SCRAM setup -------------
IFS='/' read -r ZOOKEEPER_CONNECTION_STRING ZOOKEEPER_ROOT <<< "$KAFKA_ZOOKEEPER_CONNECT"

# pre-setup the kafka znodes in zookeeper so a user can be pre-created for kafka
ZK_PATH=$(echo $ZOOKEEPER_ROOT | tr "/" "\n")
PREVIOUS_PATH=/
for ZK_PATH_PART in ${ZK_PATH}
do
    ${KAFKA_HOME}/bin/zookeeper-shell.sh ${ZOOKEEPER_CONNECTION_STRING} create ${PREVIOUS_PATH}${ZK_PATH_PART} null
    PREVIOUS_PATH="${PREVIOUS_PATH}${ZK_PATH_PART}/"
done
# create the kafka broker user in zookeeper
${KAFKA_HOME}/bin/kafka-configs.sh --zookeeper ${KAFKA_ZOOKEEPER_CONNECT} --alter --add-config "SCRAM-SHA-256=[password=${BROKER_PASSWORD}],SCRAM-SHA-512=[password=${BROKER_PASSWORD}]" --entity-type users --entity-name ${BROKER_USERNAME}
# -------- end SASL-SCRAM setup ---------------

${KAFKA_HOME}/bin/kafka-server-start.sh /etc/kafka/server.properties