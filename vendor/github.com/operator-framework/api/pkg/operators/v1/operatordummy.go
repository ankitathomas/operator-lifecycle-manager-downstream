package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// OperatorDummySpec is a dummy
type OperatorDummySpec struct {
	ServiceAccounts []string           `json:"serviceAccounts,omitempty"`
	Deployments     []string           `json:"deployments,omitempty"`
	Overrides       []metav1.Condition `json:"overrides,omitempty"`
}

// OperatorDummyStatus reports itself a dummy
type OperatorDummyStatus struct {
	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +genclient
// +kubebuilder:storageversion
// +kubebuilder:subresource:status
// OperatorDummy dummy dummy
type OperatorDummy struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata"`

	Spec   OperatorDummySpec   `json:"spec,omitempty"`
	Status OperatorDummyStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// OperatorDummyList big dumb
type OperatorDummyList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []OperatorDummy `json:"items"`
}

func init() {
	SchemeBuilder.Register(&OperatorDummy{}, &OperatorDummyList{})
}
