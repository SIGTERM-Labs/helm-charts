# Helm Charts

## Usage

Usage examples assume the generic chart.

### Install Chart via HTTP repository

```bash
helm repo add sigtermlabs https://sigterm-labs.github.io/helm-charts
helm repo update
helm install $RELEASE_NAME sigtermlabs/generic --version $CHART_VERSION -f $ADDITIONAL_VALUES_FILE
```

### Install Chart via OCI registry

```bash
helm install $RELEASE_NAME oci://ghcr.io/sigterm-labs/helm-charts/generic --version $CHART_VERSION -f $ADDITIONAL_VALUES_FILE
```

Note: Version and additional values file flags are optional.
