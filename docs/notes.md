## Configuration
* combination of /etc/nginx/nginx.conf and /etc/nginx/lua/cfg.json



## Configuration

`kubectl -n nginx exec -it nginx-internal-ingress-nginx-controller-6lzs8 -- cat /etc/nginx/lua/cfg.json | jq`


```
Fetching container IPs...
172.18.0.4 kind-cluster-worker
172.18.0.3 kind-cluster-control-plane
172.18.0.2 kind-cluster-worker2
172.19.0.4 bei_test_service-dev-service-1
172.19.0.3 bei_test_service-dev-redis-server-1
172.18.0.5 haproxy-public
172.18.0.6 haproxy-internal

Fetching node IPs...
kind-cluster-control-plane 172.18.0.3
kind-cluster-worker 172.18.0.4
kind-cluster-worker2 172.18.0.2

Fetching service IPs...
NAMESPACE        NAME                                                TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default          kubernetes                                          ClusterIP      172.18.0.1       <none>           443/TCP                      17m
httpbin          httpbin                                             LoadBalancer   172.18.222.117   172.18.255.202   80:32294/TCP                 15m
kube-system      kube-dns                                            ClusterIP      172.18.0.10      <none>           53/UDP,53/TCP,9153/TCP       17m
metallb-system   metallb-webhook-service                             ClusterIP      172.18.96.159    <none>           443/TCP                      17m
nginx            nginx-internal-ingress-nginx-controller             LoadBalancer   172.18.118.20    172.18.255.201   80:32473/TCP,443:31598/TCP   15m
nginx            nginx-internal-ingress-nginx-controller-admission   ClusterIP      172.18.58.203    <none>           443/TCP                      15m
nginx            nginx-public-ingress-nginx-controller               LoadBalancer   172.18.171.253   172.18.255.200   80:30724/TCP,443:32671/TCP   11m
nginx            nginx-public-ingress-nginx-controller-admission     ClusterIP      172.18.238.226   <none>           443/TCP                      11m


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

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES CLUSTER NETWORK                            │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                DOCKER NETWORKS                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│  Network 172.18.x.x (kind-cluster)                                              │
│                                                                                 │
│  ┌─────────────────────────┐                                                    │
│  │   CONTROL PLANE         │                                                    │
│  │  172.18.0.3             │                                                    │
│  │  kind-cluster-          │                                                    │
│  │  control-plane          │                                                    │
│  └─────────────────────────┘                                                    │
│                                                                                 │
│  ┌─────────────────────────┐                                                    │
│  │   WORKER NODES          │                                                    │
│  │                         │                                                    │
│  │  kind-cluster-worker    │                                                    │
│  │  172.18.0.4             │                                                    │
│  │                         │                                                    │
│  │  kind-cluster-worker2   │                                                    │
│  │  172.18.0.2             │                                                    │
│  └─────────────────────────┘                                                    │
│                                                                                 │
│  ┌─────────────────────────┐                                                    │
│  │   LOAD BALANCERS        │                                                    │
│  │                         │                                                    │
│  │  haproxy-public         │                                                    │
│  │  172.18.0.5             │                                                    │
│  │                         │                                                    │
│  │  haproxy-internal       │                                                    │
│  │  172.18.0.6             │                                                    │
│  └─────────────────────────┘                                                    │
│  ┌─────────────────────────┐                                                    │
│  │   Utilities             │                                                    │
|  |                         |                                                    |
│  │  curl                   │                                                    │
│  │  172.18.0.7             │                                                    │
│  └─────────────────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            KUBERNETES SERVICES                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  CLUSTER SERVICES (ClusterIP):                                                  │
│  ├─ kubernetes (default)                    172.18.0.1      :443/TCP            │
│  ├─ kube-dns (kube-system)                  172.18.0.10     :53/UDP,TCP,9153    │
│  ├─ metallb-webhook-service                 172.18.96.159   :443/TCP            │
│  ├─ nginx-internal-controller-admission     172.18.58.203   :443/TCP            │
│  └─ nginx-public-controller-admission       172.18.238.226  :443/TCP            │
│                                                                                 │
│  LOAD BALANCER SERVICES:                                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │  httpbin (httpbin namespace)                                            │    │
│  │  Cluster IP: 172.18.222.117                                             │    │
│  │  External IP: 172.18.255.202 → :80                                      │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │  nginx-internal-ingress-controller (nginx namespace)                    │    │
│  │  Cluster IP: 172.18.118.20                                              │    │
│  │  External IP: 172.18.255.201 → :80,:443                                 │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │  nginx-public-ingress-controller (nginx namespace)                      │    │
│  │  Cluster IP: 172.18.171.253                                             │    │
│  │  External IP: 172.18.255.200 → :80,:443                                 │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                               TRAFFIC FLOW                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  External Traffic:                                                              │
│  172.18.255.200 (Public Ingress)   ──→  nginx-public-controller                 │
│  172.18.255.201 (Internal Ingress) ──→ nginx-internal-controller                │
│  172.18.255.202 (HttpBin)          ──→  httpbin service                         │
│                                                                                 │
│  Internal Traffic:                                                              │
│  Control Plane (172.18.0.3) ←──→ Worker Nodes (172.18.0.4, 172.18.0.2)          │
│  HAProxy Public/Internal (172.18.0.5/6) ←──→ Cluster Services                   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```



