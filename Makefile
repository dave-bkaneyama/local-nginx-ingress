.ONESHELL:
.PHONY: cluster kill-cluster service delete-service foo-service kill-foo-service bar-service kill-bar-service nginx kill-nginx nginx-ingress kill-nginx-ingress lb kill-lb helm init nginx-public haproxy

all:
	@echo "Starting all services...":
	@make cluster helm lb nginx nginx httpbin httpbin-ingress haproxy
	@echo "All services started."

kill:
	@make kill-cluster

vpn:
	@echo "Starting docker-mac-net-connect to connect to docker mac network... (requires sudo)"
	@sudo brew services start chipmk/tap/docker-mac-net-connect \
		&& echo "complete..." \
		|| echo "failed!"
kill-vpn:
	@echo "Stopping docker-mac-net-connect..."
	@sudo brew services stop chipmk/tap/docker-mac-net-connect \
		&& echo "complete..." \
		|| echo "failed!"

cluster:
	@echo "Creating Kubernetes cluster with kind..."
	@mkdir -p ./.kube
	@bash ./kind/create-cluster.sh
	@bash ./kind/docker-network.sh
	@kind create cluster --name kind-cluster --config kind/kind-config.yaml
	@echo "Waiting for cluster to be ready..."
	@kubectl wait --for=condition=Ready nodes --all --timeout=300s
	@kubectl get nodes -o wide
	@kubectl config rename-context kind-kind-cluster kind-cluster || true
	@kubectl config use-context kind-cluster
	@kubectl cluster-info kind-cluster
	@echo "Cluster 'kind-cluster' is ready."

kill-cluster:
	@kind delete cluster --name kind-cluster
	@kubectl config delete-context kind-cluster || true
	@kubectl config delete-context king-kind-cluster || true

helm:
	@helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	@helm repo add metallb https://metallb.github.io/metallb
	@helm repo add matheusfm https://matheusfm.dev/charts
	@helm repo update

lb:
	@echo "Creating load balancer service..."
	@helm upgrade --install metallb metallb/metallb \
  		--namespace metallb-system \
  		--create-namespace
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=metallb --timeout=90s --namespace metallb-system
	@kubectl get pod -l app.kubernetes.io/name=metallb --namespace metallb-system
	@echo "Load balancer service created."
	@echo "Configuring MetalLB..."
	@bash metallb/configure.sh
	@kubectl apply -f metallb/metallb-native.yaml -n metallb-system
	@echo "MetalLB configured."

kill-lb:
	@echo "Deleting load balancer service..."
	@helm uninstall metallb -n metallb-system
	@echo "Load balancer service deleted."


nginx:
	make nginx-public nginx-internal

kill-nginx:
	@make kill-nginx-public kill-nginx-internal

nginx-public:
	@echo "Creating nginx-public controller..."
	@helm upgrade --install nginx-public ingress-nginx/ingress-nginx \
		--namespace nginx --create-namespace \
		--set controller.kind=Deployment \
		--set controller.ingressClass=nginx-public \
		--set controller.ingressClassResource.name=nginx-public \
        --set controller.service.type=LoadBalancer \
        --set controller.hostPort.enabled=false \
        --set controller.publishService.enabled=false \
        --set controller.watchIngressWithoutClass=true \
        --set controller.terminationGracePeriodSeconds=0 \
        --set controller.minReadySeconds=0 \
		--set controller.service.externalTrafficPolicy=Cluster \
		--set-string controller.nodeSelector."ingress-ready"=true \
        --set controller.tolerations[0].key=node-role.kubernetes.io/control-plane \
        --set controller.tolerations[0].operator=Equal \
        --set controller.tolerations[0].effect=NoSchedule \
		--set controller.config.use-forwarded-headers=false \
		--set controller.config.compute-full-forwarded-for=false 

	@echo "Waiting for nginx-public controller to be ready..."
	@kubectl wait -n nginx \
	 	--for=condition=ready pod \
	 	--selector=app.kubernetes.io/instance=nginx-public \
	 	--timeout=90s

	@kubectl get pods -n nginx -o wide -l app.kubernetes.io/instance=nginx-public
	@echo "Nginx service created."

kill-nginx-public:
	@echo "Deleting nginx-public controller..."
	@helm delete nginx-public -n nginx
	@echo "Nginx service deleted."

nginx-internal:
	@echo "Creating nginx-internal controller..."
	@helm upgrade --install nginx-internal ingress-nginx/ingress-nginx \
		--namespace nginx --create-namespace \
		--set controller.kind=DaemonSet \
		--set controller.ingressClass=nginx-internal \
		--set controller.ingressClassResource.name=nginx-internal \
        --set controller.service.type=LoadBalancer \
        --set controller.hostPort.enabled=false \
        --set controller.publishService.enabled=false \
        --set controller.watchIngressWithoutClass=true \
        --set controller.terminationGracePeriodSeconds=0 \
        --set controller.minReadySeconds=0 \
		--set controller.service.externalTrafficPolicy=Local \
        --set controller.tolerations[0].key=node-role.kubernetes.io/control-plane \
        --set controller.tolerations[0].operator=Equal \
        --set controller.tolerations[0].effect=NoSchedule \
		--set controller.config.use-forwarded-headers=false \
		--set controller.config.compute-full-forwarded-for=false

	@echo "Waiting for nginx-internal controller to be ready..."
	@kubectl wait -n nginx \
	 	--for=condition=ready pod \
	 	--selector=app.kubernetes.io/instance=nginx-internal \
	 	--timeout=90s

	@kubectl get pods -n nginx -o wide -l app.kubernetes.io/instance=nginx-internal
	@echo "Nginx service created."

kill-nginx-internal:
	@echo "Deleting nginx-internal controller..."
	@helm delete nginx-internal -n nginx
	@echo "Nginx service deleted."


httpbin:
	@echo "Creating httpbin service..."
	@helm upgrade --install httpbin matheusfm/httpbin \
    --namespace httpbin \
    --create-namespace \
    --set service.type=LoadBalancer
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=httpbin -n httpbin --timeout=90s
	@kubectl get pods -o wide -n httpbin
	@kubectl get svc -n httpbin
	@echo "Httpbin service created."
    # --set ingress.enabled=true \
    # --set ingress.hosts[0].host="" \
    # --set ingress.hosts[0].paths[0].path=/ \
    # --set ingress.hosts[0].paths[0].pathType=Prefix

kill-httpbin:
	@echo "Deleting httpbin service..."
	@helm uninstall httpbin -n httpbin
	@kubectl delete namespace httpbin
	@echo "Httpbin service deleted."

httpbin-ingress:
	@echo "Creating httpbin ingress..."
	@kubectl apply -f ingress/
	@kubectl get ingress -n httpbin
	@echo "Httpbin ingress created."

kill-httpbin-ingress:
	@echo "Deleting httpbin ingress..."
	@kubectl delete -f ingress/
	@echo "Httpbin ingress deleted."

haproxy:
	@echo "Creating HAProxy service configuration..."
	@bash haproxy/create-haproxy-config.sh
	@echo "Creating HAProxy service..."
	@docker compose -f haproxy/docker-compose.yaml up -d \
		&& echo "HAProxy running..." \
		|| echo "HAProxy failed to start!"

kill-haproxy:
	@echo "Stopping HAProxy service..."
	@docker compose -f haproxy/docker-compose.yaml down \
		&& echo "HAProxy stopped." \
		|| echo "HAProxy failed to stop!"
