#!/bin/bash

function getContainerIP() {
    local container_name=$1
    docker ps -q -f name="$container_name" | xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
}
function getServiceIP() {
    local service_name=$1
    local namespace=${2:-default}
    kubectl get service "$service_name" -n ${namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

echo "Fetching container IPs..."
docker ps -q | xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}' | sed 's/ \// /'
echo ""

echo "Fetching node IPs..."
kubectl get nodes -o wide | awk '{print $1, $6}' | tail -n +2
echo ""


echo "Fetching service IPs..."
kubectl get svc -A
echo ""

echo "Fetching nginx controller pod IPs..."
kubectl get pods -o wide -n nginx
echo ""

HAPROXY_PUBLIC_CONTAINER_IP=`getContainerIP haproxy-public`
HAPROXY_PUBLIC_CONTAINER_PORT=`docker port haproxy-public $1 8080/tcp | cut -d: -f2`
HAPROXY_INTERNAL_CONTAINER_IP=`getContainerIP haproxy-internal`
HAPROXY_INTERNAL_CONTAINER_PORT=`docker port haproxy-internal $1 8080/tcp | cut -d: -f2`
NGINX_INGRESS_PUBLIC_IP=$(getServiceIP nginx-public-ingress-nginx-controller nginx)
NGINX_INGRESS_INTERNAL_IP=$(getServiceIP nginx-internal-ingress-nginx-controller nginx)


echo "### Public ###"
echo "1. Localhost -> haproxy-public -> nginx-public-ingress-nginx-controller"
echo curl localhost:"${HAPROXY_PUBLIC_CONTAINER_PORT}"/headers
echo "2. Localhost -> vpn -> haproxy-public -> nginx-public-ingress-nginx-controller"
echo curl ${HAPROXY_PUBLIC_CONTAINER_IP}:8080/headers
echo "3. Localhost -> vpn -> nginx-public-ingress-nginx-controller"
echo curl -H \"Host: httpbin-public.local\"  http://${NGINX_INGRESS_PUBLIC_IP}/headers
echo ""

echo "### Internal ###"
echo "1. Localhost -> haproxy-internal -> nginx-internal-ingress-nginx-controller"
echo curl localhost:"${HAPROXY_INTERNAL_CONTAINER_PORT}"/headers
echo "2. Localhost -> vpn -> haproxy-internal -> nginx-internal-ingress-nginx-controller"
echo curl ${HAPROXY_INTERNAL_CONTAINER_IP}:8080/headers
echo "3. Localhost -> vpn -> nginx-internal-ingress-nginx-controller"
echo curl -H \"Host: httpbin-internal.local\"  http://${NGINX_INGRESS_INTERNAL_IP}/headers
echo ""
