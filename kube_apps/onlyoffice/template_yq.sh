#!/bin/sh

yq e -i '.spec.template.spec.containers[0].env[1].value = env(JWT_SECRET)' kube_apps/onlyoffice/deploy-onlyoffice.yaml
yq e -i '.spec.template.spec.containers[0].env[5].value = env(DB_USER_onlyoffice)' kube_apps/onlyoffice/deploy-onlyoffice.yaml
yq e -i '.spec.template.spec.containers[0].env[6].value = env(DB_PWD_onlyoffice)' kube_apps/onlyoffice/deploy-onlyoffice.yaml

img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/onlyoffice/deploy-onlyoffice.yaml)
echo "img is : $img"
echo "##vso[task.setvariable variable=onlyoffice_img]$img"