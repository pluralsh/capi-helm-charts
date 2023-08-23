CORE_VERSION=v1.5.0# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api
CONTROL_PLANE_VERSION=v1.5.0# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api
BOOTSTRAP_VERSION=v1.5.0# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api
DOCKER_VERSION=v1.5.0# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api
AWS_VERSION=v2.2.1# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api-provider-aws
AZURE_VERSION=v1.10.2# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api-provider-azure
GCP_VERSION=v1.4.0# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api-provider-gcp


## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries
KUSTOMIZE ?= $(LOCALBIN)/kustomize
HELMIFY ?= $(LOCALBIN)/helmify
YQ ?= $(LOCALBIN)/yq

.PHONY: kustomize
kustomize: $(KUSTOMIZE)
$(KUSTOMIZE): $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/kustomize/kustomize/v4@v4.5.2

.PHONY: helmify
helmify: $(HELMIFY)
$(HELMIFY): $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install github.com/pluralsh/helmify/cmd/helmify@capi

.PHONY: yq
yq: $(YQ)
$(YQ): $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install github.com/mikefarah/yq/v4@latest

all: kustomize helmify yq core control-plane bootstrap docker aws azure gcp

core: kustomize helmify yq
	curl -OL https://github.com/kubernetes-sigs/cluster-api/releases/download/${CORE_VERSION}/core-components.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-core/crds/provider-crd.yaml
	cat core-components.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-core
	rm core-components.yaml
	@if [ $$($(YQ) ".appVersion" charts/cluster-api-core/Chart.yaml) != "${CORE_VERSION}" ]; then \
		echo "Updating Core appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${CORE_VERSION}\"" charts/cluster-api-core/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-core/Chart.yaml; \
	fi

control-plane: kustomize helmify yq
	curl -OL https://github.com/kubernetes-sigs/cluster-api/releases/download/${CONTROL_PLANE_VERSION}/control-plane-components.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-control-plane/crds/provider-crd.yaml
	cat control-plane-components.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-control-plane
	rm control-plane-components.yaml
	@if [ $$($(YQ) ".appVersion" charts/cluster-api-control-plane/Chart.yaml) != "${CONTROL_PLANE_VERSION}" ]; then \
		echo "Updating Control Plane appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${CONTROL_PLANE_VERSION}\"" charts/cluster-api-control-plane/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-control-plane/Chart.yaml; \
	fi

bootstrap: kustomize helmify yq
	curl -OL https://github.com/kubernetes-sigs/cluster-api/releases/download/${BOOTSTRAP_VERSION}/bootstrap-components.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-bootstrap/crds/provider-crd.yaml
	cat bootstrap-components.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-bootstrap
	rm bootstrap-components.yaml
	@if [ $$($(YQ) ".appVersion" charts/cluster-api-bootstrap/Chart.yaml) != "${BOOTSTRAP_VERSION}" ]; then \
		echo "Updating Bootstrap appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${BOOTSTRAP_VERSION}\"" charts/cluster-api-bootstrap/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-bootstrap/Chart.yaml; \
	fi

docker: kustomize helmify yq
	curl -OL https://github.com/kubernetes-sigs/cluster-api/releases/download/${DOCKER_VERSION}/infrastructure-components-development.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-provider-docker/crds/provider-crd.yaml
	cat infrastructure-components-development.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-provider-docker
	rm infrastructure-components-development.yaml
	$(YQ) -i ".configVariables.capdDockerHost=\"\"" charts/cluster-api-provider-docker/values.yaml
	@if [ $$($(YQ) ".appVersion" charts/cluster-api-provider-docker/Chart.yaml) != "${DOCKER_VERSION}" ]; then \
		echo "Updating Docker appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${DOCKER_VERSION}\"" charts/cluster-api-provider-docker/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-provider-docker/Chart.yaml; \
	fi

aws: kustomize helmify yq
	curl -OL https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/${AWS_VERSION}/infrastructure-components.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts//cluster-api-provider-aws/crds/provider-crd.yaml
# This rewrites the data to stringData in the secret
	$(YQ) 'select(.kind == "Secret") | .stringData += .data | del(.data)' infrastructure-components.yaml > tmp.yaml

# This rewrites the annotation on the ServiceAccount so the environment variable is able to be parsed properly
	$(YQ) 'select(.kind == "ServiceAccount")| del(.metadata.annotations.*)  | .metadata.annotations."eks.amazonaws.com/role-arn"="$${AWS_CONTROLLER_IAM_ROLE:=\"\"}"' infrastructure-components.yaml > tmp2.yaml

# This removes the Secret and ServiceAccount from the yaml
	$(YQ) 'del( select(.kind == "Secret" or .kind == "ServiceAccount"))' infrastructure-components.yaml > tmp3.yaml

# This combines the yaml files back together
	$(YQ) eval-all tmp.yaml tmp2.yaml tmp3.yaml > infrastructure-components.yaml

	cat infrastructure-components.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-provider-aws
	rm infrastructure-components.yaml tmp.yaml tmp2.yaml tmp3.yaml
