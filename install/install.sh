#! /bin/bash

mkdir -p rosa/rosa_install
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.12.15/openshift-client-linux-4.12.15.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.12.15/openshift-install-linux-4.12.15.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz
tar -xvf openshift-client-linux-4.12.15.tar.gz
tar -xvf openshift-install-linux-4.12.15.tar.gz
sudo tar -xvf rosa-linux.tar.gz --directory /usr/local/bin/
sudo chmod +x /usr/local/bin/rosa
sudo dnf install tree -y
sudo dnf install jq -y
rm -rf openshift-install-linux* openshift-client* README.md install.sh rosa-linux.tar.gz
sudo mv oc kubectl openshift-install /usr/local/bin/