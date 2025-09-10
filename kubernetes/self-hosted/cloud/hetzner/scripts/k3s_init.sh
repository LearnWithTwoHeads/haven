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
ssh -o StrictHostKeyChecking=no root@$MASTER_IP << 'EOF'
apt-get update -y
curl https://get.k3s.io | INSTALL_K3S_EXEC="--disable-cloud-controller" sh -
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
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_NODE_PRIVATE_IP:6443 K3S_TOKEN=$REMOTE_TOKEN sh -
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
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_NODE_PRIVATE_IP:6443 K3S_TOKEN=$REMOTE_TOKEN sh -
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
echo "scp root@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
echo "Then update the server IP in the config file to: https://$MASTER_IP:6443"
