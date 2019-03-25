#!/bin/bash

cat /etc/kafka/kafka_server_jaas.conf

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
