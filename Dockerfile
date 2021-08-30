ARG BASE_IMAGE=alpine:3.14.1
FROM ${BASE_IMAGE}

ARG GRAFANA_TGZ="grafana-latest.linux-x64-musl.tar.gz"

ARG GF_INSTALL_PLUGINS="grafana-timestream-datasource grafana-iot-sitewise-datasource grafana-azure-data-explorer-datasource grafana-azure-monitor-datasource grafana-discourse-datasource grafana-github-datasource grafana-googlesheets-datasource grafana-k6cloud-datasource grafana-kairosdb-datasource grafana-es-open-distro-datasource grafana-opensearch-datasource grafana-simple-json-datasource grafana-strava-datasource grafana-x-ray-datasource grafana-synthetic-monitoring-app grafana-worldmap-panel grafana-clock-panel grafana-piechart-panel grafana-polystat-panel grafana-singlestat-panel akumuli-datasource praj-ams-datasource anodot-datasource hadesarchitect-cassandra-datasource thalysantana-appcenter-datasource rackerlabs-blueflood-datasource bmchelix-ade-datasource yeya24-chaosmesh-datasource vertamedia-clickhouse-datasource foursquare-clouderamanager-datasource cognitedata-datasource sbueringer-consul-datasource marcusolsson-csv-datasource dalmatinerdb-datasource andig-darksky-datasource devicehive-devicehive-datasource abhisant-druid-datasource grafadruid-druid-datasource ayoungprogrammer-finance-datasource clarity89-finnhub-datasource verticle-flowhook-datasource gnocchixyz-gnocchi-datasource doitintl-bigquery-datasource mtanda-google-calendar-datasource fifemon-graphql-datasource groonga-datasource hawkular-datasource udoprog-heroic-datasource spotify-heroic-datasource humio-datasource ibm-apm-datasource yesoreyeram-infinity-datasource instana-datasource itrs-hub-datasource simpod-json-datasource marcusolsson-json-datasource paytm-kapacitor-datasource aquaqanalytics-kdbadaptor-datasource lightstep-metrics-datasource linksmart-hds-datasource linksmart-sensorthings-datasource goshposh-metaqueries-datasource meteostat-meteostat-datasource monasca-datasource monitoringartist-monitoringart-datasource radensolutions-netxms-datasource ntop-ntopng-datasource fastweb-openfalcon-datasource gridprotectionalliance-openhistorian-datasource oci-logs-datasource oci-metrics-datasource gridprotectionalliance-osisoftpi-datasource xginn8-pagerduty-datasource pixie-pixie-datasource sni-pnp-datasource camptocamp-prometheus-alertmanager-datasource jasonlashua-prtg-datasource pyroscope-datasource quasardb-datasource redis-datasource ccin2p3-riemann-datasource sidewinder-datasource fzakaria-simple-annotations-datasource innius-grpc-datasource skydive-datasource pue-solr-datasource frser-sqlite-datasource marcusolsson-static-datasource streamr-datasource fetzerch-sunandmoon-datasource teamviewer-datasource sni-thruk-datasource natel-usgs-datasource vertica-grafana-datasource ovh-warp10-datasource alexanderzobnin-zabbix-app voxter-app percona-percona-app bosun-app devopsprodigy-kubegraf-app ddurieux-glpi-app opennms-helm-app stagemonitor-elasticsearch-app"

# Make sure we have Gnu tar
RUN apk add --no-cache tar

COPY ${GRAFANA_TGZ} /tmp/grafana.tar.gz

# Change to tar xfzv to make tar print every file it extracts
RUN mkdir /tmp/grafana && tar xzf /tmp/grafana.tar.gz --strip-components=1 -C /tmp/grafana

FROM ${BASE_IMAGE}

ARG GF_UID="472"
ARG GF_GID="0"

ENV PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME

RUN apk add --no-cache ca-certificates bash tzdata && \
    apk add --no-cache openssl musl-utils libcrypto1.1>1.1.1l-r0 libssl1.1>1.1.1l-r0

# Oracle Support for x86_64 only
RUN if [ `arch` = "x86_64" ]; then \
      apk add --no-cache libaio libnsl && \
      ln -s /usr/lib/libnsl.so.2 /usr/lib/libnsl.so.1 && \
      wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk \
        -O /tmp/glibc-2.30-r0.apk && \
      wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-bin-2.30-r0.apk \
        -O /tmp/glibc-bin-2.30-r0.apk && \
      apk add --no-cache --allow-untrusted /tmp/glibc-2.30-r0.apk /tmp/glibc-bin-2.30-r0.apk && \
      rm -f /tmp/glibc-2.30-r0.apk && \
      rm -f /tmp/glibc-bin-2.30-r0.apk && \
      rm -f /lib/ld-linux-x86-64.so.2 && \
      rm -f /etc/ld.so.cache; \
    fi

COPY --from=0 /tmp/grafana "$GF_PATHS_HOME"

RUN if [ ! $(getent group "$GF_GID") ]; then \
      addgroup -S -g $GF_GID grafana; \
    fi

RUN export GF_GID_NAME=$(getent group $GF_GID | cut -d':' -f1) && \
    mkdir -p "$GF_PATHS_HOME/.aws" && \
    adduser -S -u $GF_UID -G "$GF_GID_NAME" grafana && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_PROVISIONING/notifiers" \
             "$GF_PATHS_PROVISIONING/plugins" \
             "$GF_PATHS_PROVISIONING/access-control" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chown -R "grafana:$GF_GID_NAME" "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING" && \
    chmod -R 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING"

EXPOSE 3000

COPY ./run.sh /run.sh

USER "$GF_UID"
ENTRYPOINT [ "/run.sh" ]