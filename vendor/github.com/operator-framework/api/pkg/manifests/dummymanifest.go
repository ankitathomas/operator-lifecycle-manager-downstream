package manifests

// DummyManifest holds information about a dummy, which is a reference to one (or more)
// channels under a single dummy.
type DummyManifest struct {
	// DummyName is the name of the overall dummy, ala `etcd`.
	DummyName string `json:"dummyName" yaml:"dummyName"`

	// Channels are the declared channels for the dummy, ala `stable` or `alpha`.
	Channels []DummyChannel `json:"channels" yaml:"channels"`

	// DefaultChannelName is, if specified, the name of the default channel for the dummy. The
	// default channel will be installed if no other channel is explicitly given. If the dummy
	// has a single channel, then that channel is implicitly the default.
	DefaultChannelName string `json:"defaultChannel" yaml:"defaultChannel"`
}

// IsEmpty returns true if the DummyManifest instance is equal to the zero value
func (p *DummyManifest) IsEmpty() bool {
	return p.DummyName == "" && len(p.Channels) == 0 && p.DefaultChannelName == ""
}

// DummyChannel defines a single channel under a dummy, pointing to a version of that
// dummy.
type DummyChannel struct {
	// Name is the name of the channel, e.g. `alpha` or `stable`
	Name string `json:"name" yaml:"name"`

	// CurrentCSVName defines a reference to the CSV holding the version of this dummy currently
	// for the channel.
	CurrentCSVName string `json:"currentCSV" yaml:"currentCSV"`
}
