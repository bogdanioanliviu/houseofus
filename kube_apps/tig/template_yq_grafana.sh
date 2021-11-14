#!/bin/sh

yq e -i '.spec.template.spec.containers[0].env[1].value = env(Grafana_Admin_pass)' kube_apps/tig/deploy-grafana.yaml

