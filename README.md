# helm-charts

Central registry for all Helm charts used in the ShopOps project.

## Repository structure

```
helm-charts/
├── kind-config.yaml        # Local Kubernetes cluster configuration (kind)
├── examples/
│   └── shop-cr.yaml        # Example Shop custom resource
└── charts/
    ├── shoppops-infra/     # Cluster infrastructure (install first)
    ├── shophub/            # ShopHub database
    └── shop/               # Shop storefront application
```

## Charts

### `shoppops-infra`

Bootstraps the local development cluster. Installs:

- **CNPG operator** — manages PostgreSQL clusters via the `Cluster` CRD
- **NGINX ingress controller** — configured for kind (hostPort, NodePort)
- **Shop operator CRDs** — `Shop`, `DiscordChannel`, `Wallet` (mock — no controller in local dev, CRDs only so ShopHub can create resources without errors)

Install first, before any other chart:

```bash
helm upgrade --install shoppops-infra ./charts/shoppops-infra
```

### `shophub`

Helm chart for the ShopHub application (Next.js frontend + NestJS backend) and its PostgreSQL
database provisioned via the CNPG operator.

> **Status: work in progress.** The ShopHub application is not yet built, so the chart currently
> only contains the database provisioning. Deployment resources (Deployment, Service, Ingress, etc.)
> will be added once the application exists.

For local development, the application runs via `npm run dev` and connects to the in-cluster
database through `kubectl port-forward`. In staging/production it will run fully in-cluster
behind the NGINX ingress.

Requires a `values.local.yaml` with a database password (see `values.local.example.yaml`):

```bash
helm upgrade --install shophub ./charts/shophub \
  --namespace shophub --create-namespace \
  -f charts/shophub/values.local.yaml
```

### `shop`

Helm chart for a Shop storefront instance (Next.js frontend + NestJS backend). Each shop created
in ShopHub gets its own release of this chart, deployed programmatically by the `shop-operator`
when it detects a new `Shop` custom resource. ShopHub creates the CR — the operator handles the
Helm install.

> **Status: work in progress.** The Shop application is not yet built, so the chart is a skeleton
> (no Deployment, Service, Ingress, or other templates yet). These will be added once the
> application exists.

Published to `ghcr.io/shopp-ops/helm-charts` as an OCI chart and referenced from `kube-state`.

## Local cluster setup

The included `kind-config.yaml` configures a single-node kind cluster with:

- **Port mappings** (80/443 host → container) so the NGINX ingress is reachable from localhost
- **`ingress-ready=true` node label** required by the NGINX ingress controller's `nodeSelector`

```bash
kind create cluster --config kind-config.yaml
```

## Install order

```
1. kind create cluster --config kind-config.yaml
2. helm upgrade --install shoppops-infra ./charts/shoppops-infra
3. helm upgrade --install shophub ./charts/shophub --namespace shophub --create-namespace -f charts/shophub/values.local.yaml
```
