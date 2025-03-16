require 'thor'
require_relative '../ai-commit-message/suggester'

module AiCommitMessage
  class CLI < Thor
    desc "commit", "Generate git commit message"
    method_option :url, type: :string, default: 'http://192.168.1.152:1234/v1/chat/completions'
    method_option :model, type: :string, default: 'qwen2.5-coder:7b'

    def commit
      git_diff_output = `git diff --cached --no-color`
      git_log_output = `git log --format=%s -n 30`
      git_current_branch = `git branch --show-current`

      url = options[:url]
      model = options[:model]

      suggester = AiCommitMessage::Suggester.new(git_diff_output, git_log_output, git_current_branch)
      commit_message = suggester.generate_commit_message

      puts commit_message
    end
  end
end

AiCommitMessage::CLI.start