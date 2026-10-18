package main

import (
	"log"

	"com.kokubokazuki/translate-bridge/internal/config"
	"com.kokubokazuki/translate-bridge/internal/server"
)

func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Create server
	srv := server.New(cfg)

	// Setup HTTP server and start
	if err := srv.Run(cfg.ListenAddress); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
