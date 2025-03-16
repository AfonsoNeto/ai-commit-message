require 'thor'
require 'tty-prompt'
require_relative '../ai-commit-message/suggester'
require_relative 'config_manager'

module AiCommitMessage
  class CLI < Thor
    desc "commit", "Generate git commit message"
    method_option :url, type: :string, default: 'http://localhost:11434/api/generate'
    method_option :model, type: :string, default: 'qwen2.5-coder:7b'

    def commit(options = {})
      git_diff_output = `git diff --cached --no-color`
      git_log_output = `git log --format=%s -n 30`
      git_current_branch = `git branch --show-current`

      url = options[:url] || ConfigManager.get_url || 'http://localhost:11434/api/generate'
      model = options[:model] || ConfigManager.get_model || 'qwen2.5-coder:7b'

      suggester = AiCommitMessage::Suggester.new(git_diff_output, git_log_output, git_current_branch)
      commit_message = suggester.generate_commit_message(url:, model:)

      puts commit_message
    end

    desc "config", "Set global configs. API URL and Model name"
    def config
      prompt = TTY::Prompt.new

      url = prompt.ask("API URL:", default: ConfigManager.get_url || 'http://localhost:11434/api/generate')
      model = prompt.ask("Model name:", default: ConfigManager.get_model || 'qwen2.5-coder:7b')

      ConfigManager.set_url(url)
      ConfigManager.set_model(model)

      puts "Configuration updated successfully!"
    end
  end
end

AiCommitMessage::CLI.start