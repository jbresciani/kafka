# Kafka

This container runs apache kafka using openjre 11 on debian slim. It is build from source pulled directly from http://apache.org/dist/kafka/ and verified against their provided sha512 sum. 

## Build Process

To build the image, you must provide the kafka and scala versions (if unprovided they default to 2.0.0 and 2.12 respectively)

```
KAFKA_VERSION=2.1.1
SCALA_VERSION=2.12
docker build . -f Dockerfile.base\
             --build-arg KAFKA_VERSION=${KAFKA_VERSION} \
             --build-arg SCALA_VERSION=${SCALA_VERSION} \
             -t jbresciani/kafka:${SCALA_VERSION}-${KAFKA_VERSION}-built-from-my-desk
```

## Running Locally

To use this container you will also need the base zookeeper container. the commands below will pull the latest zookeeper container from dockerhub, extract the IP from the docker container and pass it into the kafka container

```
KAFKA_VERSION=2.1.1
SCALA_VERSION=2.12
docker run --name zookeeper \
           --restart always \
           -p 2181:2181 \
           -d  \
           -e ZOO_STANDALONE_ENABLED=true \
           -h zookeeper \
           zookeeper
ZOOKEEPER_IP=$(docker exec zookeeper hostname -i)
docker run --name kafka \
           --restart always \
           -d \
           -p 9092:9092 \
           -p 19092:19092 \
           -e KAFKA_ZOOKEEPER_CONNECT=${ZOOKEEPER_IP}:2181/kafka/mycluster \
           -h kafka \
           jbresciani/kafka:${SCALA_VERSION}-${KAFKA_VERSION}-built-from-my-desk
```

(if you are not building the container on your own you can use the tag ${SCALA_VERSION}-${KAFKA_VERSION}-latest to pull from dockerhub)

Kafka will now be listening to connections on your local machine.

__** WARNING, without mounting in a folder to /var/lib/kafka/logs all data is stored in the VM and will be lost on container replacement, similar issues will arise with the zookeeper container **__

## Configuring Kafka

Any kafka server property can be set using environmental variables. To make a change follow these 3 steps

1.) replace all dots (.) with underscores (_)
2.) uppercase the property key
3.) prefix the variable name with KAFKA_

i.e.
```
KAFKA_ZOOKEEPER_CONNECT=1.1.1.1:2181/kafka/mycluster
```
will set
```
zookeeper.connect=1.1.1.1:2181/kafka/mycluster
```
in /etc/kafka/server.properties

```
KAFKA_BROKER_ID=42
```
will set
```
broker.id=42
```
in /etc/kafka/server.properties

Java settings should be added to the env var "KAFKA_HEAP_OPTS" which defaults to 
```
-Xmx3G -Xms3G -XX:+HeapDumpOnOutOfMemoryError -XX:MetaspaceSize=96m -XX:+UseG1GC
```

## Kafka CLI commands

Kafka commands exist in the container at /opt/kafka so all kafka commands can be run using 

```
ZOOKEEPER_IP=$(docker exec zookeeper hostname -i)
docker exec kafka /opt/kafka/bin/kafka-topics.sh --list --zookeeper ${ZOOKEEPER_IP}:2181/kafka/mycluster
 
```

## AUTH

The authenticated port 19092 is enabled by default, it is running the protocol SASL_PLAINTEXT and will accept SCRAM-SHA-256 or SCRAM-SHA-512 passwords.

A user named "admin" with a password of "badpassword" are created by the container at startup. They can, and should, be changed by altering the ENV vars "BROKER_USERNAME and BROKER_PASSWORD respectively.

## Defaults

The following defaults are set.

```
BROKER_USERNAME="admin"
BROKER_PASSWORD="badpassword"
EXTRA_ARGS='-name kafkaServer -loggc -javaagent:/opt/jmx_prometheus_javaagent/jmx_prometheus_javaagent.jar=8080:/etc/kafka/jmx_prometheus_exporter.yml -javaagent:/opt/jolokia/jolokia-jvm-agent.jar=port=9099 -Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf'
KAFKA_HEAP_OPTS="-Xmx3G -Xms3G -XX:+HeapDumpOnOutOfMemoryError -XX:MetaspaceSize=96m -XX:+UseG1GC"
KAFKA_HOME="/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_JMX_PORT="9090"
KAFKA_VERSION="${KAFKA_VERSION}"
SCALA_VERSION="${SCALA_VERSION}"
KAFKA_BROKER_ID="1"
KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://localhost:9092,SASL_PLAINTEXT://localhost:19092"
KAFKA_LISTENERS="PLAINTEXT://0.0.0.0:9092,SASL_PLAINTEXT://0.0.0.0:19092"
KAFKA_LOG_DIR="/var/lib/kafka/logs"
KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR="1"
KAFKA_SASL_ENABLED_MECHANISMS="SCRAM-SHA-256,SCRAM-SHA-512"
KAFKA_SASL_MECHANISM="SCRAM-SHA-256"
KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL="SCRAM-SHA-512"
KAFKA_SECURITY_INTER_BROKER_PROTOCOL="SASL_PLAINTEXT"
KAFKA_UNCLEAN_LEADER_ELECTION_ENABLE="true"
KAFKA_ZOOKEEPER_CONNECT="172.17.0.2:2181/kafka/mycluster"
KAFKA_ZOOKEEPER_SESSION_TIMEOUT_MS="30000"
```

## Client Connections

For java clients you will need to create the file /path/to/file/kafka_client_jaas.conf with the following content (adjusted accordingly if you change the default user/pass)
```
KafkaClient {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="admin"
    password="badpassword";
};
```
and load it at java start time with the flag
```
-Djava.security.auth.login.config=/path/to/file/kafka_client_jaas.conf
```
you will also require
```
sasl.mechanism=SCRAM-SHA-512
security.protocol=SASL_PLAINTEXT
```
in your consumer/producer properties file
