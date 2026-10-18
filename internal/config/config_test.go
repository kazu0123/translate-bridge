package config

import "testing"

func TestModelStruct(t *testing.T) {
	model := Model{
		ID:        "test-model",
		Type:      "translategemma",
		MaxTokens: 512,
	}

	if model.ID != "test-model" {
		t.Errorf("Expected ID to be 'test-model', got '%s'", model.ID)
	}

	if model.Type != "translategemma" {
		t.Errorf("Expected Type to be 'translategemma', got '%s'", model.Type)
	}

	if model.MaxTokens != 512 {
		t.Errorf("Expected MaxTokens to be 512, got %d", model.MaxTokens)
	}
}

func TestConfigStruct(t *testing.T) {
	cfg := Config{
		Version:         "1",
		ListenAddress:   "127.0.0.1:8080",
		UpstreamBaseURL: "http://localhost:5001/v1",
	}

	if cfg.ListenAddress != "127.0.0.1:8080" {
		t.Errorf("Expected ListenAddress to be '127.0.0.1:8080', got '%s'", cfg.ListenAddress)
	}
}
