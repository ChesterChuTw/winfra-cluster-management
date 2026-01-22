# Winfra Cluster Management

This repository manages the full lifecycle of Kubernetes clusters using Talos Linux and FluxCD GitOps.

## Architecture Overview

This repository is organized into two main components:

### 1. `talos-k8s-cluster/` - Day-0 / Day-1 Cluster Provisioning

**Purpose**: Initial cluster setup and provisioning using Talos Linux.

**Contents**:
- Talos cluster configuration files for each environment
- SOPS-encrypted secrets (`talsecret.sops.yaml`)
- CNI configuration (Calico)
- Cluster management scripts (e.g., `reboot-workers.sh`)

**Environments**:
- `winfra-prod/` - Production cluster configuration
- `winfra-test/` - Test cluster configuration

**Key Files**:
- `clusterconfig/*.yaml` - Talos machine configuration files
- `talconfig.yaml` - Talos cluster configuration
- `talsecret.sops.yaml` - SOPS-encrypted cluster secrets
- `reboot-workers.sh` - Script for safely rebooting worker nodes

### 2. `fluxcd-app-mgmt/` - Day-2 GitOps Management

**Purpose**: Continuous deployment and management using FluxCD.

**Structure**:
- `flux-cluster-core/` - Flux bootstrap and core configuration
- `flux-cluster-infrastructure/` - Infrastructure components
- `flux-cluster-workloads/` - Application workloads

#### `flux-cluster-core/`

Flux bootstrap configuration that sets up FluxCD in the cluster.

**Components**:
- Flux instance configuration
- GitRepository definitions for infrastructure and workloads repos
- Kustomization definitions for cluster-level resources

#### `flux-cluster-infrastructure/`

Infrastructure components required for cluster operations.

**Applications**:
- **CNI**: Calico (network policy and pod networking)
- **Ingress**: Traefik (ingress controller and CRDs)
- **Certificate Management**: cert-manager
- **Storage**: NFS Provisioner
- **Backup**: Velero
- **Monitoring & Observability**:
  - kube-prometheus-stack (Prometheus + Grafana)
  - loki-stack (log aggregation)
  - observability (Mimir, Loki, Tempo, Grafana, Alloy)

**Structure**:
- `applications/` - HelmRelease definitions for infrastructure apps
- `clusters/` - Cluster-specific Kustomizations
- `manifests/` - Raw Kubernetes manifests
- `repositories/` - HelmRepository definitions

#### `flux-cluster-workloads/`

Application workloads deployed to the cluster.

**Applications**:
- **GitLab** - Git repository and CI/CD platform
- **Harbor** - Container registry
- **Keycloak** - Identity and access management
- **MinIO** - S3-compatible object storage
- **Nextcloud** - File sharing and collaboration
- **Wiki** - Documentation platform

**Structure**:
- `applications/` - HelmRelease definitions for workloads
- `clusters/` - Cluster-specific Kustomizations
- `manifests/` - Raw Kubernetes manifests (Ingress, Secrets, etc.)
- `repositories/` - HelmRepository definitions

## Clusters

### winfra-prod

**Domain**: `winfra.cs.nycu.edu.tw`

**Nodes**:
- 3 Control Plane nodes (kmaster1-3)
- 3 Worker nodes (kworker1-3)

### winfra-test

**Domain**: `sharkbi.online`

**Storage**:
- NFS subdir external provisioner for persistent volumes
- S3-compatible storage (MinIO) for object storage

**Nodes**:
- 1 Control Plane node (kmaster1)
- 3 Worker nodes (kworker1-3)

## Security

### SOPS Encryption

