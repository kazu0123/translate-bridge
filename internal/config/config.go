package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
)

// Config represents the application configuration
type Config struct {
	Version         string   `json:"version"`
	ListenAddress   string   `json:"listen_address"`
	UpstreamBaseURL string   `json:"upstream_base_url"`
	UpstreamAPIKey  string   `json:"upstream_api_key"`
	TranslationModel Model    `json:"translation_model"`
	DetectionModel  Model    `json:"detection_model"`
	LogLevel        string   `json:"log_level,omitempty"`
}

// Model represents a language model configuration
type Model struct {
	ID        string `json:"id"`
	Type      string `json:"type,omitempty"`
	MaxTokens int    `json:"max_tokens"`
}

// LoadConfig loads the configuration from the config file
func LoadConfig() (*Config, error) {
	configPath := getConfigPath()

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	// Set defaults
	if cfg.LogLevel == "" {
		cfg.LogLevel = "info"
	}

	return &cfg, nil
}

// getConfigPath returns the path to the config file
func getConfigPath() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Fatal("Failed to get home directory")
	}
	return filepath.Join(homeDir, "Library", "Application Support", "Translate Bridge", "config.jsonc")
}
