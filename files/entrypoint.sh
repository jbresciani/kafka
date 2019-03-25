#!/bin/bash
JMX_PORT=KAFKA_JMX_PORT

# run any extra scripts required
for script in $(ls /kafka.d/); do
  echo "running script ${script}"
  /kafka.d/${script}
done

# this will update /etc/kafka/server.properties with any ENV vars that start KAFKA_
# the remaining part of the ENV var name should be the kafka properties in upper case
# with .'s replaced by _
#
# i.e.
# KAFKA_BROKER_ID=1 
# will be added as
# broker.id=1
# in /etc/kafka/server.properties
/usr/local/bin/update-server-properties
${KAFKA_HOME}/bin/kafka-server-start.sh /etc/kafka/server.properties