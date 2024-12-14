#!/bin/sh

#yq e -i '.spec.template.spec.containers[0].env[5].value = env(telegram_token)' kube_apps/diun/deploy-diun.yaml
img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/diun/deploy-diun.yaml)
echo "img is : $img"
echo "##vso[task.setvariable variable=diun_img]$img"
