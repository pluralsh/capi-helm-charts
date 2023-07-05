CORE_VERSION=v1.4.3
CONTROL_PLANE_VERSION=v1.4.3
BOOTSTRAP_VERSION=v1.4.3
DOCKER_VERSION=v1.4.3
AWS_VERSION=v2.1.4
AZURE_VERSION=v1.9.2
GCP_VERSION=v1.3.1

all: core control-plane bootstrap docker aws azure gcp

core:
	wget https://github.com/kubernetes-sigs/cluster-api/releases/download/${CORE_VERSION}/core-components.yaml
	kustomize build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-core/crds/provider-crd.yaml
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

docker:
	wget https://github.com/kubernetes-sigs/cluster-api/releases/download/${DOCKER_VERSION}/infrastructure-components-development.yaml
	cat infrastructure-components-development.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-provider-docker
	rm infrastructure-components-development.yaml
	yq -i ".appVersion=\"${DOCKER_VERSION}\"" charts/cluster-api-provider-docker/Chart.yaml
	yq -i ".configVariables.capdDockerHost=\"\"" charts/cluster-api-provider-docker/values.yaml

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

azure: # TODO: Looking at the raw yaml only 1 sa is used so the next isn't relevant, but further checking should be done. this is deploying multiple things so we need to improve the helmify fork to avoid clashes with SA names.
	wget https://github.com/kubernetes-sigs/cluster-api-provider-azure/releases/download/${AZURE_VERSION}/infrastructure-components.yaml
# This rewrites the data to stringData in the secret
	yq 'select(.kind == "Secret") | .stringData += .data | del(.data)' infrastructure-components.yaml > tmp.yaml
# This removes the Secret from the yaml
	yq 'del( select(.kind == "Secret"))' infrastructure-components.yaml > tmp2.yaml

# This combines the yaml files back together
	yq eval-all tmp.yaml tmp2.yaml > infrastructure-components.yaml

	cat infrastructure-components.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-provider-azure
	rm infrastructure-components.yaml tmp.yaml tmp2.yaml
	yq -i ".appVersion=\"${AZURE_VERSION}\"" charts/cluster-api-provider-azure/Chart.yaml

# This removes the awsB64EncodedCredentials from the values.yaml since it is being set by managerBootstrapCredentials.credentials instead
	yq -i "del(.configVariables.azureClientIdB64) | del(.configVariables.azureClientSecretB64) | del(.configVariables.azureSubscriptionIdB64) | del(.configVariables.azureTenantIdB64)" charts/cluster-api-provider-azure/values.yaml

gcp:
	wget https://github.com/kubernetes-sigs/cluster-api-provider-gcp/releases/download/${GCP_VERSION}/infrastructure-components.yaml
# This rewrites the data to stringData in the secret
	yq 'select(.kind == "Secret") | .data."credentials.json" = ""' infrastructure-components.yaml > tmp.yaml
# This removes the Secret from the yaml
	yq 'del( select(.kind == "Secret"))' infrastructure-components.yaml > tmp2.yaml

# This combines the yaml files back together
	yq eval-all tmp.yaml tmp2.yaml > infrastructure-components.yaml

	cat infrastructure-components.yaml | helmify -generate-defaults -image-pull-secrets charts/cluster-api-provider-gcp
	rm infrastructure-components.yaml tmp.yaml tmp2.yaml
	yq -i ".appVersion=\"${GCP_VERSION}\"" charts/cluster-api-provider-gcp/Chart.yaml
