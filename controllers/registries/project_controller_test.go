package registries_test

import (
	"github.com/mittwald/harbor-operator/apis/registries/v1alpha2"
	registriestesting "github.com/mittwald/harbor-operator/controllers/registries/testing"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
)

var _ = Describe("ProjectController", func() {
	BeforeEach(func() {
		name = testProjectName
		namespace = testNamespaceName
		request = ctrl.Request{
			NamespacedName: types.NamespacedName{
				Name:      name,
				Namespace: namespace,
			},
		}
	})
	Describe("Create, Get and Delete", func() {
		var project *v1alpha2.Project
		Context("Project", func() {
			BeforeEach(func() {
				project = registriestesting.CreateProject(name, namespace, "")
				Ω(k8sClient.Create(ctx, project)).Should(Succeed())
				Ω(k8sClient.Get(ctx, types.NamespacedName{
					Name:      name,
					Namespace: namespace,
				},
					project)).Should(Succeed())
			})
			AfterEach(func() {
				Ω(k8sClient.Delete(ctx, project)).Should(Succeed())
			})
			It("Should not be nil", func() {
				Ω(project).ToNot(BeNil())
			})
		})
	})
})
