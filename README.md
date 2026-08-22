# Helm Charts

This is a collection of helm charts that don't fit inside any of my other projects. Likely made for other, externally owned, projects. See the charts directory for a list of helm charts and their usage.

## Usage

Usage examples assume the generic chart.

### Install Chart via HTTP repository

```bash
helm repo add starttoaster https://starttoaster.github.io/helm-charts
helm repo update
helm install $RELEASE_NAME starttoaster/generic --version $CHART_VERSION -f $ADDITIONAL_VALUES_FILE
```

### Install Chart via OCI registry

```bash
helm install $RELEASE_NAME oci://ghcr.io/starttoaster/helm-charts/generic --version $CHART_VERSION -f $ADDITIONAL_VALUES_FILE
```

Note: Version and additional values file flags are optional.
