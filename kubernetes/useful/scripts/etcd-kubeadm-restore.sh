#!/bin/bash

# The --data-dir will be created by the following command, and the etcd-backup.db is
# the location for the backup you want to restore.

# You should also make sure that in the `/etc/kubernetes/manifests/etcd.yaml` that etcd is pointing
# to the location that you just restored the backup to. In this case `/opt/etcd-data/`
ETCDCTL_API=3 etcdctl --data-dir /opt/etcd-data/ snapshot restore etcd-backup.db