All sensitive data is encrypted using [SOPS](https://github.com/getsops/sops) with AGE encryption:

- **Talos Secrets**: `talos-k8s-cluster/*/talsecret.sops.yaml`
- **Application Secrets**: `fluxcd-app-mgmt/*/applications/*/overlays/*/values.secrets.yaml`
- **GitLab Secrets**: `fluxcd-app-mgmt/flux-cluster-workloads/manifests/gitlab/overlays/*/*.yaml`

**Encryption Rules**:
- Fields matching patterns like `password`, `secret`, `key`, `token`, `credential`, etc. are automatically encrypted
- Configuration files use `.sops.yaml` to define encryption rules

### Secret Management

- **Non-sensitive values**: Stored in `values.yaml` → Generated as ConfigMaps
- **Sensitive values**: Stored in `values.secrets.yaml` (SOPS encrypted) → Generated as Secrets
- HelmReleases use both ConfigMaps and Secrets via `valuesFrom`

## Directory Structure

```
winfra-cluster-management/
├── README.md (this file)
├── talos-k8s-cluster/          # Day-0/Day-1: Cluster provisioning
│   ├── README.md
│   ├── reboot-workers.sh       # Worker node reboot script
│   ├── cni/                     # CNI configuration
│   ├── winfra-prod/             # Production cluster config
│   └── winfra-test/             # Test cluster config
└── fluxcd-app-mgmt/            # Day-2: GitOps management
    ├── flux-cluster-core/      # Flux bootstrap
    │   ├── README.md
    │   ├── SECRET_VS_CONFIGMAP_GUIDE.md
    │   └── clusters/
    ├── flux-cluster-infrastructure/  # Infrastructure apps
    │   ├── README.md
    │   ├── GRAFANA_DASHBOARD_GUIDE.md
    │   ├── applications/        # HelmRelease definitions
    │   ├── clusters/           # Cluster-specific configs
    │   ├── manifests/          # Raw Kubernetes manifests
    │   └── repositories/       # HelmRepository definitions
    └── flux-cluster-workloads/  # Application workloads
        ├── README.md
        ├── applications/        # HelmRelease definitions
        ├── clusters/           # Cluster-specific configs
        ├── manifests/          # Raw Kubernetes manifests
        └── repositories/       # HelmRepository definitions
```

## Getting Started

### Prerequisites

- `talosctl` - Talos Linux management tool
- `kubectl` - Kubernetes CLI
- `flux` - FluxCD CLI
- `sops` - Secrets OPerationS tool
- AGE key for SOPS decryption

### Day-0: Cluster Provisioning

See [talos-k8s-cluster/README.md](talos-k8s-cluster/README.md) for detailed cluster provisioning instructions.

### Day-1: Flux Bootstrap

See [fluxcd-app-mgmt/flux-cluster-core/README.md](fluxcd-app-mgmt/flux-cluster-core/README.md) for Flux bootstrap instructions.

### Day-2: Application Management

Applications are automatically deployed via FluxCD GitOps. Changes to the repository will be automatically synced to the cluster.

For detailed information, see:
- [fluxcd-app-mgmt/flux-cluster-infrastructure/README.md](fluxcd-app-mgmt/flux-cluster-infrastructure/README.md)
- [fluxcd-app-mgmt/flux-cluster-workloads/README.md](fluxcd-app-mgmt/flux-cluster-workloads/README.md)

## Documentation

- [Talos Cluster README](talos-k8s-cluster/README.md)
- [Flux Core README](fluxcd-app-mgmt/flux-cluster-core/README.md)
- [Flux Infrastructure README](fluxcd-app-mgmt/flux-cluster-infrastructure/README.md)
- [Flux Workloads README](fluxcd-app-mgmt/flux-cluster-workloads/README.md)
- [FluxCD + SOPS Decryption: Secret vs ConfigMap](fluxcd-app-mgmt/flux-cluster-core/SECRET_VS_CONFIGMAP_GUIDE.md)
- [Grafana Dashboard Guide](fluxcd-app-mgmt/flux-cluster-infrastructure/GRAFANA_DASHBOARD_GUIDE.md)



## License

Apache License 2.0
