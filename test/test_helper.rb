require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/ai-commit-message/suggester'
require_relative '../lib/ai-commit-message/config_manager'

module TestHelper
  # Reads a full HTTP request from the socket: headers plus Content-Length
  # bytes of body. Segments can arrive split across multiple reads.
  def read_http_request(client)
    request = +''
    request << client.readpartial(4096) until request.include?("\r\n\r\n")
    headers, body = request.split("\r\n\r\n", 2)
    body = +(body || '')
    content_length = headers[/^Content-Length: (\d+)$/i, 1].to_i
    body << client.readpartial(4096) while body.bytesize < content_length
    "#{headers}\r\n\r\n#{body}"
  end

  # Minimal dependency-free HTTP server returning a canned JSON response.
  # Yields the bound port and returns the full received HTTP request.
  def with_mock_server(response_body, status: '200 OK')
    server = TCPServer.new('127.0.0.1', 0)
    thread = nil
    received = nil
    begin
      thread = Thread.new do
        client = server.accept
        received = read_http_request(client)
        client.write(
          "HTTP/1.1 #{status}\r\n" \
          "Content-Type: application/json\r\n" \
          "Content-Length: #{response_body.bytesize}\r\n" \
          "Connection: close\r\n\r\n#{response_body}"
        )
        client.close
      end
      yield server.addr[1]
    ensure
      # Close the server first so a thread still blocked in accept can exit.
      server&.close
      thread&.join(1)
    end
    received
  end

  def openai_chat_response(content)
    { choices: [{ message: { role: 'assistant', content: content } }] }.to_json
  end
end
