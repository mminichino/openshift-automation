#!/bin/sh
#
REGISTRY=""

while getopts r: optargs
do
    case "${optargs}" in
        r) REGISTRY=$OPTARG 
           ;;
    esac
done

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${HOME}/pull-secret/pull-secret.json

oc get secret/pull-secret -n openshift-config -o yaml

if [ -n "$REGISTRY" ]
then

oc create configmap registry-config --from-file=${REGISTRY}..5000=/opt/registry/certs/domain.crt -n openshift-config

oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge

oc patch configs.samples.operator.openshift.io/cluster --type merge --patch "{\"spec\":{\"samplesRegistry\":\"${REGISTRY}:5000\"}}"

fi
