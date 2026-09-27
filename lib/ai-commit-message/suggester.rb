require 'net/http'
require 'uri'
require 'json'
require 'openssl'

module AiCommitMessage
  class Suggester
    class Error < StandardError; end
    class ConnectionError < Error; end
    class ApiError < Error; end

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 120
    DEFAULT_LENGTH = 72
    # Thinking models (qwen3 and friends) spend tokens reasoning before the
    # answer; the budget must leave room for both or content comes back empty.
    MAX_TOKENS = 2048

    def self.list_models(url)
      uri = URI("#{normalized_base(url)}/v1/models")
      http = build_http(uri)

      begin
        response = http.request(Net::HTTP::Get.new(uri))
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        raise ConnectionError,
              "Could not connect to #{uri.host}:#{uri.port}. Is your local LLM server running?"
      end

      parse_response(response).fetch('data', []).map { |m| m['id'] }.compact.sort
    end

    def self.parse_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, "API returned HTTP #{response.code}: #{response.body.to_s[0, 200]}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise ApiError, 'API response was not valid JSON'
    end

    def self.build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http
    end

    def self.normalized_base(url)
      url.chomp('/').sub(%r{/v1$}, '')
    end

    def initialize(git_diff_output, git_log_output, git_current_branch)
      @git_diff_output = git_diff_output
      @git_log_output = git_log_output
      @git_current_branch = git_current_branch
    end

    def generate_commit_message(url:, model:, length: DEFAULT_LENGTH, conventional: false)
      response = post_json(chat_completions_uri(url), request_body(model, length, conventional))
      json = self.class.parse_response(response)
      message = clean_commit_message(json.dig('choices', 0, 'message', 'content'), length)
      return message unless message.empty?

      raise ApiError,
            'Model returned no commit message content. Try a non-thinking model or a different model.'
    end

    private

    def request_body(model, length, conventional)
      {
        model: model,
        messages: [
          { role: 'system', content: system_prompt(conventional) },
          { role: 'user', content: user_prompt(length) }
        ],
        temperature: 0.3,
        max_tokens: MAX_TOKENS,
        stream: false
      }
    end

    def system_prompt(conventional)
      prompt = 'You write git commit messages. Respond with a single line containing ' \
               'only the commit message: no quotes, no backticks, no markdown, no explanations.'
      prompt += ' Use the Conventional Commits format (type: description).' if conventional
      prompt
    end

    def user_prompt(length)
      <<~PROMPT
        Write a concise git commit message with no more than #{length} characters for the staged changes below.
        Follow the style of these recent commit messages: #{@git_log_output}
        #{branch_line}
        Git diff:
        #{@git_diff_output}
      PROMPT
    end

    # git branch --show-current returns nothing on a detached HEAD
    def branch_line
      @git_current_branch.strip.empty? ? '' : "The current branch name is: #{@git_current_branch.strip}"
    end
    # Models tend to wrap answers in code fences or quotes, inline their
    # reasoning in <think> blocks, or offer alternatives; reduce everything to
    # a single clean subject line.
    def clean_commit_message(raw, length)
      line = raw.to_s
        .gsub(%r{<think>.*?</think>}m, '')
        .gsub('`', '')
        .each_line.map(&:strip).reject(&:empty?).first.to_s
      line = line.sub(/\A["'](.*)["']\z/, '\1')
      line.gsub(/\s+/, ' ')[0, length].to_s.strip
    end

    # Accepts base URLs with or without a trailing /v1 and with or without a
    # trailing slash, e.g. http://localhost:11434, http://localhost:1234/v1/
    def chat_completions_uri(url)
      URI("#{self.class.normalized_base(url)}/v1/chat/completions")
    end

    def post_json(uri, body)
      http = self.class.build_http(uri)
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = body.to_json

      begin
        http.request(request)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
        raise ConnectionError,
              "Could not connect to #{uri.host}:#{uri.port}. Is your local LLM server running?"
      end
    end
  end
end
