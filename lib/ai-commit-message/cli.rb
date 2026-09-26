require 'thor'
require 'tty-prompt'
require_relative '../ai-commit-message/suggester'
require_relative 'config_manager'

module AiCommitMessage
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    DEFAULT_URL = 'http://localhost:11434'
    DEFAULT_MODEL_NAME = 'qwen3:8b'
    MAX_DIFF_LENGTH = 12_000

    desc "commit", "Generate git commit message"
    method_option :url, type: :string
    method_option :model, type: :string
    method_option :length, type: :numeric, default: Suggester::DEFAULT_LENGTH
    method_option :conventional, type: :boolean, default: false
    method_option :apply, type: :boolean, default: false

    def commit
      git_diff_output = `git diff --cached --no-color`
      if git_diff_output.strip.empty?
        warn 'Nothing is staged. Stage your changes with `git add` first.'
        exit 1
      end

      git_log_output = `git log --format=%s -n 30`
      git_current_branch = `git branch --show-current`

      suggester = AiCommitMessage::Suggester.new(git_diff_output[0, MAX_DIFF_LENGTH], git_log_output, git_current_branch)
      commit_message = suggester.generate_commit_message(
        url: url_to_be_used(options.url),
        model: model_to_be_used(options.model),
        length: options.length,
        conventional: options.conventional
      )

      puts commit_message
      return unless options.apply

      prompt = TTY::Prompt.new
      return unless prompt.yes?("Commit with this message?", default: true)

      system('git', 'commit', '-m', commit_message)
    rescue AiCommitMessage::Suggester::Error => e
      warn e.message
      exit 1
    end

    desc "models", "List models available on the configured API URL"
    method_option :url, type: :string

    def models
      puts AiCommitMessage::Suggester.list_models(url_to_be_used(options.url))
    rescue AiCommitMessage::Suggester::Error => e
      warn e.message
      exit 1
    end

    desc "config", "Set global configs. API URL and Model name"
    def config
      prompt = TTY::Prompt.new

      url = prompt.ask("API URL:", default: ConfigManager.get_url || DEFAULT_URL)
      available_models = AiCommitMessage::Suggester.list_models(url) rescue nil
      model = if available_models && !available_models.empty?
        prompt.select("Model name:", available_models)
      else
        prompt.ask("Model name:", default: ConfigManager.get_model || DEFAULT_MODEL_NAME)
      end

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