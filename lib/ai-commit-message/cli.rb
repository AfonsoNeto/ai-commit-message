require 'thor'
require 'tty-prompt'
require_relative '../ai-commit-message/suggester'
require_relative 'config_manager'

module AiCommitMessage
  class CLI < Thor
    DEFAULT_URL = 'http://localhost:11434'
    DEFAULT_MODEL_NAME = 'qwen3:8b'
    MAX_DIFF_LENGTH = 12_000

    desc "commit", "Generate git commit message"
    method_option :url, type: :string
    method_option :model, type: :string

    def commit
      git_diff_output = `git diff --cached --no-color`
      if git_diff_output.strip.empty?
        warn 'Nothing is staged. Stage your changes with `git add` first.'
        exit 1
      end

      git_log_output = `git log --format=%s -n 30`
      git_current_branch = `git branch --show-current`

      url = url_to_be_used(options.url)
      model = model_to_be_used(options.model)

      suggester = AiCommitMessage::Suggester.new(git_diff_output[0, MAX_DIFF_LENGTH], git_log_output, git_current_branch)
      commit_message = suggester.generate_commit_message(url:, model:)

      puts commit_message
    end

    desc "config", "Set global configs. API URL and Model name"
    def config
      prompt = TTY::Prompt.new

      url = prompt.ask("API URL:", default: ConfigManager.get_url || DEFAULT_URL)
      model = prompt.ask("Model name:", default: ConfigManager.get_model || DEFAULT_MODEL_NAME)

      ConfigManager.set_url(url)
      ConfigManager.set_model(model)

      puts "Configuration updated successfully!"
    end

    private

    def url_to_be_used(options_url)
      options_url || ConfigManager.get_url || DEFAULT_URL
    end

    def model_to_be_used(options_model)
      options_model || ConfigManager.get_model || DEFAULT_MODEL_NAME
    end
  end
end

AiCommitMessage::CLI.start