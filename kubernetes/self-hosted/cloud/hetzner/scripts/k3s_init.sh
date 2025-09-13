#!/bin/bash

set -e

MASTER_NODE_NAME="kubernetes-master-node"
WORKER_NODE_0_NAME="kubernetes-worker-node-0"
WORKER_NODE_1_NAME="kubernetes-worker-node-1"
MASTER_NODE_PRIVATE_IP="10.0.1.1"

echo "Starting K3s cluster initialization..."

echo "Getting server public IPs..."
MASTER_IP=$(hcloud server ip $MASTER_NODE_NAME)
WORKER_0_IP=$(hcloud server ip $WORKER_NODE_0_NAME)
WORKER_1_IP=$(hcloud server ip $WORKER_NODE_1_NAME)

echo "Master node IP: $MASTER_IP"
echo "Worker node 0 IP: $WORKER_0_IP"
echo "Worker node 1 IP: $WORKER_1_IP"

echo "Initializing master node..."
ssh -o StrictHostKeyChecking=no root@$MASTER_IP <<'EOF'
apt-get update -y
curl https://get.k3s.io | INSTALL_K3S_EXEC="--disable-cloud-controller" sh -s - --disable=traefik --disable-cloud-controller --kubelet-arg cloud-provider=external
exit 0
EOF

echo "Master node initialized successfully"

echo "Retrieving k3s token from master node..."
REMOTE_TOKEN=$(ssh -o StrictHostKeyChecking=no root@$MASTER_IP cat /var/lib/rancher/k3s/server/node-token)

if [ -z "$REMOTE_TOKEN" ]; then
  echo "L Failed to retrieve k3s token"
  exit 1
fi

echo "Token retrieved: ${REMOTE_TOKEN:0:10}..."

echo "Joining worker node 0 to the cluster..."
ssh -o StrictHostKeyChecking=no root@$WORKER_0_IP <<EOF
apt-get update -y
until nc -z $MASTER_NODE_PRIVATE_IP 6443; do sleep 5; done
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_NODE_PRIVATE_IP:6443 K3S_TOKEN=$REMOTE_TOKEN sh -s - --kubelet-arg cloud-provider=external
exit 0
EOF

echo "⏳ Waiting for worker node 0 service to start..."
for i in {1..30}; do
  if ssh -o StrictHostKeyChecking=no root@$WORKER_0_IP "systemctl is-active k3s-agent" &>/dev/null; then
    echo "✅ Worker node 0 joined successfully"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Worker node 0 failed to start after 150 seconds"
    exit 1
  fi
  sleep 5
done
echo "Joining worker node 1 to the cluster..."
ssh -o StrictHostKeyChecking=no root@$WORKER_1_IP <<EOF
apt-get update -y
until nc -z $MASTER_NODE_PRIVATE_IP 6443; do sleep 5; done
HOSTNAME=$(hostname -f)
PUBLIC_IP=$(hostname -I | awk '{print $1}')

NETWORK_INTERFACE=$(
  ip -o link show |
    awk -F': ' '/mtu (1450|1280)/ {print $2}' |
    grep -Ev 'cilium|br|flannel|docker|veth' |
    head -n1
)
PRIVATE_IP=$(
  ip -4 -o addr show dev "$NETWORK_INTERFACE" |
    awk '{print $4}' |
    cut -d'/' -f1 |
    head -n1
)

curl -sfL https://get.k3s.io |
  K3S_TOKEN=secret_token \
    INSTALL_K3S_SKIP_START=false \
    INSTALL_K3S_EXEC="server" \
    INSTALL_K3S_VERSION="v1.33.4+k3s1" \
    sh -s - \
    --disable-cloud-controller \
    --disable=traefik \
    --write-kubeconfig-mode=644 \
    --cluster-cidr=10.244.0.0/16 \
    --cluster-dns=10.43.0.10 \
    --kube-controller-manager-arg="bind-address=0.0.0.0" \
    --kube-proxy-arg="metrics-bind-address=0.0.0.0" \
    --kube-scheduler-arg="bind-address=0.0.0.0" \
    --node-ip=$PRIVATE_IP \
    --advertise-address=$PRIVATE_IP \
    --node-external-ip=$PUBLIC_IP \
    --cluster-init \
    --tls-san=$PRIVATE_IP \
exit 0
EOF

echo "⏳ Waiting for worker node 1 service to start..."
for i in {1..30}; do
  if ssh -o StrictHostKeyChecking=no root@$WORKER_1_IP "systemctl is-active k3s-agent" &>/dev/null; then
    echo "✅ Worker node 1 joined successfully"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Worker node 1 failed to start after 150 seconds"
    exit 1
  fi
  sleep 5
done
echo "K3s cluster initialization completed!"
echo ""
echo "To access your cluster, copy the kubeconfig from the master node:"
echo "scp -o StrictHostKeyChecking=no root@$MASTER_IP:/etc/rancher/k3s/k3s.yaml kubeconfig"
echo "Then update the server IP in the config file to: https://$MASTER_IP:6443"
