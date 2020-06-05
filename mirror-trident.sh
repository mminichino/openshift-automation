#!/bin/sh
#
REGISTRY=""
function print_usage () {
   echo "$0 -r registry"
   exit 1
}

while getopts r: optargs
do
    case "${optargs}" in
        r) REGISTRY=$OPTARG
           ;;
       \?) print_usage
           ;;
    esac
done

if [ -z "$REGISTRY" ]
then
   print_usage
fi

echo "Registry: $REGISTRY"

export LOCAL_REGISTRY="${REGISTRY}:5000"

for TRIDENT_RELEASE in $(curl -sH 'Accept:application/json' https://registry.hub.docker.com/v2/repositories/netapp/trident/tags | jq -r '.results|.[]|.name' | head -n 3)
do
  oc image mirror -a ${HOME}/pull-secret/pull-secret.json docker.io/netapp/trident:${TRIDENT_RELEASE} ${LOCAL_REGISTRY}/netapp/trident:${TRIDENT_RELEASE}
done
