#!/bin/sh
#
REGION="us-east-1"

echo -n "StorageGRID S3 Access Key: "
read SGKEY

echo -n "StorageGRID S3 Secret Key: "
read SGSECRET

echo -n "StorageGRID LB Bucket: "
read BUCKET

echo -n "StorageGRID LB End Point (FQDN): "
read LBENDPOINT

echo -n "StorageGRID Region: [$REGION]: "
read NEWREGION

if [ -n "$NEWREGION" ]
then
   REGION=$NEWREGION
fi

#SGENCKEY=$(echo $SGKEY | base64 -w0)
#SGENCSECRET=$(echo $SGSECRET | base64 -w0)
LBENDPOINT=$(echo "https://$LBENDPOINT")

echo "S3 Key:    $SGKEY"
echo "Secret:    $SGSECRET"
echo "Bucket:    $BUCKET"
echo "End Point: $LBENDPOINT"
echo "Region:    $REGION"

echo -n "Continue? [y/n] "
read ANSWER

if [ "$ANSWER" = "n" ]
then
   exit 1
fi

if [ "$(oc get secret image-registry-private-configuration-user -n openshift-image-registry -o json | jq -r '.kind')" = "Secret" ]
then
    echo "Removing old secret ..."
    oc delete secret image-registry-private-configuration-user -n openshift-image-registry
fi

oc create secret generic image-registry-private-configuration-user \
        --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY=${SGKEY} \
        --from-literal=REGISTRY_STORAGE_S3_SECRETKEY=${SGSECRET} \
        --namespace openshift-image-registry

oc patch configs.imageregistry.operator.openshift.io/cluster --type merge --patch "{\"spec\":{\"storage\": {\"s3\": {\"bucket\":\"${BUCKET}\",\"region\":\"${REGION}\",\"regionEndpoint\":\"${LBENDPOINT}\"}}}}"
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge --patch '{"spec":{"defaultRoute":true}}'
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
