#!/bin/bash

# Create HAProxy configuration for PUBLIC ingress
cat <<EOF > haproxy/haproxy-public.cfg
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend public
    bind *:8080
    option forwardfor
    http-request set-header Host httpbin-public.local
    default_backend k8s_ingress_public

backend k8s_ingress_public
    server ingress-public \$(INGRESS_PUBLIC_IP):80 check

EOF

# Create HAProxy configuration for INTERNAL ingress  
cat <<EOF > haproxy/haproxy-internal.cfg
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend internal
    bind *:8080
    option forwardfor
    http-request set-header Host httpbin-internal.local
    default_backend k8s_ingress_internal

backend k8s_ingress_internal
    server ingress-internal \$(INGRESS_INTERNAL_IP):80 check

EOF

# Get the Ingress controller IPs
export INGRESS_PUBLIC_IP=$(kubectl get service nginx-public-ingress-nginx-controller -n nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Public Ingress IP: ${INGRESS_PUBLIC_IP}"

export INGRESS_INTERNAL_IP=$(kubectl get service nginx-internal-ingress-nginx-controller -n nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Internal Ingress IP: ${INGRESS_INTERNAL_IP}"

# Create final configs
sed "s/\$(INGRESS_PUBLIC_IP)/$INGRESS_PUBLIC_IP/g" haproxy/haproxy-public.cfg > haproxy/haproxy-public-final.cfg
sed "s/\$(INGRESS_INTERNAL_IP)/$INGRESS_INTERNAL_IP/g" haproxy/haproxy-internal.cfg > haproxy/haproxy-internal-final.cfg

echo "Configurations created:"
echo "  - Public:   haproxy/haproxy-public-final.cfg  (port 8080)"
echo "  - Internal: haproxy/haproxy-internal-final.cfg (port 8080)"
echo ""
echo "Run with:"
echo "  haproxy -f haproxy/haproxy-public-final.cfg &"
echo "  haproxy -f haproxy/haproxy-internal-final.cfg &"
echo ""
echo "Access:"
echo "  - Public:   http://localhost:8080"
echo "  - Internal: http://localhost:8081"