module github.com/mittwald/harbor-operator

go 1.16

require (
	github.com/go-logr/logr v0.4.0
	github.com/imdario/mergo v0.3.12
	github.com/jinzhu/copier v0.0.0-20190924061706-b57f9002281a
	github.com/mittwald/go-helm-client v0.8.0
	github.com/mittwald/goharbor-client/v4 v4.0.0
	github.com/onsi/ginkgo v1.16.4
	github.com/onsi/gomega v1.13.0
	github.com/spf13/pflag v1.0.5
	github.com/spf13/viper v1.7.0
	github.com/stretchr/testify v1.7.0
	helm.sh/helm/v3 v3.6.2
	k8s.io/api v0.21.2
	k8s.io/apiextensions-apiserver v0.21.2
	k8s.io/apimachinery v0.21.2
	k8s.io/client-go v0.21.2
	sigs.k8s.io/controller-runtime v0.9.2
	sigs.k8s.io/yaml v1.2.0
)

replace sigs.k8s.io/kustomize/api => sigs.k8s.io/kustomize/api v0.8.11
