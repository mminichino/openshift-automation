# openshift-automation
OpenShift on vSphere Automation Scripts

Deploy OCP on vSphere with these utilities.

1) Login to, or create, the OCP admin system (i.e. a RHEL/CentOS 7/8 VM)
2) Pull the mminichino/ansible-playbooks repository into $HOME/playbooks
3) Create OCP directory in $HOME/ocp
4) Pull the mminichino/openshift-automation repository into $HOME/ocp/bin
5) Create $HOME/OpenShift_install-config.yaml per OCP documentation
6) Create ${HOME}/append-bootstrap.ign per OCP documentation
7) Create $HOME/pull-secret/pull-secret.json with your pull secrets
8) Mount the HTTP path for bootstrap.ign as /install
9) Create OCP folder in vSphere
10) Deploy RHCOS templates for bootstrap, master, and worker nodes into OCP folder
11) Add Configuration Parameter guestinfo.ignition.config.data.encoding and set it to base64
12) Add Configuration Parameter disk.EnableUUID and set it to TRUE
13) Create $HOME/playbooks/group_vars/all/vault.yaml with vsphere_address, vsphere_username and vsphere_password
14) Add ocp_vsphere_folder, ocp_vsphere_vm_folder, vsphere_datacenter, oslab_datastore, and esx2_host (ocp_vsphere_folder and ocp_vsphere_vm_folder are the same in this example) to vault.yaml
15) Create oslab_host_list with the bootstrap, master, and worker nodes with name, mac, and template name attributes in vault.yaml
16) Create an appropriate $HOME/playbooks/.vault_password 
17) Configure DHCP statuc mappings for bootstrap, master, and worker hosts and Load Balancer VIPs and Pools for master and worker nodes
18) Optionally if you will use a mirror registry, run set-ocp-registry-environment.sh to do the inital setup of the mirror registry
19) In $HOME/ocp run bin/prepOpenShift.sh
20) When the cluster is up run bin/approve-csr-reqs.sh to complete the install
21) Optionally if you use a mirror OCP registry, use the fix-pull-secret.sh, fix-sample-registry.sh, mirror-oper-catalog.sh, and mirror-trident.sh scripts to update the mirror registry
22) Optionally you can use storagegrid-image-registry.sh to configure OCP to use StorageGRID for the Image Registry

````
$ cd ocp
$ bin/prepOpenShift.sh
$ bin/approve-csr-reqs.sh
````

Example oslab_host_list construct:
````
oslab_host_list:
  - name: bootstrap-0
    mac: 00:50:xx:xx:xx:xx
    template: RHCOS-bootstrap
  - name: master-0
    mac: 00:50:xx:xx:xx:xx
    template: RHCOS-master
  - name: worker-0
    mac: 00:50:xx:xx:xx:xx
    template: RHCOS-worker
````
