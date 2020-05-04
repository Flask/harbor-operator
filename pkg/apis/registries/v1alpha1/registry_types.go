package v1alpha1

import (
	h "github.com/mittwald/goharbor-client"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type RegistryStatusPhaseName string

const (
	RegistryStatusPhaseUnknown     RepositoryStatusPhaseName = ""
	RegistryStatusPhaseCreating                              = "Creating"
	RegistryStatusPhaseReady                                 = "Ready"
	RegistryStatusPhaseTerminating                           = "Terminating"
)

// RegistrySpec defines the desired state of a Registry
type RegistrySpec struct {
	// Registry ID, gets autogenerated (last project id +1) when left empty
	// +optional
	ID int64 `json:"id,omitempty"`

	Name string `json:"name"`

	// +optional
	Description string `json:"description,omitempty"`

	// TODO: A string enum would be appropriate here, though kubebuilder seems to not like this annotation:
	// "+kubebuilder:validation:Enum:=harbor,docker-hub,docker-registry,huawei-SWR,google-gcr,aws-ecr,azure-acr,ali-acr,jfrog-artifactory,quay-io,gitlab,helm-hub"
	// Leaving it as is for the time being
	Type h.RegistryType `json:"type"`

	// Target URL of the registry
	URL string `json:"url"`

	// TokenServiceURL is only used for local harbor instances to
	// avoid the requests passing through the external proxy for now
	// +optional
	TokenServiceURL string `json:"token_service_url,omitempty"`

	// +optional
	Credential *h.Credential `json:"credential,omitempty"`

	// Whether or not the TLS certificate will be verified when Harbor tries to access the registry
	// +optional
	Insecure bool `json:"insecure,omitempty"`

	// ParentInstance is a LocalObjectReference to the
	// name of the harbor instance the registry is created for
	ParentInstance corev1.LocalObjectReference `json:"parentInstance"`
}

// RegistryStatus defines the observed state of Registry
type RegistryStatus struct {
	Name    string                    `json:"name"`
	Phase   RepositoryStatusPhaseName `json:"phase"`
	Message string                    `json:"message"`
	// Time of last observed transition into this state
	// +optional
	LastTransition *metav1.Time `json:"lastTransition,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// Registry is the Schema for the registries API
// +kubebuilder:subresource:status
// +kubebuilder:resource:path=registries,scope=Namespaced
// +kubebuilder:printcolumn:name="Status",type="string",JSONPath=".status.phase",description="phase"
type Registry struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec RegistrySpec `json:"spec,omitempty"`

	Status RegistryStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// RegistryList contains a list of Registry
type RegistryList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Registry `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Registry{}, &RegistryList{})
}
