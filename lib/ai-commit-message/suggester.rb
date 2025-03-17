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
      url = URI(url + '/api/generate')
      body = {
        model: model,
        prompt: "Create a concise git commit message with no more than 250 characters. Exclude anything unnecessary such as translation, backticks characters or multiple suggestions, since your entire response will be passed directly into git commit. Consider the following messages as example to follow: #{@git_log_output}.
            The First [#XXX] option is the branch name. The current branch name is: #{@git_current_branch}. Now Do it for the following git diff: #{@git_diff_output}",
        stream: false,
        options: { temperature: 0.8 }
      }
      json_body = body.to_json
      headers = { 'Content-Type' => 'application/json' }

      http = Net::HTTP.new(url.host, url.port)
      request = Net::HTTP::Post.new(url)
      request.body = json_body
      headers.each { |key, value| request[key] = value }
      response = http.request(request)

      begin
        json = JSON.parse(response.body)
        return json['response'] if json
      rescue JSON::ParserError => e
        puts "Failed to parse API response as JSON: #{e.message}"
      end

      nil
    end
  end
end