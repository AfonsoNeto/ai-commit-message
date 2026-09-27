require_relative 'test_helper'

class SuggesterTest < Minitest::Test
  include TestHelper

  def setup
    @suggester = AiCommitMessage::Suggester.new('+def foo', 'add foo', 'feature/foo')
  end

  def test_chat_completions_uri_normalization
    [
      'http://localhost:11434',
      'http://localhost:11434/',
      'http://localhost:1234/v1',
      'http://localhost:1234/v1/'
    ].each do |url|
      uri = @suggester.send(:chat_completions_uri, url)
      assert_equal '/v1/chat/completions', uri.path
      assert_equal 'localhost', uri.host
    end
  end

  def test_normalized_base_keeps_custom_paths
    assert_equal 'http://localhost:8080/api', AiCommitMessage::Suggester.normalized_base('http://localhost:8080/api/')
  end

  def test_clean_commit_message_strips_code_fences_and_quotes
    assert_equal 'feat: add login page', @suggester.send(:clean_commit_message, "```\nfeat: add login page\n```", 72)
    assert_equal 'Fix the parser bug', @suggester.send(:clean_commit_message, '"Fix the parser bug"', 72)
  end

  def test_clean_commit_message_takes_first_line
    assert_equal 'fix: handle nil', @suggester.send(:clean_commit_message, "fix: handle nil\n\nAlternative: something else", 72)
  end

  def test_clean_commit_message_truncates_to_length
    assert_equal 'a' * 10, @suggester.send(:clean_commit_message, 'a' * 100, 10)
    assert_equal '', @suggester.send(:clean_commit_message, nil, 72)
  end

  def test_build_http_enables_ssl_verification_for_https
    http = AiCommitMessage::Suggester.build_http(URI('https://api.example.com/v1/chat/completions'))
    assert http.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, http.verify_mode
  end

  def test_build_http_keeps_plain_http_local
    http = AiCommitMessage::Suggester.build_http(URI('http://localhost:11434/v1/chat/completions'))
    refute http.use_ssl?
  end

  def test_clean_commit_message_strips_inline_think_blocks
    raw = "<think>Let me decide on wording.</think>\nfix: handle nil diff"
    assert_equal 'fix: handle nil diff', @suggester.send(:clean_commit_message, raw, 72)
  end

  def test_generate_commit_message_raises_when_content_is_empty
    with_mock_server(openai_chat_response('')) do |port|
      assert_raises AiCommitMessage::Suggester::ApiError do
        @suggester.generate_commit_message(url: "http://127.0.0.1:#{port}", model: 'm')
      end
    end
  end

  def test_generate_commit_message_returns_cleaned_content
    with_mock_server(openai_chat_response("```\nfix: avoid nil crash\n```")) do |port|
      message = @suggester.generate_commit_message(url: "http://127.0.0.1:#{port}", model: 'test-model')
      assert_equal 'fix: avoid nil crash', message
    end
  end

  def test_generate_commit_message_uses_chat_completions_and_chat_payload
    request = nil
    server = TCPServer.new('127.0.0.1', 0)
    body = openai_chat_response('ok')
    thread = Thread.new do
      client = server.accept
      request = +''
      request << client.readpartial(4096) until request.include?("\r\n\r\n")
      client.write("HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
      client.close
    end
    begin
      @suggester.generate_commit_message(url: "http://127.0.0.1:#{server.addr[1]}/v1", model: 'm', conventional: true)
    ensure
      thread.join
      server.close
    end

    assert_includes request, "POST /v1/chat/completions"
    json_body = JSON.parse(request.split("\r\n\r\n").last)
    assert_equal 'm', json_body['model']
    assert_equal 'system', json_body['messages'][0]['role']
    assert_includes json_body['messages'][0]['content'], 'Conventional Commits'
    assert_equal 0.3, json_body['temperature']
  end

  def test_generate_commit_message_omits_branch_when_detached
    suggester = AiCommitMessage::Suggester.new('', '', '')
    prompt = suggester.send(:user_prompt, 72)
    refute_includes prompt, 'The current branch name is'
  end

  def test_api_error_on_http_failure
    with_mock_server({'error' => 'boom'}.to_json, status: '500 Internal Server Error') do |port|
      assert_raises AiCommitMessage::Suggester::ApiError do
        @suggester.generate_commit_message(url: "http://127.0.0.1:#{port}", model: 'm')
      end
    end
  end

  def test_api_error_on_invalid_json
    with_mock_server('not json') do |port|
      assert_raises AiCommitMessage::Suggester::ApiError do
        @suggester.generate_commit_message(url: "http://127.0.0.1:#{port}", model: 'm')
      end
    end
  end

  def test_connection_error_when_server_is_down
    server = TCPServer.new('127.0.0.1', 0)
    closed_port = server.addr[1]
    server.close

    assert_raises AiCommitMessage::Suggester::ConnectionError do
      @suggester.generate_commit_message(url: "http://127.0.0.1:#{closed_port}", model: 'm')
    end
  end

  def test_list_models_returns_sorted_ids
    with_mock_server({ data: [{ id: 'zeta' }, { id: 'alpha' }] }.to_json) do |port|
      models = AiCommitMessage::Suggester.list_models("http://127.0.0.1:#{port}")
      assert_equal %w[alpha zeta], models
    end
  end

  def test_list_models_normalizes_v1_suffix
    with_mock_server({ data: [{ id: 'm' }] }.to_json) do |port|
      models = AiCommitMessage::Suggester.list_models("http://127.0.0.1:#{port}/v1")
      assert_equal ['m'], models
    end
  end
end
