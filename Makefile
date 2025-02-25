TERRAFORM ?= terraform

# Default target
all: init

## Initialize Terraform
init:
	@echo "==> Initializing Terraform..."
	$(TERRAFORM) init

## Validate Terraform configuration
validate:
	@echo "==> Validating Terraform configuration..."
	$(TERRAFORM) validate

## Format Terraform files (fixes formatting issues)
fmt:
	@echo "==> Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive

## Show the execution plan
plan:
	@echo "==> Planning Terraform execution..."
	$(TERRAFORM) plan

## Apply the Terraform configuration
apply:
	@echo "==> Applying Terraform configuration..."
	$(TERRAFORM) apply --var-file .tfvars --auto-approve

## Destroy the Terraform-managed infrastructure
destroy:
	@echo "==> Destroying Terraform-managed infrastructure..."
	$(TERRAFORM) apply --destroy --var-file .tfvars --auto-approve

## Initialize the cluster by configuring the first control-plane node
cluster-init:
	@echo "==> Initializing the cluster..."
	cd ansible && ansible-playbook \
		-i hosts \
		playbooks/01-cluster-init.yml

## Join masters to the cluster
join-masters:
	@echo "==> Joining masters to the cluster..."
	cd ansible && ansible-playbook \
		-i hosts \
		playbooks/02-join-masters.yml

## Join workers to the cluster
join-workers:
	@echo "==> Joining workers to the cluster..."
	cd ansible && ansible-playbook \
		-i hosts \
		playbooks/03-join-workers.yml

## Get the kubeconfig file from the cluster
get-kubeconfig:
	@echo "==> Copying kubeconfig to local machine..."
	cd ansible && ansible-playbook \
		-i hosts \
		playbooks/04-get-kubectl-config.yml

## Install traefik in the cluster
install-traefik:
	@echo "==> Installing Traefik on the cluster..."
	cd ansible && ansible-playbook \
		-i hosts \
		playbooks/05-install-traefik.yml

## Install ArgoCD in the cluster
install-argocd:
	@echo "==> Installing ArgoCD on the cluster..."
	cd ansible && ansible-playbook \
		-i hosts \
		playbooks/06-install-argocd.yml

.PHONY: all init validate fmt plan apply destroy cluster-init join-masters join-workers get-kubeconfig install-traefik install-argocd
