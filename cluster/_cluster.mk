CLUSTER_NAME ?= my-platform
CLUSTER_NODES = $(shell kind get nodes --name $(CLUSTER_NAME))

cluster_create:
	kind create cluster --config cluster/cluster_config.yaml --name $(CLUSTER_NAME)
	@echo "Cluster $(CLUSTER_NAME) created"

cluster_delete:
	kind delete cluster --name $(CLUSTER_NAME)
	@echo "Cluster $(CLUSTER_NAME) deleted"

cluster_info:
	kind get clusters
	@echo "Cluster $(CLUSTER_NAME) info"

cluster_start:
	docker start $(CLUSTER_NODES)
	@echo "Cluster $(CLUSTER_NAME) started"

cluster_stop:
	docker stop $(CLUSTER_NODES)
	@echo "Cluster $(CLUSTER_NAME) stopped"

.PHONY: cluster_create cluster_delete cluster_info cluster_start cluster_stop