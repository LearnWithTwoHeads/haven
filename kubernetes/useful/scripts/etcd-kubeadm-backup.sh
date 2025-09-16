#!/bin/bash

# create /opt/etcd-backup dir, in this directory daily etcd-database backup will be stored
mkdir -p /opt/etcd-backup

# creating file name variable which have value of filename with current datetime
FILE_NAME=etcd-$(date +"%F%T").db

# creting etcd path variable where full path for current backup file is defined
ETCD_PATH=/opt/etcd-backup/$FILE_NAME

# taking etcd database snapshot with etcdctl and saving it into /opt/etcd-backup dir, we have to specify 4 keys in order to interact with etcd server
# --endpoints it is the url of etcd server
# --cacert it is the full path where ca.crt file located
# --cert it is the full path where server.crt file located
# --key it is the full path where server.key file located
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save $ETCD_PATH
