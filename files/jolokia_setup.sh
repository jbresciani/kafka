#!/bin/bash
sed -i "s/^hostPort:.*/hostPort:\ 127.0.0.1:${KAFKA_JMX_PORT}/g" "/etc/kafka/jmx_prometheus_exporter.yml"
