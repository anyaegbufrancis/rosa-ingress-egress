#! /bin/bash
version="4.13.4"
mkdir -p rosa/rosa_install
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$version/openshift-client-linux-$version.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$version/openshift-install-linux-$version.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz
tar -xvf openshift-client-linux-$version.tar.gz
tar -xvf openshift-install-linux-$version.tar.gz
sudo tar -xvf rosa-linux.tar.gz --directory /usr/local/bin/
sudo chmod +x /usr/local/bin/rosa
sudo dnf install tree -y
sudo dnf install jq -y
rm -rf openshift-install-linux* openshift-client* README.md install.sh rosa-linux.tar.gz
sudo mv oc kubectl openshift-install /usr/local/bin/