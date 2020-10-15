"""A simple script to convert ENV variables to Java properties."""
#!/usr/bin/env python3

import os

blacklist = ['KAFKA_JMX_PORT', 'KAFKA_VERSION', 'KAFKA_HOME', 'KAFKA_HEAP_OPTS']
properties_file = "/etc/kafka/server.properties"
properties = {}

env_args = [env_arg for env_arg in os.environ if env_arg.startswith('KAFKA_') and env_arg not in blacklist]

for env_arg in env_args:
    value = os.environ[env_arg]
    properties[env_arg.replace('KAFKA_', '').lower().replace('_', '.')] = value

with open(properties_file, 'w') as f:
    for key, value in properties.items():
        f.write('%s=%s\n' % (key, value))
