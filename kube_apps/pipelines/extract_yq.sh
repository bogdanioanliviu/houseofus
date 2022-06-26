#!/bin/sh

myjson=$(curl https://dev.azure.com/bogdan0109/houseofus/_apis/build/builds?definitions=25&resultFilter=succeeded&statusFilter=completed&maxBuildsPerDefinition=1&queryOrder=finishTimeDescending )
echo $myjson

#img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/kuma/deploy-kuma.yaml)
#echo "img is : $img"
#echo "##vso[task.setvariable variable=last_buildNumber]$img"
