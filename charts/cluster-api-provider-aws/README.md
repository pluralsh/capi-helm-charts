# Cluster API Provider AWS

This helm chart installs the [Cluster API Provider AWS](https://github.com/kubernetes-sigs/cluster-api-provider-aws). It is automatically generated by a fork of [Helmify](https://github.com/arttor/helmify).

To install run the following commands

```bash
helm repo add capi https://pluralsh.github.io/capi-helm-charts
helm repo update
helm install capi-bootstrap capi/cluster-api-provider-aws
```

## Values

You must set the following values:

```yaml
managerBootstrapCredentials:
  AWS_ACCESS_KEY_ID: ""
  AWS_SECRET_ACCESS_KEY: ""
  AWS_REGION: ""
  AWS_SESSION_TOKEN: ""
```

After you move to the installation from the bootstrap cluster to the management cluster you need to set the value `bootstrapMode: false`.
This will nullify the credentials so that the controller uses the IAM role credentials. See [here](https://cluster-api-aws.sigs.k8s.io/topics/using-iam-roles-in-mgmt-cluster.html) for more details about this.
