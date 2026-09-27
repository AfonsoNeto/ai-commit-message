# AI git commit message

A Ruby gem that automatically generates concise and meaningful git commit messages using a local LLM via [Ollama](https://github.com/ollama/ollama), LM Studio, llama.cpp `llama-server`, or any other OpenAI-compatible API.

![Terminal demo](docs/demo.gif)

## Installation

Install the gem using:

```bash
gem install ai-commit-message
```

Or add it to your Gemfile:

```ruby
gem 'ai-commit-message'
```

And then run:

```bash
bundle install
```

## Requirements

- Ruby 3.0 or newer
- Git repository
- A local LLM server: [Ollama](https://github.com/ollama/ollama), [LM Studio](https://lmstudio.ai/), [llama.cpp `llama-server`](https://github.com/ggml-org/llama.cpp), or any other OpenAI-compatible endpoint

## Usage

### Basic Usage

Generate a commit message for your staged changes and commit with it after a confirmation:

```bash
ai-commit-message commit
```

This will:
1. Analyze your staged changes (`git diff --cached`)
2. Review your recent commit history for style consistency
3. Consider your current branch name
4. Generate an appropriate commit message
5. Ask for confirmation and create the commit (answering "no" keeps the printed message so you can edit or copy it)

### Message only

If you just want the suggested message without the confirmation prompt — e.g. to pipe it somewhere or review it yourself — use `--message-only`:

```bash
ai-commit-message commit --message-only
```

### Conventional Commits

Ask the model to follow the [Conventional Commits](https://www.conventionalcommits.org/) format (`feat:`, `fix:`, `chore:`, ...):

```bash
ai-commit-message commit --conventional
```

### Configuration

Configure the API URL and model interactively:

```bash
ai-commit-message config
```

If your server is reachable, the model prompt becomes a picker populated with the models available on that server.

List the models available on your server:

```bash
ai-commit-message models
```

### Command Line Options

Override configuration settings directly:

```bash
ai-commit-message commit --url=http://your-api-endpoint --model=your-model-name
```

All options:

| Option | Description | Default |
| --- | --- | --- |
| `--url` | Base URL of the OpenAI-compatible API | `http://localhost:11434` |
| `--model` | Model name | `qwen3:8b` |
| `--length` | Maximum message length in characters | `72` |
| `--conventional` | Use Conventional Commits format | off |
| `--message-only` | Print the message without the commit confirmation prompt | off |

## How It Works

The gem:
1. Collects your staged changes using `git diff --cached` (capped at 12,000 characters so large diffs don't overwhelm a local model's context)
2. Retrieves your recent commit history for context
3. Identifies your current branch name
4. Sends a chat request to `{url}/v1/chat/completions` — the standard OpenAI-compatible endpoint
5. Cleans the model output (strips code fences, quotes and reasoning blocks) and prints a single-line commit message (limited to 72 characters by default)

The URL accepts base addresses with or without a trailing `/v1` and `/`, so `http://localhost:11434` (Ollama), `http://localhost:1234/v1` (LM Studio) and `http://localhost:8080` (llama.cpp `llama-server`) all work as-is.

## Configuration File

The gem stores your configuration in `~/.ai-commit-message.conf`. You can manually edit this file if needed. Example:

```bash
url=http://localhost:11434
model=qwen3:8b
```

## Models

The default configuration uses Ollama with the `qwen3:8b` model, but you can use any model available through your API endpoint.

### Recommended Models

- **qwen3:8b**: Good balance of quality and speed (default). Note that it is a thinking model, so expect a few seconds of reasoning before the message appears
- **qwen2.5-coder:7b**: Faster, non-thinking coding model
- **qwen3.5:4b**: Current-generation small model for modest hardware
- **gemma4:e4b**: Compact general-purpose option
- **llama3.1:8b**: Solid general-purpose choice

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b my-new-feature`
3. Install dependencies: `bundle install`
4. Run the tests: `bundle exec rake test`
5. Make your changes and add tests if applicable
6. Commit your changes: `git commit -m 'Add some feature'`
7. Push to the branch: `git push origin my-new-feature`
8. Submit a pull request

## License

This gem is available as open source under the terms of the [MIT License](LICENSE).
