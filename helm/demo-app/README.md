# Demo App Helm Chart

Kubernetes deployment chart for the demo application.

## Installation

```bash
# Dev environment
helm install demo-app . -f values.dev.yaml

# Production
helm install demo-app . -f values.prod.yaml
```

## Configuration

Main configuration in `values.yaml` with environment overrides:
- `values.dev.yaml` - Development (1 replica, minimal resources)
- `values.ci.yaml` - CI/Testing (fast probes, test mode)
- `values.prod.yaml` - Production (HA, HPA, network policies)

## Requirements

MongoDB must be deployed first:
```bash
helm install mongodb bitnami/mongodb -f ../../mongodb/values.dev.yaml
```

## Upgrade

```bash
helm upgrade demo-app . -f values.dev.yaml
```

## Uninstall

```bash
helm uninstall demo-app
```
