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

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}

if [ -f ./openshift-install ]
then
   mv openshift-install openshift-install.$(date +\%Y-%m-%d-%H-%M-%S)
fi

oc adm -a ${LOCAL_SECRET_JSON} release extract \
--command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}"

