#!/bin/sh

img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/kuma/deploy-kuma.yaml)
echo "img is : $img"
echo "##vso[task.setvariable variable=kuma_img]$img"
