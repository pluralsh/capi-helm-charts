# capi-helm-charts

This repo contains helm charts to deploy the various cluster API components and providers.
They are automatically generated by a fork of [Helmify](https://github.com/davidspek/helmify/tree/capi) with changes specific for these charts.
Once this fork of Helmify matures it shall be released properly.

To add the repo run

```bash
helm repo add capi https://pluralsh.github.io/capi-helm-charts
helm repo update
```