# This removes the awsB64EncodedCredentials from the values.yaml since it is being set by managerBootstrapCredentials.credentials instead
	$(YQ) -i "del(.configVariables.awsB64EncodedCredentials)" charts/cluster-api-provider-aws/values.yaml
# Delete the secret file since we are managing that ourselves
	rm charts/cluster-api-provider-aws/templates/manager-bootstrap-credentials.yaml
# Add proper credentials input and the bootstrapMode toogle to easily nullify the credentials. Also set `awsControllerIamRole` to proper empty string
	$(YQ) -i ".configVariables.awsControllerIamRole=\"\" | .bootstrapMode="true" | del(.managerBootstrapCredentials.credentials) | .managerBootstrapCredentials.AWS_ACCESS_KEY_ID=\"\" | .managerBootstrapCredentials.AWS_SECRET_ACCESS_KEY=\"\" | .managerBootstrapCredentials.AWS_REGION=\"\" | .managerBootstrapCredentials.AWS_SESSION_TOKEN=\"\"" charts/cluster-api-provider-aws/values.yaml

	@if [ $$($(YQ) ".appVersion" charts/cluster-api-provider-aws/Chart.yaml) != "${AWS_VERSION}" ]; then \
		echo "Updating AWS appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${AWS_VERSION}\"" charts/cluster-api-provider-aws/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-provider-aws/Chart.yaml; \
	fi

azure: kustomize helmify yq # TODO: Looking at the raw yaml only 1 sa is used so the next isn't relevant, but further checking should be done. this is deploying multiple things so we need to improve the helmify fork to avoid clashes with SA names.
	curl -OL https://github.com/kubernetes-sigs/cluster-api-provider-azure/releases/download/${AZURE_VERSION}/infrastructure-components.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-provider-azure/crds/provider-crd.yaml
# This rewrites the data to stringData in the secret
	$(YQ) 'select(.kind == "Secret") | .stringData += .data | del(.data)' infrastructure-components.yaml > tmp.yaml
# This removes the Secret from the yaml
	$(YQ) 'del( select(.kind == "Secret"))' infrastructure-components.yaml > tmp2.yaml

# This combines the yaml files back together
	$(YQ) eval-all tmp.yaml tmp2.yaml > infrastructure-components.yaml

	cat infrastructure-components.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-provider-azure
	rm infrastructure-components.yaml tmp.yaml tmp2.yaml

# This removes the awsB64EncodedCredentials from the values.yaml since it is being set by managerBootstrapCredentials.credentials instead
	$(YQ) -i "del(.configVariables.azureClientIdB64) | del(.configVariables.azureClientSecretB64) | del(.configVariables.azureSubscriptionIdB64) | del(.configVariables.azureTenantIdB64)" charts/cluster-api-provider-azure/values.yaml

	@if [ $$($(YQ) ".appVersion" charts/cluster-api-provider-azure/Chart.yaml) != "${AZURE_VERSION}" ]; then \
		echo "Updating Azure appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${AZURE_VERSION}\"" charts/cluster-api-provider-azure/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-provider-azure/Chart.yaml; \
	fi

gcp: kustomize helmify yq
	curl -OL https://github.com/kubernetes-sigs/cluster-api-provider-gcp/releases/download/${GCP_VERSION}/infrastructure-components.yaml
	$(KUSTOMIZE) build "https://github.com/kubernetes-sigs/cluster-api/cmd/clusterctl/config/crd/?ref=${CORE_VERSION}" > charts/cluster-api-provider-gcp/crds/provider-crd.yaml
# This rewrites the data to stringData in the secret
	$(YQ) 'select(.kind == "Secret") | .data."credentials.json" = ""' infrastructure-components.yaml > tmp.yaml
# This removes the Secret from the yaml
	$(YQ) 'del( select(.kind == "Secret"))' infrastructure-components.yaml > tmp2.yaml

# This combines the yaml files back together
	$(YQ) eval-all tmp.yaml tmp2.yaml > infrastructure-components.yaml

	cat infrastructure-components.yaml | $(HELMIFY) -generate-defaults -image-pull-secrets charts/cluster-api-provider-gcp
	rm infrastructure-components.yaml tmp.yaml tmp2.yaml

	# Delete the secret file since we are managing that ourselves
	rm charts/cluster-api-provider-gcp/templates/manager-bootstrap-credentials.yaml
	# Add the bootstrapMode toggle to easily nullify the credentials.
	$(YQ) -i ".bootstrapMode=false" charts/cluster-api-provider-gcp/values.yaml

	@if [ $$($(YQ) ".appVersion" charts/cluster-api-provider-gcp/Chart.yaml) != "${GCP_VERSION}" ]; then \
		echo "Updating GCP appVersion and chart version"; \
		$(YQ) -i ".appVersion=\"${GCP_VERSION}\"" charts/cluster-api-provider-gcp/Chart.yaml; \
		$(YQ) -i '.version |= (split(".") | .[-1] |= ((. tag = "!!int") + 1) | join("."))' charts/cluster-api-provider-gcp/Chart.yaml; \
	fi
