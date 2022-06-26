#!/bin/sh

pat=${pat_val}
myjson=$(curl -u :$pat https://dev.azure.com/bogdan0109/houseofus/_apis/build/builds?definitions=25&resultFilter=succeeded&statusFilter=completed&maxBuildsPerDefinition=1&queryOrder=finishTimeDescending)
echo $myjson > test.json
lstbuild_nr=$(jq -r '.value[0].buildNumber' test.json)
echo "$lstbuild_nr"
echo "##vso[task.setvariable variable=lastbuildNumber]$lstbuild_nr"
#img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/kuma/deploy-kuma.yaml)
#echo "img is : $img"
#echo "##vso[task.setvariable variable=last_buildNumber]$img"
