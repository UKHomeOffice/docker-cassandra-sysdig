FROM quay.io/sysdig/cassandra:2.1.15.0

# Don't upgrade cassandra
RUN apt-mark hold cassandra

RUN apt-get update && apt-get upgrade -y

# Chagne cassandra compaction throughput to unlimited
RUN sed -i "s|^compaction_throughput_mb_per_sec:.*$|compaction_throughput_mb_per_sec: 0|" "$CASSANDRA_CONFIG/cassandra.yaml"

# Increase the number of cores doing compaction
RUN sed -i "s|.*concurrent_compactors:.*$|concurrent_compactors: 2|" "$CASSANDRA_CONFIG/cassandra.yaml"

# Change permissions on cassandra logfile
RUN touch /var/log/cassandra/system.log && \
    chmod 700 /var/log/cassandra && \
    chmod 600 /var/log/cassandra/system.log
