#!/bin/bash

set -e

# Get load balancer DNS name
LOAD_BALANCER_DNS=$(aws elbv2 describe-load-balancers \
  --names "yke-control-plane-lb" \
  --output text \
  --query "LoadBalancers[0].DNSName")

if [ -z "$LOAD_BALANCER_DNS" ]; then
  echo "Error: Load balancer not found"
  exit 1
fi

echo "Found load balancer: $LOAD_BALANCER_DNS"

# Remove existing time-server-patch.yaml if it exists
if [ -f "time-server-patch.yaml" ]; then
  echo "Removing existing time-server-patch.yaml"
  rm time-server-patch.yaml
fi

cat <<EOF > time-server-patch.yaml
machine:
  time:
    servers:
      - 169.254.169.123
EOF

talosctl gen config talos-k8s-aws-tutorial https://${LOAD_BALANCER_DNS}:6443 \
    --with-examples=false \
    --with-docs=false \
    --with-kubespan \
    --install-disk /dev/xvda \
    --config-patch '@time-server-patch.yaml'

# Get control plane IP
CONTROL_PLANE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Component,Values=control-plane-node" "Name=instance-state-name,Values=running" \
  --output text \
  --query "Reservations[0].Instances[0].PublicIpAddress")

# Get worker node IPs
WORKER_NODE_IPS=$(aws ec2 describe-instances \
  --filters "Name=tag:Component,Values=worker-node" "Name=instance-state-name,Values=running" \
  --output text \
  --query "Reservations[].Instances[].PublicIpAddress" | tr '\n' ' ')

echo "Control plane IP: $CONTROL_PLANE_IP"
echo "Worker node IPs: $WORKER_NODE_IPS"

# Configure talosctl endpoints
echo "Configuring talosctl endpoints..."
talosctl config endpoints $CONTROL_PLANE_IP --talosconfig talosconfig

# Configure talosctl nodes (use control plane for commands)
echo "Configuring talosctl nodes..."
talosctl config nodes $CONTROL_PLANE_IP --talosconfig talosconfig

# Apply control plane configuration
echo "Applying control plane configuration..."
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml --talosconfig talosconfig

# Apply worker node configurations
echo "Applying worker node configurations..."
for worker_ip in $WORKER_NODE_IPS; do
  echo "Configuring worker node: $worker_ip"
  talosctl apply-config --insecure --nodes $worker_ip --file worker.yaml --talosconfig talosconfig
done

# Bootstrap the cluster
echo "Bootstrapping Talos cluster..."
talosctl bootstrap --talosconfig talosconfig

echo "Talos cluster provisioning completed successfully!"
echo "Use 'talosctl kubeconfig' to retrieve the kubeconfig file."
