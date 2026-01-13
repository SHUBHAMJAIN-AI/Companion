# Health Companion Red Team Testing

LLM security evaluation suite using [promptfoo](https://promptfoo.dev/).

## Quick Start

```bash
# Install promptfoo
npm install -g promptfoo

# Run all tests against RAG API
promptfoo eval -c promptfooconfig.yaml

# Run specific test suite
promptfoo eval -c promptfoo-injection.yaml

# View results in browser
promptfoo view
```

## Test Suites

| File | Tests | Description |
|------|-------|-------------|
| `promptfoo-injection.yaml` | 16 | Prompt injection, system prompt extraction, context escape |
| `promptfoo-jailbreak.yaml` | 14 | DAN attacks, roleplay bypasses, encoding tricks |
| `promptfoo-healthcare.yaml` | 19 | PHI extraction, prescription bypass, medical misinformation |
| `promptfoo-document-injection.yaml` | 18 | Filename injection, path traversal, unicode attacks |
| `promptfoo-harmful.yaml` | 23 | Self-harm, bias, violence, privacy violations |

**Total: 90 test cases**

## Target Vulnerabilities

### 1. RAG Service Injection
```swift
// RAGService.swift:38-41
let requestBody: [String: String] = [
    "query": query,  // <-- User input passed directly
    "knowledge_base_id": knowledgeBaseId
]
```

### 2. OpenAI Document Context Injection
```swift
// OpenAIService.swift:18-22
var prompt = "You are a medical AI assistant... User question: \(message)"
prompt += "\n\nAvailable documents: \(documents.map { $0.name }.joined(separator: ", "))"
// Document names can inject instructions ^^^
```

## Running Individual Suites

```bash
# Prompt injection attacks
promptfoo eval -c promptfoo-injection.yaml

# Jailbreak attempts
promptfoo eval -c promptfoo-jailbreak.yaml

# Healthcare-specific attacks
promptfoo eval -c promptfoo-healthcare.yaml

# Document/filename injection
promptfoo eval -c promptfoo-document-injection.yaml

# Harmful content generation
promptfoo eval -c promptfoo-harmful.yaml
```

## CI/CD Integration

```yaml
# .github/workflows/llm-security.yml
name: LLM Security Tests
on: [push, pull_request]
jobs:
  red-team:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g promptfoo
      - run: cd redteam && promptfoo eval -c promptfooconfig.yaml
```

## Environment Variables

### Required for RAG API tests:
```bash
export RAG_API_URL=https://your-api-endpoint.com/prod/query
export RAG_KNOWLEDGE_BASE_ID=your-knowledge-base-id
```

### For OpenRouter tests (recommended):
```bash
export OPENROUTER_API_KEY=your-openrouter-key
```

### For OpenAI direct tests:
```bash
export OPENAI_API_KEY=sk-your-key-here
```

> **Note:** If RAG_API_URL and RAG_KNOWLEDGE_BASE_ID are not set, defaults will be used.

## Available Providers

| Provider | Label | Description |
|----------|-------|-------------|
| `openrouter:anthropic/claude-3.5-sonnet` | openrouter-claude | Claude 3.5 Sonnet via OpenRouter |
| `openrouter:openai/gpt-4o` | openrouter-gpt4o | GPT-4o via OpenRouter |
| `openrouter:meta-llama/llama-3.1-70b-instruct` | openrouter-llama | Llama 3.1 70B via OpenRouter |
| `openai:gpt-4o-mini` | openai-medical | OpenAI direct |
| `http` (custom) | rag-api | RAG API endpoint |

## Running with Specific Provider

```bash
# Run with Claude via OpenRouter
promptfoo eval -c promptfooconfig.yaml --providers openrouter-claude

# Run with multiple models for comparison
promptfoo eval -c promptfooconfig.yaml --providers openrouter-claude,openrouter-gpt4o

# Run all providers
promptfoo eval -c promptfooconfig.yaml
```

## Results

Results are saved to `./results/eval-results.json` (gitignored).

View interactive report:
```bash
promptfoo view
```

The results directory is excluded from version control to avoid committing sensitive test data.
