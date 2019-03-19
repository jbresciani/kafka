# based on the file
FROM openjdk:11-jre-slim
LABEL maintainer="Jacob Bresciani"

ARG KAFKA_VERSION=2.0.0
ARG SCALA_VERSION=2.12

ENV BROKER_USERNAME="admin" \
    BROKER_PASSWORD="badpassword" \
    EXTRA_ARGS='-name kafkaServer -loggc -javaagent:/opt/jmx_prometheus_javaagent/jmx_prometheus_javaagent.jar=8080:/etc/kafka/jmx_prometheus_exporter.yml -javaagent:/opt/jolokia/jolokia-jvm-agent.jar=port=9099 -Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf' \
    KAFKA_HEAP_OPTS="-Xmx3G -Xms3G -XX:+HeapDumpOnOutOfMemoryError -XX:MetaspaceSize=96m -XX:+UseG1GC" \
    KAFKA_HOME="/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}" \
    KAFKA_JMX_PORT="9090" \
    KAFKA_VERSION="${KAFKA_VERSION}" \
    SCALA_VERSION="${SCALA_VERSION}" \
    KAFKA_BROKER_ID="1" \
    KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://localhost:9092,SASL_PLAINTEXT://localhost:19092" \
    KAFKA_LISTENERS="PLAINTEXT://0.0.0.0:9092,SASL_PLAINTEXT://0.0.0.0:19092" \
    KAFKA_LOG_DIR="/var/lib/kafka/logs" \
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR="1" \
    KAFKA_SASL_ENABLED_MECHANISMS="SCRAM-SHA-256,SCRAM-SHA-512" \
    KAFKA_SASL_MECHANISM="SCRAM-SHA-256" \
    KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL="SCRAM-SHA-512" \
    KAFKA_SECURITY_INTER_BROKER_PROTOCOL="SASL_PLAINTEXT" \
    KAFKA_UNCLEAN_LEADER_ELECTION_ENABLE="true" \
    KAFKA_ZOOKEEPER_CONNECT="172.17.0.2:2181/kafka/mycluster" \
    KAFKA_ZOOKEEPER_SESSION_TIMEOUT_MS="30000"
    
 RUN apt-get update \
     && apt-get -y install gnupg2 \
                           python3 \
                           python3-pip \
                           python3-setuptools \
     && rm -rf /var/lib/apt/lists/* 

ADD http://apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.sha512 /tmp
ADD http://apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz /tmp
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar /opt/jmx_prometheus_javaagent/jmx_prometheus_javaagent.jar
ADD http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.6.0/jolokia-jvm-1.6.0-agent.jar /opt/jolokia/jolokia-jvm-agent.jar

COPY files/entrypoint.sh /
COPY files/update-server-properties.py /usr/local/bin/
COPY files/jmx_prometheus_exporter.yml /etc/kafka/jmx_prometheus_exporter.yml

WORKDIR /tmp
RUN if ! (gpg --print-md sha512 kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz | diff kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.sha512 -); then \
    echo "bad sha512 checksum"; \
    exit 1; \
    fi

RUN tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
    && rm /tmp/kafka*

RUN adduser --shell /bin/bash \
            --home /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} \
            kafka \
    && mkdir -p ${KAFKA_LOG_DIR} \
    && mkdir /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/logs \
    && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka \
    && mkdir -p /var/log/zookeeper \
    && chown -R kafka.kafka /var/log/zookeeper \
    && chown -R kafka.kafka ${KAFKA_LOG_DIR} \
    && chown -R kafka:kafka /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/logs \
    && chown -R kafka:kafka /etc/kafka \
    && chmod 755 /opt/jmx_prometheus_javaagent \
    && chmod 644 /opt/jmx_prometheus_javaagent/* \
    && chmod 755 /var/log/zookeeper \
    && chmod 755 /opt/jolokia \
    && chmod 644 /opt/jolokia/*

WORKDIR /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
USER kafka

EXPOSE 8080/tcp 9090/tcp 9092/tcp 9099/tcp 19092/tcp

CMD ["/bin/bash"]

ENTRYPOINT [ "/entrypoint.sh" ]