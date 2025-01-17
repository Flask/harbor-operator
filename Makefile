# Current Operator version
VERSION ?= 0.0.1
# Default bundle image tag
BUNDLE_IMG ?= harbor-operator-bundle:$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= quay.io/mittwald/harbor-operator:latest
# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd:trivialVersions=true,preserveUnknownFields=false"

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec
 all: build

all: manager

# Run tests
ENVTEST_ASSETS_DIR = $(shell pwd)/testbin
test: generate fmt vet manifests
	mkdir -p $(ENVTEST_ASSETS_DIR)
	test -f $(ENVTEST_ASSETS_DIR)/setup-envtest.sh || curl -sSLo $(ENVTEST_ASSETS_DIR)/setup-envtest.sh https://raw.githubusercontent.com/kubernetes-sigs/controller-runtime/v0.8.1/hack/setup-envtest.sh
	source $(ENVTEST_ASSETS_DIR)/setup-envtest.sh; fetch_envtest_tools $(ENVTEST_ASSETS_DIR); setup_envtest_env $(ENVTEST_ASSETS_DIR); go test ./... -coverprofile cover.out

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager main.go

# Run against the configured Kubernetes cluster in ~/.kube/config
run: generate fmt vet manifests
	go run ./main.go

debug: generate fmt vet manifests manager
	dlv --listen=:2345 --headless=true --api-version=2 exec bin/manager --

# Generate manifests e.g. CRD, RBAC etc.
manifests: controller-gen
	go mod download && go mod tidy
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases
	# build helm-chart
	echo "# AUTOGENERATED BY 'make manifests' - DO NOT EDIT!" | tee \
		./deploy/helm-chart/harbor-operator/templates/role.yaml \
		./deploy/helm-chart/harbor-operator/templates/role_binding.yaml \
		./deploy/helm-chart/harbor-operator/templates/leader_election_role.yaml \
		./deploy/helm-chart/harbor-operator/templates/leader_election_role_binding.yaml \
		./deploy/helm-chart/harbor-operator/templates/monitor.yaml
	echo "{{ if .Values.serviceMonitor.enabled }}" >> ./deploy/helm-chart/harbor-operator/templates/monitor.yaml
	$(SED) 's/manager-role/{{ include "harbor-operator.name" . }}/g' ./config/rbac/role.yaml >> ./deploy/helm-chart/harbor-operator/templates/role.yaml
	$(SED) 's/manager-rolebinding/{{ include "harbor-operator.name" . }}/g; s/manager-role/{{ include "harbor-operator.name" . }}/g; s/default/{{ include "harbor-operator.name" . }}/g; s/system/{{ .Release.Namespace }}/g' \
		./config/rbac/role_binding.yaml >> ./deploy/helm-chart/harbor-operator/templates/role_binding.yaml
	$(SED) 's/leader-election-role/{{ include "harbor-operator.name" . }}-leader-election/g' ./config/rbac/leader_election_role.yaml >> ./deploy/helm-chart/harbor-operator/templates/leader_election_role.yaml
	$(SED) 's/leader-election-rolebinding/{{ include "harbor-operator.name" . }}-leader-election/g; s/leader-election-role/{{ include "harbor-operator.name" . }}-leader-election/g; s/name\: default/name\: {{ include "harbor-operator.name" . }}/g; s/namespace\: system/namespace\: {{ .Release.Namespace }}/g' \
		 ./config/rbac/leader_election_role_binding.yaml >> ./deploy/helm-chart/harbor-operator/templates/leader_election_role_binding.yaml
	$(SED) 's/controller-manager-metrics-monitor/{{ include "harbor-operator.fullname" . }}/g; 1,/control-plane: controller-manager/ s/control-plane: controller-manager/{{- include "harbor-operator.labels" . | nindent 4 }}/g; 2,/control-plane: controller-manager/ s/control-plane: controller-manager/app.kubernetes.io\/instance: {{ .Release.Name }}/g; s/port: https/port: metrics/g; s/namespace\: system/namespace\: {{ .Release.Namespace }}/g' \
		 ./config/prometheus/monitor.yaml >> ./deploy/helm-chart/harbor-operator/templates/monitor.yaml
	echo "{{ end }}" >> ./deploy/helm-chart/harbor-operator/templates/monitor.yaml

UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
SED=gsed
else
SED=sed
endif

# Run go fmt against code
fmt: imports
	go fmt $$(go list ./...)

GO_FILES := $(shell find . -type f -name '*.go')

# Run goimports against code
imports:
	@goimports -w -d $(GO_FILES)||:

# Run go vet against code
vet:
	go vet $$(go list ./...)

# Generate code
generate: controller-gen
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./apis/..."
	rm -r ./pkg/apis/v* && cp -rf ./apis/registries/* ./pkg/apis/
	cd pkg/apis && go mod tidy

# Build the docker image
docker-build:
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}

# Download controller-gen locally if necessary
CONTROLLER_GEN = $(shell pwd)/bin/controller-gen
controller-gen:
	$(call go-get-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen@v0.6.1)

# Download kustomize locally if necessary
KUSTOMIZE = $(which kustomize)
kustomize:
	$(call go-get-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v3@v3.8.7)


# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go get $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: manifests
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	operator-sdk bundle validate ./bundle

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .
