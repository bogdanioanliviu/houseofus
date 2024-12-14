#!/bin/sh

img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/diun/deploy-diun.yaml)
tag=${img#*:}
echo "tag is : $tag"
echo "img is : $img"
echo "##vso[task.setvariable variable=img]$img"