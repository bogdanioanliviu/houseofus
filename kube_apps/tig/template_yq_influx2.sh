#!/bin/sh

yq e -i '.data.DOCKER_INFLUXDB_INIT_PASSWORD = env(INFLUXDB_INIT_PASSWORD)' kube_apps/tig/secrets.yaml
yq e -i '.data.DOCKER_INFLUXDB_INIT_ADMIN_TOKEN = env(INFLUXDB_INIT_ADMIN_TOKEN)' kube_apps/tig/secrets.yaml


