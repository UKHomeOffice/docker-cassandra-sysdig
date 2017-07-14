#!/bin/bash
set -x

if [ -n "$CASSANDRA_SERVICE" ]; then
    ip=$(hostname --ip-address)

    CASSANDRA_SEEDS=$(host $CASSANDRA_SERVICE | \
        grep -v "not found" | \
        grep -v $ip | \
        sort | \
        head -$CASSANDRA_NUM_SEEDS | \
        cut -d" " -f4 | \
        tr '\n' ',' | \
        sed -e 's/,$//')
fi

if [ ! -z "$CASSANDRA_SEEDS" ]; then
    export CASSANDRA_SEEDS
fi

if [ "$CASSANDRA_SECURE" == "true" ]; then
    sed -i "s|^authenticator:.*$|authenticator: PasswordAuthenticator|" "$CASSANDRA_CONFIG/cassandra.yaml"
    sed -i "s|^authorizer:.*$|authorizer: CassandraAuthorizer|" "$CASSANDRA_CONFIG/cassandra.yaml"
fi

if [ -n "$CASSANDRA_DATA_DIRS" ]; then
    sed -ri "/^    - \/var\/lib\/cassandra\/data/d" "$CASSANDRA_CONFIG/cassandra.yaml"
    for DIR in $CASSANDRA_DATA_DIRS; do
        sed -ri "/data_file_directories:/a\    - $DIR" "$CASSANDRA_CONFIG/cassandra.yaml"
    done
fi

# Enable tls on cassandra intra node communication
if [ "$CASSANDRA_TLS" == "true" ] && [ -e ${CASSANDRA_KEYSTORE} ] && [ ! -z ${CASSANDRA_KEYSTORE_PASSWORD} ] && [ -e ${CASSANDRA_TRUSTSTORE} ] && [ ! -z ${CASSANDRA_TRUSTSTORE_PASSWORD} ]; then
    sed -i "s|internode_encryption:.*$|internode_encryption: all|" "$CASSANDRA_CONFIG/cassandra.yaml"
    sed -i "s|keystore:.*$|keystore: ${CASSANDRA_KEYSTORE}|" "$CASSANDRA_CONFIG/cassandra.yaml"
    sed -i "s|keystore_password:.*$|keystore_password: ${CASSANDRA_KEYSTORE_PASSWORD}|" "$CASSANDRA_CONFIG/cassandra.yaml"
    sed -i "s|truststore:.*$|truststore: ${CASSANDRA_TRUSTSTORE}|" "$CASSANDRA_CONFIG/cassandra.yaml"
    sed -i "s|truststore_password:.*$|truststore_password: ${CASSANDRA_TRUSTSTORE_PASSWORD}|" "$CASSANDRA_CONFIG/cassandra.yaml"
fi

/docker-entrypoint.sh "$@"
