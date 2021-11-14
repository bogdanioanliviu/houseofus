#!/bin/sh

img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/ha_nginx/deploy-ha_nginx.yaml)
echo "img is : $img"
echo "##vso[task.setvariable variable=ha_img]$img"