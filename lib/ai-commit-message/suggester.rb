require 'net/http'
require 'uri'
require 'json'

module AiCommitMessage
  class Suggester
    def initialize(git_diff_output, git_log_output, git_current_branch)
      @git_diff_output = git_diff_output
      @git_log_output = git_log_output
      @git_current_branch = git_current_branch
    end

    def generate_commit_message(url:, model:)
      response = post_json(chat_completions_uri(url), request_body(model))
      json = JSON.parse(response.body)
      json.dig('choices', 0, 'message', 'content')
    end

    private

    def request_body(model)
      {
        model: model,
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: user_prompt }
        ],
        temperature: 0.3,
        max_tokens: 100,
        stream: false
      }
    end

    def system_prompt
      'You write git commit messages. Respond with a single line containing ' \
        'only the commit message: no quotes, no backticks, no markdown, no explanations.'
    end

    def user_prompt
      <<~PROMPT
        Write a concise git commit message with no more than 250 characters for the staged changes below.
        Follow the style of these recent commit messages: #{@git_log_output}
        The current branch name is: #{@git_current_branch}
        Git diff:
        #{@git_diff_output}
      PROMPT
    end

    # Accepts base URLs with or without a trailing /v1 and with or without a
    # trailing slash, e.g. http://localhost:11434, http://localhost:1234/v1/
    def chat_completions_uri(url)
      base = url.chomp('/')
      base = base.sub(%r{/v1$}, '')
      URI("#{base}/v1/chat/completions")
    end

    def post_json(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = body.to_json
      http.request(request)
    end
  end
end
