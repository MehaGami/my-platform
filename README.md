# My Platform - Deployment Guide

Cloud-native platform deployed on Kubernetes using Helm and ArgoCD with GitOps practices.

## Prerequisites

- Docker
- kind (Kubernetes in Docker)
- kubectl
- Helm 3
- make

## Quick Start

### Full Platform Deployment

Deploy the entire platform from scratch:

```bash
# Deploy cluster + ArgoCD + platform apps
make platform_deploy
```

This will:

1. Create a Kind cluster with Ingress support
2. Install ArgoCD
3. Bootstrap the platform application (App of Apps)
4. Configure all applications with self-healing enabled

### Access ArgoCD

After deployment, access ArgoCD at: **http://my-platform.local/argocd**

Default credentials:

- Username: `admin`
- Password: Get it with `make argocd_password`

## Individual Commands

### Cluster Management

```bash
# Create cluster
make cluster_create

# Delete cluster
make cluster_delete

# Start/stop cluster (without recreating)
make cluster_start
make cluster_stop

# Restart cluster
make platform_restart

# Get cluster info
make cluster_info
```

### ArgoCD Management

```bash
# Install ArgoCD
make argocd_install

# Uninstall ArgoCD
make argocd_uninstall

# Get admin password
make argocd_password
```

### Platform Management

```bash
# Bootstrap platform (deploy root app)
make platform_bootstrap

# Check platform status
make platform_status

# Destroy entire platform
make platform_destroy
```

### DNS Configuration

```bash
# Add my-platform.local to /etc/hosts
# If ENABLE_REGISTRY=true (default), also adds registry.my-platform.local
make hosts_configure

# To disable registry domain:
make hosts_configure ENABLE_REGISTRY=false
```

## Architecture

The platform uses the **App of Apps** pattern:

```
platform (root app)
├── argocd (self-managing)
└── ingress-nginx
```

All applications are configured with:

- `selfHeal: true` - Auto-sync from Git
- `prune: true` - Remove deleted resources
- GitOps source: `https://github.com/MehaGami/my-platform.git`

## Directory Structure

```
.
├── bootstrap/          # Bootstrap manifests (applied once)
│   └── platform-app.yaml
├── charts/            # Helm charts
│   ├── argocd/       # ArgoCD configuration
│   ├── ingress-nginx/
│   └── platform/     # Root app (App of Apps)
│       ├── templates/
│       └── _platform.mk  # Platform deployment automation
├── cluster/          # Cluster configuration
│   ├── cluster_config.yaml
│   └── _cluster.mk
└── Makefile          # Main entry point
```

## Workflow

### Initial Setup

```bash
# 1. Deploy platform
make platform_deploy

# 2. Configure DNS
make hosts_configure

# 3. Access ArgoCD
open http://my-platform.local/argocd
```

### Making Changes

1. Edit files in `charts/` directory
2. Commit and push to Git with appropriate tag
3. ArgoCD auto-syncs changes (selfHeal enabled)

### Recreating from Scratch

```bash
# Destroy and redeploy
make platform_destroy
make platform_deploy
```

## Troubleshooting

### Check Status

```bash
make platform_status
```

### ArgoCD Not Accessible

1. Check ingress: `kubectl get ingress -n argocd`
2. Check pods: `kubectl get pods -n argocd`
3. Verify /etc/hosts has `my-platform.local`

### Applications Not Syncing

1. Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-server`
2. Verify Git tag exists: Should match `targetRevision` in apps
3. Manually sync in ArgoCD UI

## Configuration Variables

Edit in `charts/platform/_platform.mk`:

- `CLUSTER_NAME`: Kind cluster name (default: `my-platform`)
- `ARGOCD_NAMESPACE`: ArgoCD namespace (default: `argocd`)
- `ARGOCD_VERSION`: ArgoCD version (default: `v2.13.0`)
- `DOMAIN`: Platform domain (default: `my-platform.local`)
