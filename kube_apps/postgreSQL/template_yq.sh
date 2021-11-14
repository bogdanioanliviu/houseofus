#!/bin/sh

yq e -i '.data.POSTGRES_USER = env(POSTGRES12_USER)' kube_apps/postgreSQL/configmap.yaml
yq e -i '.data.POSTGRES_PASSWORD = env(POSTGRES12_PASSWORD)' kube_apps/postgreSQL/configmap.yaml
