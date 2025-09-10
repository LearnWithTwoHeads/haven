# Kubernetes

This is a directory dedicated to all things Kubernetes.

## Different Distributions and observations

### YKE
YKE (Yoofi's Kubernetes Engine) is a distribution created by me. It focuses on simple semantics of running various workloads that we encounter everyday as self-hosted Kubernetes clusters on various clouds using the cloud's version of a VM. So EC2 for AWS, Compute Engine for GKE, etc.

In order for YKE to work on a specific cloud, the cloud would have to support a way for the cluster to provision Persistent Volumes, and Ingress into the cluster via Layer 4 load balancers. As you provision the cluster, it comes with a variety of opinionated software including `cert-manager`, `traefik`, etc.

The configuration for a YKE cluster is in the [self hosted directory](./self-hosted/).

### GKE Autopilot
**Pricing:**
- Usage based. $0.10/hr/cluster, $32.28/vCPU/month (cpu), $3.57/GB/month (memory), $0.10/GB/month (storage/volumes)
- The above is for resources that you provision

**Pros:**
- Clusters are pretty easy to spin up without too much overhead
- Very easy to find how many vCPUs and total memory that all the workloads are taking up on the cluster

**Cons:**
- It seems as though Google automatically adjust your Memory requests when you submit any resource with a Pod spec to the API. However, for the CPU requests it maintains the number/figure that you declare in the Pod spec

**Overall assessment**
GKE Autopilot is pretty nice in the sense where you do not have to provision your own nodes, but the automatic adjustment of memory requests is a bit annoying to me. What if you want to pay less for your workloads because they do not need that much memory?
