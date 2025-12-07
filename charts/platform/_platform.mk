# Platform deployment variables
ARGOCD_NAMESPACE ?= argocd
ARGOCD_VERSION ?= v2.13.0
DOMAIN ?= my-platform.local
ENABLE_REGISTRY ?= true

# Install ArgoCD
argocd_install:
	@echo "Installing ArgoCD..."
	kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml
	@echo "Waiting for ArgoCD to be ready..."
	kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $(ARGOCD_NAMESPACE)
	@echo "ArgoCD installed successfully"

# Uninstall ArgoCD
argocd_uninstall:
	@echo "Uninstalling ArgoCD..."
	kubectl delete -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml
	kubectl delete namespace $(ARGOCD_NAMESPACE)
	@echo "ArgoCD uninstalled"

# Get ArgoCD admin password
argocd_password:
	@echo "ArgoCD admin password:"
	@kubectl get secret argocd-initial-admin-secret -n $(ARGOCD_NAMESPACE) -o jsonpath="{.data.password}" | base64 -d && echo

# Bootstrap platform (deploy platform app)
platform_bootstrap:
	@echo "Bootstrapping platform..."
	kubectl apply -f bootstrap/platform-app.yaml
	@echo "Platform application deployed. ArgoCD will now sync all applications."

# Full platform deployment (cluster + ArgoCD + platform)
platform_deploy: cluster_create argocd_install platform_bootstrap
	@echo "Platform deployed successfully!"
	@echo "Access ArgoCD at: http://$(DOMAIN)/argocd"
	@echo ""
	@make argocd_password

# Destroy entire platform
platform_destroy: cluster_delete
	@echo "Platform destroyed"

# Restart platform (stop, start, wait)
platform_restart: cluster_stop cluster_start
	@echo "Waiting for cluster to be ready..."
	@sleep 10
	kubectl wait --for=condition=Ready nodes --all --timeout=120s
	@echo "Platform restarted"

# Status check
platform_status:
	@echo "=== Cluster Status ==="
	@kubectl get nodes
	@echo ""
	@echo "=== ArgoCD Applications ==="
	@kubectl get applications -n $(ARGOCD_NAMESPACE)
	@echo ""
	@echo "=== All Pods ==="
	@kubectl get pods -A

# Configure /etc/hosts for local domain
hosts_configure:
	@echo "Adding $(DOMAIN) to /etc/hosts..."
	@grep -q "\s$(DOMAIN)$$" /etc/hosts || echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts
ifeq ($(ENABLE_REGISTRY),true)
	@echo "Adding registry.$(DOMAIN) to /etc/hosts (ENABLE_REGISTRY=true)..."
	@grep -q "\sregistry.$(DOMAIN)$$" /etc/hosts || echo "127.0.0.1 registry.$(DOMAIN)" | sudo tee -a /etc/hosts
endif
	@echo "Hosts configured."

.PHONY: argocd_install argocd_uninstall argocd_password platform_bootstrap platform_deploy platform_destroy platform_restart platform_status hosts_configure
