#!/bin/sh
#
REGISTRY=""
VERSION=""
LOCAL_VERSION="1"
TMPFILE=$(mktemp)
function print_usage () {
   echo "$0 -r registry -v version [ -l local_version ]"
   exit 1
}

while getopts r:v:l: optargs
do
    case "${optargs}" in
        r) REGISTRY=$OPTARG
           ;;
        v) VERSION=$OPTARG
           ;;
        l) LOCAL_VERSION=$OPTARG
           ;;
       \?) print_usage
           ;;
    esac
done

if [ -z "$REGISTRY" -o -z "$VERSION" ]
then
   print_usage
else
#   CHECK=$(echo $VERSION | sed -e 's/^[0-9]*\.[0-9]*\.[0-9]*$/X/')
   CHECK=$(echo $VERSION | sed -e 's/^[0-9]*\.[0-9]*$/X/')
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

podman login ${LOCAL_REGISTRY}

podman login quay.io

podman login registry.redhat.io

oc adm catalog build \
    --appregistry-org redhat-operators \
    --from=registry.redhat.io/openshift4/ose-operator-registry:v${VERSION} \
    --to=${LOCAL_REGISTRY}/olm/redhat-operators:v${LOCAL_VERSION} \
    -a ${XDG_RUNTIME_DIR}/containers/auth.json \
    --insecure

oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

oc adm catalog mirror \
    ${LOCAL_REGISTRY}/olm/redhat-operators:v${LOCAL_VERSION} \
    ${LOCAL_REGISTRY} \
    -a ${XDG_RUNTIME_DIR}/containers/auth.json \
    --insecure

oc apply -f ./redhat-operators-manifests

if [ -f "$TMPFILE" ]
then
cat << EOF > $TMPFILE
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: ${LOCAL_REGISTRY}/olm/redhat-operators:v${LOCAL_VERSION}
  displayName: My Operator Catalog
  publisher: grpc
EOF
   MYCATALOGNAME=$(oc get catalogsource -n openshift-marketplace -o json | jq -r '.items|.[]|.metadata.name')
   if [ "$MYCATALOGNAME" = "my-operator-catalog" ]
   then
      OPERATION="replace"
   else
      OPERATION="create"
   fi
   oc $OPERATION -f $TMPFILE
   rm $TMPFILE
else
   echo "Error: can not access temp file, can not replace catalog source."
fi