**Nodes:**
- kind-cluster-worker: `172.18.0.4`
- kind-cluster-worker2: `172.18.0.2`

**Hitting ingress directly:**
1. client:  `172.18.0.7 ` -> nginx-public-controller:   `172.18.255.200` -> httpBin svc
2. client:  `172.18.0.7 ` -> nginx-internal-controller: `172.18.255.201` -> httpBiun svc

**Hitting ingress directly via haproxy:**
1. client:  `172.18.0.7 ` -> haproxy-public:   `172.18.0.5` -> nginx-public-controller:   `172.18.255.200` -> httpBin svc
2. client:  `172.18.0.7 ` -> haproxy-internal: `172.18.0.6` -> nginx-internal-controller: `172.18.255.201` -> httpBiun svc

**fake xff used**
> xff: 123.123.123.13

## Test Cases:
- client (172.18.0.7) -> nginx-public (172.18.255.200) -> httpBin


## Configuration #1
- `--set controller.config.use-forwarded-headers=false`
- `--set controller.config.compute-full-forwarded-for=false`


```
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
|                             Nginx Public                             | X-Forwarded-For                         |    X-Original-Forwarded-For     | X-Real-IP       |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
| client -> nginx-public -> httpBin                                    | 172.18.0.2                              |                                 | 172.18.0.2      |
| client -> haproxy-public -> nginx-public-controller -> httpBin       | 172.18.0.2                              | 172.18.0.7                      | 172.18.0.2      |
| client + xff -> haproxy-public -> nginx-public-controller -> httpBin | 172.18.0.2                              | 172.18.0.7                      | 172.18.0.2      |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+

+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
|                             Nginx Internal                           | X-Forwarded-For                         | X-Original-Forwarded-For        | X-Real-IP       |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
| client -> nginx-internal -> httpBin                                  | 172.18.0.7                              |                                 | 172.18.0.7      |
| client -> haproxy-internal -> nginx-internal -> httpBin              | 172.18.0.6                              | 172.18.0.7                      | 172.18.0.6      |
| client + xff -> haproxy-internal -> nginx-internal -> httpBin        | 172.18.0.6                              | 172.18.0.7                      | 172.18.0.6      |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
```

## Configuration #2
- `--set controller.config.use-forwarded-headers=true`
- `--set controller.config.compute-full-forwarded-for=false`

```
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
|                             Nginx Public                             | X-Forwarded-For                         |    X-Original-Forwarded-For     | X-Real-IP       |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
| client -> nginx-public -> httpBin                                    | 172.18.0.2                              |                                 | 172.18.0.2      |
| client -> haproxy-public -> nginx-public-controller -> httpBin       | 172.18.0.7                              | 172.18.0.7                      | 172.18.0.7      |
| client + xff -> haproxy-public -> nginx-public-controller -> httpBin | 172.18.0.7                              | 172.18.0.7                      | 172.18.0.7      |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+

+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
|                             Nginx Internal                           | X-Forwarded-For                         | X-Original-Forwarded-For        | X-Real-IP       |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
| client -> nginx-internal -> httpBin                                  | 172.18.0.7                              |                                 | 172.18.0.7      |
| client -> haproxy-internal -> nginx-internal -> httpBin              | 172.18.0.7                              | 172.18.0.7                      | 172.18.0.7      |
| client + xff -> haproxy-internal -> nginx-internal -> httpBin        | 123.123.123.123                         | 123.123.123.123, 172.18.0.7     | 123.123.123.123 |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+

```

