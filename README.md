## Requirements
1. docker runtime (docker desktop, rancher desktop, etc..)
2. kubectl
3. kubectx
4. helm
5. kind
6. jq


## Quick start
`make all`


### Get ips for docker containers
`bash info.sh`

```
bash info.sh                                                                                                                                                   ▼
Fetching container IPs...
172.18.0.5 haproxy-public
172.18.0.6 haproxy-internal
172.18.0.2 kind-cluster-control-plane
172.18.0.3 kind-cluster-worker2
172.18.0.4 kind-cluster-worker

Fetching node IPs...
kind-cluster-control-plane 172.18.0.2
kind-cluster-worker 172.18.0.4
kind-cluster-worker2 172.18.0.3

Fetching service IPs...
NAMESPACE        NAME                                                TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default          kubernetes                                          ClusterIP      172.18.0.1       <none>           443/TCP                      5h52m
httpbin          httpbin                                             LoadBalancer   172.18.158.3     172.18.255.202   80:31361/TCP                 5h49m
kube-system      kube-dns                                            ClusterIP      172.18.0.10      <none>           53/UDP,53/TCP,9153/TCP       5h52m
metallb-system   metallb-webhook-service                             ClusterIP      172.18.229.215   <none>           443/TCP                      5h51m
nginx            nginx-internal-ingress-nginx-controller             LoadBalancer   172.18.151.112   172.18.255.201   80:30755/TCP,443:31904/TCP   5h49m
nginx            nginx-internal-ingress-nginx-controller-admission   ClusterIP      172.18.40.112    <none>           443/TCP                      5h49m
nginx            nginx-public-ingress-nginx-controller               LoadBalancer   172.18.58.103    172.18.255.200   80:31519/TCP,443:30462/TCP   5h50m
nginx            nginx-public-ingress-nginx-controller-admission     ClusterIP      172.18.8.254     <none>           443/TCP                      5h50m

### Public ###
1. Localhost -> haproxy-public -> nginx-public-ingress-nginx-controller
curl localhost:9080/headers
2. Localhost -> vpn -> haproxy-public -> nginx-public-ingress-nginx-controller
curl 172.18.0.5:8080/headers
3. Localhost -> vpn -> nginx-public-ingress-nginx-controller
curl -H "Host: httpbin-public.local" http://172.18.255.200/headers

### Internal ###
1. Localhost -> haproxy-internal -> nginx-internal-ingress-nginx-controller
curl localhost:9081/headers
2. Localhost -> vpn -> haproxy-internal -> nginx-internal-ingress-nginx-controller
curl 172.18.0.6:8080/headers
3. Localhost -> vpn -> nginx-internal-ingress-nginx-controller
curl -H "Host: httpbin-internal.local" http://172.18.255.201/headers

```

**see docs for more information**
