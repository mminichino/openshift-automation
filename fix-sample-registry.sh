#!/bin/sh
#
REGISTRY=""
VERSION=""
function print_usage () {
   echo "$0 -r registry -v version"
   exit 1
}

while getopts r:v: optargs
do
    case "${optargs}" in
        r) REGISTRY=$OPTARG
           ;;
        v) VERSION=$OPTARG
           ;;
       \?) print_usage
           ;;
    esac
done

if [ -z "$REGISTRY" -o -z "$VERSION" ]
then
   print_usage
else
   CHECK=$(echo $VERSION | sed -e 's/^[0-9]*\.[0-9]*\.[0-9]*$/X/')
   if [ "$CHECK" != "X" ]
   then
      echo "Invalid format for OCP version: $VERSION"
      exit 1
   fi
   echo "Registry: $REGISTRY Version: $VERSION"
fi

export OCP_RELEASE=${VERSION}-x86_64
export LOCAL_REGISTRY="${REGISTRY}:5000"
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="${HOME}/pull-secret/pull-secret.json"
export RELEASE_NAME="ocp-release"

for imagestream in $(oc get imagestreams -n openshift -o json | jq -r '.items[]?.spec.tags[]?.from.name | select(startswith("admin"))'); do
   REMOTE_REGISTRY="registry.redhat.io"
   ORIGIFS=$IFS
   IFS='/'
   read -ra IMAGEDATA <<< "$imagestream"
   IFS=$ORIGIFS
   PACKAGE=${IMAGEDATA[1]}
   IMAGE=${IMAGEDATA[2]}
   if [ "${IMAGEDATA[1]}" = "openshift-release-dev" ]
   then
      REMOTE_REGISTRY="quay.io"
      TARGET_IMAGE=$(echo $IMAGE | sed -ne 's/^\(.*\)@.*$/\1/p')
   else
      TARGET_IMAGE=$IMAGE
   fi
   oc image mirror -a ${LOCAL_SECRET_JSON} ${REMOTE_REGISTRY}/${PACKAGE}/${IMAGE} ${LOCAL_REGISTRY}/${PACKAGE}/${TARGET_IMAGE}
done

oc import-image jenkins --all --confirm -n openshift
oc import-image nodejs --all --confirm -n openshift
