#!/bin/sh
#
OSLABDIR=$(pwd)
PENDING=0
CONTINUE=1

export KUBECONFIG=${OSLABDIR}/oslab/auth/kubeconfig

while [ "$CONTINUE" -eq 1 ]
do

for STATE in $(oc get csr | awk '{print $4}')
do
    if [ "$STATE" = "Pending" ]
    then
       PENDING=1
       break
    fi
done

if [ "$PENDING" -eq 1 ]
then
    oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
else
    echo "No pending requests."
    CONTINUE=0
fi

done
