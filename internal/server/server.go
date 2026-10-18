package server

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"com.kokubokazuki/translate-bridge/internal/config"
	"com.kokubokazuki/translate-bridge/internal/translation"
)

// Server represents the HTTP server
type Server struct {
	cfg        *config.Config
	translator *translation.Translator
	detector   *translation.Translator
}

// New creates a new server instance
func New(cfg *config.Config) *Server {
	s := &Server{
		cfg: cfg,
	}

	// Initialize translator
	s.translator = translation.NewTranslator(
		cfg.UpstreamBaseURL,
		cfg.UpstreamAPIKey,
		cfg.TranslationModel.ID,
		cfg.TranslationModel.Type,
		cfg.TranslationModel.MaxTokens,
	)

	// Initialize detector
	s.detector = translation.NewTranslator(
		cfg.UpstreamBaseURL,
		cfg.UpstreamAPIKey,
		cfg.DetectionModel.ID,
		"", // detection doesn't use translator type
		cfg.DetectionModel.MaxTokens,
	)

	return s
}

// Handler returns the HTTP handler
func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/health", s.healthHandler)

	// LibreTranslate endpoints
	mux.HandleFunc("/translate", s.translateHandler)
	mux.HandleFunc("/detect", s.detectHandler)

	return mux
}

// Run starts the HTTP server
func (s *Server) Run(listenAddress string) error {
	// Setup HTTP server
	httpServer := &http.Server{
		Addr:    listenAddress,
		Handler: s.Handler(),
	}

	log.Printf("Starting server on %s", listenAddress)
	if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return fmt.Errorf("failed to run server: %w", err)
	}

	return nil
}

// Stop gracefully shuts down the server (for tests only, not used in production)
func (s *Server) Stop() {
	// This is handled by the OS signal in main
}

// healthHandler handles health check requests
func (s *Server) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// translateHandler handles translation requests
func (s *Server) translateHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Q            string `json:"q"`
		Source       string `json:"source"`
		Target       string `json:"target"`
		Format       string `json:"format,omitempty"`
		Alternatives int    `json:"alternatives,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request: %v", err), http.StatusBadRequest)
		return
	}

	if req.Q == "" {
		http.Error(w, "Missing required parameter 'q'", http.StatusBadRequest)
		return
	}

	if req.Target == "" {
		http.Error(w, "Missing required parameter 'target'", http.StatusBadRequest)
		return
	}

	// Perform translation
	translatedText, err := s.translator.Translate(req.Q, req.Source, req.Target)
	if err != nil {
		http.Error(w, fmt.Sprintf("Translation failed: %v", err), http.StatusInternalServerError)
		return
	}

	// Perform language detection if source is auto or empty
	detectedLang := ""
	if req.Source == "auto" || req.Source == "" {
		detectedLang, err = s.detector.DetectLanguage(req.Q)
		if err != nil {
			http.Error(w, fmt.Sprintf("Language detection failed: %v", err), http.StatusInternalServerError)
			return
		}
	}

	// Build response
	response := map[string]interface{}{
		"translatedText": translatedText,
	}

	if detectedLang != "" {
		response["detectedLanguage"] = map[string]interface{}{
			"confidence": float64(90),
			"language":   detectedLang,
		}
	}

	if req.Alternatives > 0 {
		response["alternatives"] = []string{} // Placeholder for alternatives
	}

	json.NewEncoder(w).Encode(response)
}

// detectHandler handles language detection requests
func (s *Server) detectHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Q string `json:"q"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request: %v", err), http.StatusBadRequest)
		return
	}

	if req.Q == "" {
		http.Error(w, "Missing required parameter 'q'", http.StatusBadRequest)
		return
	}

	// Perform language detection
	detectedLang, err := s.detector.DetectLanguage(req.Q)
	if err != nil {
		http.Error(w, fmt.Sprintf("Language detection failed: %v", err), http.StatusInternalServerError)
		return
	}

	// Build response (confidence is hardcoded as we can't determine it from the model)
	response := []map[string]interface{}{
		{
			"confidence": float64(90), // Default confidence
			"language":   detectedLang,
		},
	}

	json.NewEncoder(w).Encode(response)
}
