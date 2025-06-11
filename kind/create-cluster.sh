#!/bin/bash

echo "Creating the 'kind' docker network, type bridge"
cat <<EOF > kind/docker-network.sh
docker network create \
    -d=bridge \
    --scope=local \
    --attachable=false \
    --gateway=${KIND_GATEWAY} \
    --ingress=false \
    --internal=false \
    --subnet=${KIND_SUBNET} \
    -o "com.docker.network.bridge.enable_ip_masquerade"="true" \
    -o "com.docker.network.driver.mtu"="1500" kind || true
EOF
chmod +x kind/docker-network.sh

cat <<EOF > kind/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "${KIND_SUBNET}"
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF