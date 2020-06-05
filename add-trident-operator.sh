#!/bin/sh
#
TRIDENTDIR=""
function print_usage () {
   echo "$0 -f directory"
   exit 1
}

while getopts f: optargs
do
    case "${optargs}" in
        f) TRIDENTDIR=$OPTARG
           ;;
       \?) print_usage
           ;;
    esac
done

if [ -z "$TRIDENTDIR" -o ! -f "${TRIDENTDIR}/tridentctl" ]
then
   print_usage
fi

cd $TRIDENTDIR

if [ "$(oc version | grep "^Kubernetes" | sed -n -e 's/^.*v[0-9]*\.\([0-9]*\)\.[0-9]*.*$/\1/p')" -ge 16 ]
then
   oc create -f deploy/crds/trident.netapp.io_tridentprovisioners_crd_post1.16.yaml
else
   oc create -f deploy/crds/trident.netapp.io_tridentprovisioners_crd_pre1.16.yaml
fi

oc create namespace trident
oc create -f deploy/bundle.yaml

echo "Waiting for Trident Operator ..."
while true
do
RUNPOD=$(oc get pods -n trident 2>/dev/null | grep "^trident-operator" | awk '{print $2}' | sed -e 's/^\([0-9]*\)\/[0-9]*$/\1/')
NUMPOD=$(oc get pods -n trident 2>/dev/null | grep "^trident-operator" | awk '{print $2}' | sed -e 's/^[0-9]*\/\([0-9]*\)$/\1/')
STATE=$(oc get pods -n trident 2>/dev/null | grep "^trident-operator" | awk '{print $3}')

if [ -n "$RUNPOD" -a -n "$NUMPOD" ]
then
   if [ "$RUNPOD" -eq "$NUMPOD" -a "$STATE" = "Running" ]
   then
      break
   fi
fi
done

oc create -f deploy/crds/tridentprovisioner_cr.yaml
