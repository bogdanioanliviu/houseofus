#!/bin/sh

img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/nextcloud/deploy-nextcloud.yaml)
echo "img is : $img"
echo "##vso[task.setvariable variable=nextcloud_img]$img"