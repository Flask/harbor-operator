package v1alpha1

import (
	h "github.com/mittwald/goharbor-client"
)

func (spec *RegistrySpec) ToHarborRegistry() *h.Registry {
	return &h.Registry{
		ID:              spec.ID,
		Name:            spec.Name,
		Description:     spec.Description,
		Type:            spec.Type,
		URL:             spec.URL,
		TokenServiceURL: spec.TokenServiceURL,
		Credential:      spec.Credential,
		Insecure:        spec.Insecure,
	}
}
