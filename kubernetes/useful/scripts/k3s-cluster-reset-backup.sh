#!/bin/bash

# Right here the `node-ip` is important for the server to locate where etcd is listening and other
# services on the control plane.

k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=path_to_snapshot_in_bucket \
  --etcd-s3 \
  --etcd-s3-endpoint=s3.amazonaws.com \
  --etcd-s3-region=us-east-1 \
  --etcd-s3-bucket=some-bucket \
  --etcd-s3-access-key=... \
  --etcd-s3-secret-key=... \
  --etcd-s3-folder=etcd-backups \
  --node-ip=10.0.1.1
