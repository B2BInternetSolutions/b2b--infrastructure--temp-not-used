#!/bin/bash
# script that runs 
# https://kubernetes.io/docs/setup/production-environment/container-runtime

yum install -y vim yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# notice that only verified versions of Docker may be installed
# verify the documentation to check if a more recent version is available

yum install -y docker-ce
[ ! -d /etc/docker ] && mkdir /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

cat >> /etc/hosts << EOF
{
  10.36.1.184 control.example.com control
  10.36.1.140 worker1.example.com worker1
  10.36.1.151 worker2.example.com worker2
  10.36.1.155 worker3.example.com worker3
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

if [[ $HOSTNAME = control.example.com ]]
then
  firewall-cmd --add-port 6443/tcp --permanent
  firewall-cmd --add-port 2379-2380/tcp --permanent
  firewall-cmd --add-port 10250/tcp --permanent
  firewall-cmd --add-port 10251/tcp --permanent
  firewall-cmd --add-port 10252/tcp --permanent
fi

if echo $HOSTNAME | grep worker
then
  firewall-cmd --add-port 10250/tcp --permanent
  firewall-cmd --add-port 30000-32767/tcp --permanent
fi

systemctl restart firewalld
