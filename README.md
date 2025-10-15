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

## 09/13/2025

- k3s
  - Learned how to backup and restore etcd data, it seems like the `--node-ip` argument is important because that is where the `k3s` program looks for listening services
    - The script sample is [here](./kubernetes/useful/scripts/k3s-cluster-reset-backup.sh)

## 09/16/2025

- kubeadm
  - Backing up and restoring etcd instructions [here](https://devopscube.com/backup-etcd-restore-kubernetes/)
  - The script to backup `etcd` for `kubeadm` is located [here](./kubernetes/useful/scripts/etcd-kubeadm-backup.sh)
  - The script to restore a backup for `etcd` is located [here](./kubernetes/useful/scripts/etcd-kubeadm-restore.sh)
  - It seems as though if you want to stop the Kubernetes API server so that you can restore etcd, you can do so by moving the manifests out of the `/etc/kubernetes/manifests` directory
    ```bash
    sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
    ```
  - And to resume the service, you would just move the manifest back to the `/etc/kubernetes/manifests` directory
  - You can compress the backup file by using `gzip` or `zstd`, this is to incur lower storage costs on s3
  - To scrape metrics for all the control plane components, you should actually just run an agent within the cluster. My opinion is that you should just use the `otel` collector as a `daemonset`
- Some overall thoughts
  - I think that backing up and restoring etcd is way simpler with `k3s` than `kubeadm`, because it is built into `k3s`. You can provide configuration for automated backups when starting a `k3s` cluster
  - With `kubeadm` it is a whole lot more manual. You'd have to provide your own scripts for backing up and restoring

## 09/17/2025

- `ReplicaSet`
  - `ReplicaSet` is usually not used directly, but is indirectly provisioned via a `Deployment` which manages the `ReplicaSet`'s
  - It can own a non-homogeneous set of pods, as long as the selectors match
  - The reason to use a `Deployment` is because the `ReplicaSet`'s are managed for you (during rolling updates). For instance during rolling updates, if you use `ReplicaSet` directly, you'd need to write custom logic for replacing old pods with new ones
- `StatefulSet`
  - A [headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) publishes the IP Addresses of the pods in a particular `StatefulSet`, so you can address each pod like so:
    ```
    <pod-name>.<service-name>.<namespace>.svc.cluster.local
    ```
  - A use case of a `StatefulSet` is for addressing individual pods (if that is your use case), instead of addressing a `Service` that points to a `Deployment` and load balances across pods
  - If you want to network to a random pod instead of a particular pod, you can just point to the headless service
    ```
    <service-name>.<namespace>.svc.cluster.local
    ```

## 09/24/2025

- `talos`
  - Learned how to bootstrap talos on AWS EC2 instances. It was pretty seamless, within about 10 minutes I was able to get a Kubernetes cluster up and running
  - It is a bit weird though that you cannot ssh into the instances, since the Talos machine image doesn't have an ssh server

# 10/01/2025

- `Next.js`
  - `next.js` automatically optimizes fonts in the application when you use the `next/font` module. It will download font files at build time and host them with other static assets. You can eliminate unnecessary network requests with this
  - `next/image` optimizes images in a lot of ways
  - Make sure to set width and height on images identical to the aspect ratio of the original image
  - **Question**: What is layout shift in FE development?
  - pages are automatically nested in a layout if you have a `layout.tsx`, then any `page.tsx` nested under the layout will use the layout. On navigation only the page component re-renders not the layout
  - `next/link` allows for doing client side navigation to prevent full page refreshes when trying to navigate. The `Link` component also prefetches the page, so navigations to that said page will appear near instant
  - You can only use React Hooks in client components
  - Server components are default in `next.js` and they can be `async`
  - `loading.tsx` is a special file in `next.js` for rendering a component while data is being rendered
  - **Question**: What is `Suspense` and how would I use it?
    - Seems like it allows you to provide a fallback component while a wrapped component is fetching its data
    - You should look to use `Suspense` when a component relies on data fetching if you want that effect for the user

# 10/02/2025

- `Next.js`
  - You should move data fetching down to the components that need it
  - Debouncing is used when you need to limit the rate at which a function is firing

# 10/10/2025

- Networking
  - The first 24 bits (first three numbers in an IP Address), determine the network, while the last 8 bits determine the actual host
  - `192.168.123.255` and `192.168.123.0` are invalid IP Addresses because the host octect can not contain all 0s or all 1s
  - You can further divide a network into subnets by providing a subnet mask
  - CIDR notation `192.168.10.15/24`. This means the first 24 bits belong to the network portion leaving 8 bits for the host
    - The Broadcast Address is represented where all the host bits are set to 1, so in this case `192.168.10.255`
    - The Network Address is represented where all the host bits are set to 0, so in this case `192.168.10.0`. This identifies the network
    - The Address Range for this would be `192.168.10.1` -> `192.168.10.254`
    - The Subnet mask in this case will be `255.255.255.0`

# 10/15/2025

- OpenAI Agents SDK
  - The agents SDK allows for you to create multiple agents and chain them together for a coordinated purpose
  - This [here](https://openai.github.io/openai-agents-js/) is a great guide for using the Agents SDK in TypeScript
