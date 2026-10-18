package translation

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// TranslateGemmaTranslator implements the Translator interface for TranslateGemma
type TranslateGemmaTranslator struct {
	baseURL   string
	apiKey    string
	modelID   string
	maxTokens int
}

// NewTranslateGemmaTranslator creates a new TranslateGemma translator
func NewTranslateGemmaTranslator(baseURL, apiKey, modelID string, maxTokens int) *TranslateGemmaTranslator {
	return &TranslateGemmaTranslator{
		baseURL:   baseURL,
		apiKey:    apiKey,
		modelID:   modelID,
		maxTokens: maxTokens,
	}
}

// Translate translates text using TranslateGemma
func (t *TranslateGemmaTranslator) Translate(sourceText, sourceLang, targetLang string) (string, error) {
	// Build messages according to TranslateGemma format
	// Per the model spec: content must be a list with exactly one entry
	// containing type, source_lang_code, target_lang_code, and text
	messages := []map[string]interface{}{
		{
			"role": "user",
			"content": []map[string]interface{}{
				{
					"type":           "text",
					"source_lang_code": sourceLang,
					"target_lang_code": targetLang,
					"text":           sourceText,
				},
			},
		},
	}

	request := map[string]interface{}{
		"model":   t.modelID,
		"messages": messages,
	}

	return t.sendRequest(request)
}

// DetectLanguage detects the language of the given text
func (t *TranslateGemmaTranslator) DetectLanguage(text string) (string, error) {
	prompt := fmt.Sprintf(
		"Determine the language of the following text. Return only the ISO 639-1 language code.\nText: %s\nLanguage:",
		text,
	)

	return t.sendRequest(prompt)
}

// sendRequest sends a request to the OpenAI-compatible API
func (t *TranslateGemmaTranslator) sendRequest(request interface{}) (string, error) {
	jsonData, err := json.Marshal(request)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	url := t.buildURL()
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if t.apiKey != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", t.apiKey))
	}

	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(body))
	}

	// Parse response
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	// Try different response formats
	if choices, ok := result["choices"].([]interface{}); ok && len(choices) > 0 {
		if choice, ok := choices[0].(map[string]interface{}); ok {
			if message, ok := choice["message"].(map[string]interface{}); ok {
				if content, ok := message["content"].(string); ok {
					return strings.TrimSpace(content), nil
				}
			}
			if delta, ok := choice["delta"].(map[string]interface{}); ok {
				if content, ok := delta["content"].(string); ok {
					return strings.TrimSpace(content), nil
				}
			}
		}
	}

	// Try alternative format with text field
	if text, ok := result["text"].(string); ok {
		return strings.TrimSpace(text), nil
	}

	// Return raw result for debugging
	raw, _ := json.Marshal(result)
	return "", fmt.Errorf("failed to extract translation from response. Raw response: %s", string(raw))
}

// buildURL builds the API endpoint URL
func (t *TranslateGemmaTranslator) buildURL() string {
	// Try common OpenAI-compatible endpoint patterns
	if strings.HasSuffix(t.baseURL, "/v1") {
		return t.baseURL + "/chat/completions"
	}
	if strings.HasSuffix(t.baseURL, "/v1/") {
		return t.baseURL + "chat/completions"
	}
	if strings.Contains(t.baseURL, "/v1") {
		return t.baseURL + "/chat/completions"
	}
	return t.baseURL + "/v1/chat/completions"
}
