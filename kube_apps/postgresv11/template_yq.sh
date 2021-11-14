#!/bin/sh

yq e -i '.data.POSTGRES_USER = env(POSTGRES11_USER)' kube_apps/postgresv11/secrets.yaml
yq e -i '.data.POSTGRES_PASSWORD = env(POSTGRES11_PASSWORD)' kube_apps/postgresv11/secrets.yaml
