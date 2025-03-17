# AI Commit Message Generator

A Ruby gem that automatically generates concise and meaningful git commit messages using AI models via [Ollama](https://github.com/ollama/ollama) or any OpenAI-compatible API.

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
- [Ollama](https://github.com/ollama/ollama) model running locally or other OpenAI-compatible API endpoint

## Usage

### Basic Usage

Generate a commit message for your staged changes:

```bash
ai-commit-message commit
```

This will:
1. Analyze your staged changes (`git diff --cached`)
2. Review your recent commit history for style consistency
3. Consider your current branch name
4. Generate an appropriate commit message

### Configuration

You can configure the gem using the built-in configuration command:

```bash
ai-commit-message config
```

This interactive prompt allows you to set:
- **API URL**: The endpoint for your AI model (defaults to `http://localhost:11434`)
- **Model name**: The AI model to use (defaults to `qwen2.5-coder:7b`, which I personally recommend)

### Command Line Options

Override configuration settings directly:

```bash
ai-commit-message commit --url=http://your-api-endpoint --model=your-model-name
```

## How It Works

The gem:
1. Collects your staged changes using `git diff --cached`
2. Retrieves your recent commit history for context
3. Identifies your current branch name
4. Sends this information to the specified AI model
5. Returns a concise, contextual commit message (limited to 250 characters)

## Configuration File

The gem stores your configuration in `~/.ai-commit-message.conf`. You can manually edit this file if needed. Example:

```bash
url=http://localhost:11434
model=qwen2.5-coder:7b
```

## Models

The default configuration uses Ollama with the `qwen2.5-coder:7b` model, but you can use any model available through your API endpoint.

### Recommended Models

- **qwen2.5-coder:7b**: Good balance of quality and speed (default)
- **llama3:8b**: Excellent for general commit messages
- **codellama:7b**: Specialized for code-related commits

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b my-new-feature`
3. Install dependencies: `bundle install`
4. Make your changes and add tests if applicable
5. Commit your changes: `git commit -m 'Add some feature'`
6. Push to the branch: `git push origin my-new-feature`
7. Submit a pull request

## License

This gem is available as open source free to use/alter without restrictions.