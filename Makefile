CORE_VERSION=v1.4.3
CONTROL_PLANE_VERSION=v1.4.3
BOOTSTRAP_VERSION=v1.4.3
AWS_VERSION=v2.1.4

core:
	wget https://github.com/kubernetes-sigs/cluster-api/releases/download/${CORE_VERSION}/core-components.yaml
	kustomize build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" >> core-components.yaml
	cat core-components.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-core
	rm core-components.yaml
	yq -i ".appVersion=\"${CORE_VERSION}\"" charts/cluster-api-core/Chart.yaml

control-plane:
	wget https://github.com/kubernetes-sigs/cluster-api/releases/download/${CONTROL_PLANE_VERSION}/control-plane-components.yaml
	cat control-plane-components.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-control-plane
	rm control-plane-components.yaml
	yq -i ".appVersion=\"${CONTROL_PLANE_VERSION}\"" charts/cluster-api-control-plane/Chart.yaml

bootstrap:
	wget https://github.com/kubernetes-sigs/cluster-api/releases/download/${BOOTSTRAP_VERSION}/bootstrap-components.yaml
	cat bootstrap-components.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-bootstrap
	rm bootstrap-components.yaml
	yq -i ".appVersion=\"${BOOTSTRAP_VERSION}\"" charts/cluster-api-bootstrap/Chart.yaml

aws:
	wget https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/${AWS_VERSION}/infrastructure-components.yaml
# This rewrites the data to stringData in the secret
	yq 'select(.kind == "Secret") | .stringData += .data | del(.data)' infrastructure-components.yaml > tmp.yaml

# This rewrites the annotation on the ServiceAccount so the environment variable is able to be parsed properly
	yq 'select(.kind == "ServiceAccount")| del(.metadata.annotations.*)  | .metadata.annotations."eks.amazonaws.com/role-arn"="$${AWS_CONTROLLER_IAM_ROLE:=\"\"}"' infrastructure-components.yaml > tmp2.yaml

# This removes the Secret and ServiceAccount from the yaml
	yq 'del( select(.kind == "Secret" or .kind == "ServiceAccount"))' infrastructure-components.yaml > tmp3.yaml

# This combines the yaml files back together
	yq eval-all tmp.yaml tmp2.yaml tmp3.yaml > infrastructure-components.yaml

	cat infrastructure-components.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-provider-aws
	rm infrastructure-components.yaml tmp.yaml tmp2.yaml tmp3.yaml
	yq -i ".appVersion=\"${AWS_VERSION}\"" charts/cluster-api-provider-aws/Chart.yaml
# This removes the awsB64EncodedCredentials from the values.yaml since it is being set by managerBootstrapCredentials.credentials instead
	yq -i "del(.configVariables.awsB64EncodedCredentials)" charts/cluster-api-provider-aws/values.yaml
# Delete the secret file since we are managing that ourselves
	rm charts/cluster-api-provider-aws/templates/manager-bootstrap-credentials.yaml
# Add proper credentials input and the bootstrapMode toogle to easily nullify the credentials. Also set `awsControllerIamRole` to proper empty string
	yq -i ".configVariables.awsControllerIamRole=\"\" | .bootstrapMode="true" | del(.managerBootstrapCredentials.credentials) | .managerBootstrapCredentials.AWS_ACCESS_KEY_ID=\"\" | .managerBootstrapCredentials.AWS_SECRET_ACCESS_KEY=\"\" | .managerBootstrapCredentials.AWS_REGION=\"\" | .managerBootstrapCredentials.AWS_SESSION_TOKEN=\"\"" charts/cluster-api-provider-aws/values.yaml
