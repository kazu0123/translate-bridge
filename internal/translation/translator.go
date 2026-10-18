package translation

// Translator handles translation and language detection
type Translator struct {
	impl TranslationImpl
}

// TranslationImpl is the interface for different translation implementations
type TranslationImpl interface {
	Translate(sourceText, sourceLang, targetLang string) (string, error)
	DetectLanguage(text string) (string, error)
}

// NewTranslator creates a new translator instance based on type
func NewTranslator(baseURL, apiKey, modelID, modelType string, maxTokens int) *Translator {
	var impl TranslationImpl

	switch modelType {
	case "translategemma":
		impl = NewTranslateGemmaTranslator(baseURL, apiKey, modelID, maxTokens)
	case "translategemma-vllm":
		impl = NewTranslateGemmaVLLMTranslator(baseURL, apiKey, modelID, maxTokens)
	case "translategemma-nullpolab-any2any":
		impl = NewTranslateGemmaNullpolabTranslator(baseURL, apiKey, modelID, maxTokens)
	case "generic":
		fallthrough
	default:
		// Default to generic translator (non-specialized models)
		impl = NewGenericTranslator(baseURL, apiKey, modelID, maxTokens)
	}

	return &Translator{impl: impl}
}

// Translate translates text
func (t *Translator) Translate(sourceText, sourceLang, targetLang string) (string, error) {
	return t.impl.Translate(sourceText, sourceLang, targetLang)
}

// DetectLanguage detects the language of text
func (t *Translator) DetectLanguage(text string) (string, error) {
	return t.impl.DetectLanguage(text)
}
