#!/bin/sh
#
DATE=$(date '+%H%M%S%m%d%y')
TMPFILE=$(mktemp)
TMPFILEB=$(mktemp)
TMPFILEC=$(mktemp)
STEP=0
BASEDIR=$(pwd)

while getopts s optargs
do
    case "${optargs}" in
        s) STEP=1;;
    esac
done

if [ -d ./oslab ]
then
echo "Moving old oslab directory ..."

mv oslab oslab.$DATE

fi

echo -n "Creating new install directory... "
mkdir ./oslab
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo -n "Copying install config to install directory ... "
cp ${HOME}/OpenShift_install-config.yaml ./oslab/install-config.yaml
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo "Creating manifests ..."
./openshift-install create manifests --dir=${BASEDIR}/oslab
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo -n "Editing cluster-scheduler-02-config.yml ..."
sed -e 's/mastersSchedulable: true/mastersSchedulable: False/' ./oslab/manifests/cluster-scheduler-02-config.yml > $TMPFILE
mv $TMPFILE ./oslab/manifests/cluster-scheduler-02-config.yml
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo "Creating ignition configs..."
./openshift-install create ignition-configs --dir=${BASEDIR}/oslab
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo -n "Copy append-bootstrap ... "
cp ${HOME}/append-bootstrap.ign ./oslab
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo -n "Copy bootstrap ... "
cp ${BASEDIR}/oslab/bootstrap.ign /install/bootstrap.ign
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo -n "Convert to base64 ..."
base64 -w0 ./oslab/master.ign > ./oslab/master.64
base64 -w0 ./oslab/worker.ign > ./oslab/worker.64
base64 -w0 ./oslab/append-bootstrap.ign > ./oslab/append-bootstrap.64
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo -n "Editing update template Ansible yaml ... "
sed -e "s/GUESTINFOBOOTSTRAP/$(cat oslab/append-bootstrap.64)/" ${HOME}/playbooks/edit_oslab_template.yaml > $TMPFILE
sed -e "s/GUESTINFOMASTER/$(cat oslab/master.64)/" $TMPFILE > $TMPFILEB
sed -e "s/GUESTINFOWORKER/$(cat oslab/worker.64)/" $TMPFILEB > $TMPFILEC

rm $TMPFILE
rm $TMPFILEB

mv $TMPFILEC ${HOME}/playbooks/update_oslab_template.yaml
echo "Done."

if [ "$STEP" -eq 1 ]
then
echo -n "Continue? [y/n]: "
read ANSWER
[ "$ANSWER" = "n" ] && exit 0
fi

echo "Run vSphere playbooks ... "
cd ${HOME}/playbooks

ansible-playbook update_oslab_template.yaml

ansible-playbook create_oslab_vms.yaml

ansible-playbook change_oslab_vms_mac.yaml

ansible-playbook start_oslab_vms.yaml
echo "Done."

##
