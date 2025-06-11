#!/bin/bash

set -euo pipefail


# Step 4: Create the MetalLB CRD manifests
mkdir -p metallb
cat <<EOF > metallb/metallb-native.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
EOF

echo "✅ Generated metallb/metallb-native.yaml with range ${METALLB_RANGE}"

# Step 5 (optional): Apply it automatically if kubectl is available
if command -v kubectl &>/dev/null; then
  echo "📦 Applying config to cluster..."
  kubectl apply -f metallb/metallb-native.yaml
fi
