# frozen_string_literal: true

# Start fake API server(s) in-process (same Ruby as rspec). No subprocess or bundle exec.
# Set USE_FAKE_API=false to use external hosts (reqres.in, etc.).

require "socket"

def port_open?(host, port)
  TCPSocket.new(host, port).close
  true
rescue Errno::ECONNREFUSED, Errno::EADDRINUSE
  false
end

def wait_for_server(host, port, timeout: 10)
  started = Time.now
  until port_open?(host, port)
    raise "Server on #{host}:#{port} did not start in #{timeout}s" if Time.now - started > timeout
    sleep 0.1
  end
end

TEST_SERVER_PORT = (ENV["TEST_SERVER_PORT"] || 4567).to_i
TEST_SERVER_PORT_2 = (ENV["TEST_SERVER_PORT_2"] || 4568).to_i
TEST_SERVER_HOST = "localhost"
TEST_SERVER_URL = "http://#{TEST_SERVER_HOST}:#{TEST_SERVER_PORT}"
TEST_SERVER_URL_2 = "http://#{TEST_SERVER_HOST}:#{TEST_SERVER_PORT_2}"

if ENV["USE_FAKE_API"] != "false"
  begin
    require "sinatra/base"
    require "webrick"
    require_relative "fake_api"

    # Run two servers in threads (stats_spec needs two host:port).
    # Use a subclass per port so Sinatra doesn't reuse the same port.
    [TEST_SERVER_PORT, TEST_SERVER_PORT_2].each do |port|
      Thread.new do
        app = Class.new(FakeApi) { set :port, port }
        app.run!(
          server: "webrick",
          Logger: WEBrick::Log.new(File::NULL),
          AccessLog: [],
        )
      end
    end

    wait_for_server(TEST_SERVER_HOST, TEST_SERVER_PORT)
    wait_for_server(TEST_SERVER_HOST, TEST_SERVER_PORT_2)

    ENV["HOST_EXAMPLE_SINATRA"] = TEST_SERVER_URL
    ENV["TEST_SERVER_URL"] = TEST_SERVER_URL
    ENV["TEST_SERVER_URL_2"] = TEST_SERVER_URL_2
    ENV["TEST_SERVER_PORT"] = TEST_SERVER_PORT.to_s
    ENV["TEST_SERVER_PORT_2"] = TEST_SERVER_PORT_2.to_s
  rescue LoadError => e
    warn "Fake API skipped (Sinatra not available: #{e.message}); set USE_FAKE_API=false to use external hosts."
    ENV["USE_FAKE_API"] = "false"
  rescue StandardError => e
    warn "Fake API server failed to start (#{e.message}); set USE_FAKE_API=false to use external hosts."
    ENV["USE_FAKE_API"] = "false"
  end
end
