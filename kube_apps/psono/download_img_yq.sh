#!/bin/sh
file=$1
img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/psono/$file)
echo "img is : $img"
echo "##vso[task.setvariable variable=ha_img]$img"