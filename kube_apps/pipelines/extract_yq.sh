#!/bin/sh

pat=${pat_val}
myjson=$(curl -u :$pat https://dev.azure.com/bogdan0109/houseofus/_apis/build/builds?definitions=25&resultFilter=succeeded&statusFilter=completed&maxBuildsPerDefinition=1&queryOrder=finishTimeDescending)
echo $myjson > test.json
correct=$(jq -r '[.value[] | {buildNumber,result} | select (.result == "succeeded")] | limit(1;.[]) ' test.json)
var1=$(jq -r '.buildNumber' <<< $correct)
echo "var1: $var1"
echo "##vso[task.setvariable variable=lastbuildNumber]'20220626.3'"
#img=$(yq e '.spec.template.spec.containers[0].image' kube_apps/kuma/deploy-kuma.yaml)
#echo "img is : $img"
#echo "##vso[task.setvariable variable=last_buildNumber]$img"
