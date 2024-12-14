#!/bin/sh

yq e -i '.spec.template.spec.containers[0].env[0].value = env(GANDI_APIKEY)' kube_apps/gandi-dns/deploy-gandi-dns.yaml