## Configuration #3
- `--set controller.config.use-forwarded-headers=true`
- `--set controller.config.compute-full-forwarded-for=true`

```
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
|                             Nginx Public                             | X-Forwarded-For                         |    X-Original-Forwarded-For     | X-Real-IP       |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
| client -> nginx-public -> httpBin                                    | 172.18.0.2                              |                                 | 172.18.0.2      |
| client -> haproxy-public -> nginx-public-controller -> httpBin       | 172.18.0.7, 172.18.0.2                  | 172.18.0.7                      | 172.18.0.7      |
| client + xff -> haproxy-public -> nginx-public-controller -> httpBin | 172.18.0.7, 172.18.0.2                  | 172.18.0.7                      | 172.18.0.7      |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+

+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
|                             Nginx Internal                           | X-Forwarded-For                         | X-Original-Forwarded-For        | X-Real-IP       |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
| client -> nginx-internal -> httpBin                                  | 172.18.0.7                              |                                 | 172.18.0.7      |
| client -> haproxy-internal -> nginx-internal -> httpBin              | 172.18.0.7, 172.18.0.6                  | 172.18.0.7                      | 172.18.0.7      |
| client + xff -> haproxy-internal -> nginx-internal -> httpBin        | 123.123.123.123, 172.18.0.7, 172.18.0.6 | 123.123.123.123, 172.18.0.7     | 123.123.123.123 |
+----------------------------------------------------------------------+-----------------------------------------+---------------------------------+-----------------+
```




```
# Public-1: client -> nginx-public -> httpBin
docker exec -it curl curl -s -H "Host: httpbin-public.local" http://172.18.255.200/headers | \
 jq '.headers | {
  "X-Forwarded-For": .["X-Forwarded-For"],
  "X-Original-Forwarded-For": .["X-Original-Forwarded-For"],
  "X-Real-Ip": .["X-Real-Ip"]
}'

# Public-2: client -> haproxy-public -> nginx-public-controller -> httpBin
docker exec -it curl curl -s 172.18.0.5:8080/headers | \
 jq '.headers | {
  "X-Forwarded-For": .["X-Forwarded-For"],
  "X-Original-Forwarded-For": .["X-Original-Forwarded-For"],
  "X-Real-Ip": .["X-Real-Ip"]
}'

# Public-3: client + xff -> haproxy-public -> nginx-public-controller -> httpBin
docker exec -it curl curl -s 172.18.0.5:8080/headers | \
 jq '.headers | {
  "X-Forwarded-For": .["X-Forwarded-For"],
  "X-Original-Forwarded-For": .["X-Original-Forwarded-For"],
  "X-Real-Ip": .["X-Real-Ip"]
}'


#################################################################

# Int-1: client -> nginx-internal -> httpBin
docker exec -it curl curl -s -H "Host: httpbin-internal.local" http://172.18.255.201/headers | \
 jq '.headers | {
  "X-Forwarded-For": .["X-Forwarded-For"],
  "X-Original-Forwarded-For": .["X-Original-Forwarded-For"],
  "X-Real-Ip": .["X-Real-Ip"]
}'

# Int-2: client -> haproxy-internal -> nginx-internal -> httpBin
docker exec -it curl curl -s 172.18.0.6:8080/headers | \
 jq '.headers | {
  "X-Forwarded-For": .["X-Forwarded-For"],
  "X-Original-Forwarded-For": .["X-Original-Forwarded-For"],
  "X-Real-Ip": .["X-Real-Ip"]
}'

# Int-3: client + xff -> haproxy-internal -> nginx-internal -> httpBin
docker exec -it curl curl -s 172.18.0.6:8080/headers -H 'X-Forwarded-For: 123.123.123.123'  | \
 jq '.headers | {
  "X-Forwarded-For": .["X-Forwarded-For"],
  "X-Original-Forwarded-For": .["X-Original-Forwarded-For"],
  "X-Real-Ip": .["X-Real-Ip"]
}'
```