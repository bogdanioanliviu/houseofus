# Traefik Kubernetes Deployment
_Last updated: March 22, 2025_

## Overview

This repository contains Kubernetes manifests for deploying Traefik v3.3.3 as an ingress controller, providing dynamic routing, load balancing, SSL termination, and dashboard visualization.

## Repository Contents
- `deploy-traefik.yaml`: Deployment configuration
- `configmap-trafik.yaml`: ConfigMap with Traefik configuration
- `service-account.yaml`: RBAC permissions
- `svc-trafik-all.yaml`: Service definitions
- `pv-pvc-traefik-unifi.yaml`: Persistent volume configuration
- `cdr-trafik_old.yaml`: Custom Resource Definitions

## Prerequisites
- Kubernetes cluster (v1.19+)
- NFS server for persistent storage
- DNS provider (Gandi v5 DNS configured)

## Installation
```
# Create namespace
kubectl create namespace traefik

# Apply RBAC, storage, config and deployment
kubectl apply -f service-account.yaml
kubectl apply -f pv-pvc-traefik-unifi.yaml
kubectl apply -f configmap-trafik.yaml
kubectl apply -f deploy-traefik.yaml
kubectl apply -f svc-trafik-all.yaml
```

## Configuration
- **Services**: Dashboard (8080), Web (80), Secure web (443)
- **TLS**: Automatic certificate management via Let's Encrypt with DNS challenge
- **Storage**: NFS-backed volume for certificates
- **Resources**: Memory: 65Mi (request), 150Mi (limit); CPU: 18m (request)
- **Monitoring**: Metrics sent to InfluxDB

## Dashboard Access
```http://<node-ip>:<nodeport>/dashboard/```

## Troubleshooting
```bash
# Check logs
kubectl logs -n traefik -l app=traefik
# Verify RBAC
kubectl auth can-i list services --as=system:serviceaccount:traefik:traefik-account
# Check storage
kubectl get pv,pvc -n traefik
```

## Maintenance
To upgrade Traefik:
1. Update image tag in `deploy-traefik.yaml`
2. Apply: `kubectl apply -f deploy-traefik.yaml`
3. Backup certificate data before major changes.

## Security
- Dedicated service account with least privilege
- Volume permissions set with init container
- TLS configured for secure communication

## License
GNU General Public License v3.0


