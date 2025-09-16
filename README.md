# Running Journal of learnings

## 09/11/2025

- [hetzner-k3s](https://vitobotta.github.io/hetzner-k3s/) is awesome, you can create an HA Kubernetes cluster on Hetzner for very cheap
  - The configuration file is relatively simple as well, with a lot of good documentation on the site, i've included a sample documentation [here](./kubernetes/self-hosted/cloud/hetzner/configuration/hetzner-k3s.yaml)

## 09/12/2025

- [cloudnativepg](https://cloudnative-pg.io/documentation/1.27) is a great product from what I am seeing right now. It was super easy to setup and configure with great documentation
  - The purpose of `cloudnativepg` is to run PostgreSQL within Kubernetes with ease. The idea being your compute and storage can be as collocated as possible without having to use an external service like RDS or something
  - It also documents that it is advisable to reserve nodes for your PostgreSQL cluster, basically only run Postgres workloads on a certain set of nodes [here](https://cloudnative-pg.io/documentation/1.27/architecture/#reserving-nodes-for-postgresql-workloads). You can do this via taints/tolerations, or node selectors
  - You can configure backups via Object store or native Kubernetes volume snapshots and that is documented [here](https://cloudnative-pg.io/documentation/1.27/backup/)
  - [Important documentation](https://cloudnative-pg.io/documentation/1.27/appendixes/backup_volumesnapshot/#how-to-configure-volume-snapshot-backups) on how to configure `VolumeSnapshot` backups
  - [Important documentation](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/) for using the new way of backing up data to the cloud
  - I learned how to do backups and recovery from an s3 bucket/object store
- k3s
  - You can rotate certificates manually via [here](https://docs.k3s.io/cli/certificate#rotating-client-and-server-certificates)
  - Certificates will automatically rotate if they are within 120 days of expiry

# 09/13/2025

- k3s
  - Learned how to backup and restore etcd data, it seems like the `--node-ip` argument is important because that is where the `k3s` program looks for listening services
    - The script sample is [here](./kubernetes/useful/scripts/k3s-cluster-reset-backup.sh)

# 09/16/2025

- kubeadm
  - Backing up and restoring etcd instructions [here](https://devopscube.com/backup-etcd-restore-kubernetes/)
  - The script to backup `etcd` for `kubeadm` is located [here](./kubernetes/useful/scripts/etcd-kubeadm-backup.sh)
  - It seems as though if you want to stop the Kubernetes API server so that you can restore etcd, you can do so by moving the manifests out of the `/etc/kubernetes/manifests` directory
    ```bash
    sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
    ```
  - And to resume the service, you would just move the manifest back to the `/etc/kubernetes/manifests` directory
  - You can compress the backup file by using `gzip` or `zstd`, this is to incur lower storage costs on s3
  - To scrape metrics for all the control plane components, you should actually just run an agent within the cluster. My opinion is that you should just use the `otel` collector as a `daemonset`
