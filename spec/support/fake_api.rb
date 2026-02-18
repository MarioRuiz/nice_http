# frozen_string_literal: true

# Fake API server for nice_http specs (reqres.in-style + async + redirects + set-cookie).
# Loaded by spec/support/server.rb for in-process use, or run standalone: ruby spec/support/fake_api.rb [port]
require "sinatra/base"
require "json"
require "uri"

class FakeApi < Sinatra::Base
  set :port, (ENV["FAKE_API_PORT"] || ARGV[0] || 4567).to_i

  # In-memory state for async operation polling
  OPERATION_POLLS = Hash.new(0)

  get "/" do
    content_type "text/plain"
    "OK"
  end

  # Echo a request header for testing headers.generate (e.g. X-Custom-Header)
  get "/echo_headers" do
    content_type "application/json"
    { "X-Custom-Header" => request.env["HTTP_X_CUSTOM_HEADER"] }.to_json
  end

  # Response with non-UTF-8 charset for encoding conversion tests (é in ISO-8859-1)
  get "/encoding_iso8859" do
    content_type "text/plain; charset=ISO-8859-1"
    "caf\xE9".dup.force_encoding(Encoding::ISO_8859_1)
  end

  post "/" do
    content_type "text/plain"
    status 200
    "OK"
  end

  # --- reqres.in-style API ---
  get "/api/users" do
    delay = params["delay"].to_i
    sleep(delay) if delay > 0
    content_type "application/json"
    {
      page: params["page"] || 1,
      per_page: 6,
      total: 12,
      total_pages: 2,
      data: [
        { id: 1, first_name: "George", last_name: "Bluth", avatar: "https://example.com/1.jpg" },
        { id: 2, first_name: "Janet", last_name: "Weaver", avatar: "https://example.com/2.jpg" },
      ],
    }.to_json
  end

  get "/api/users/2" do
    content_type "application/json"
    {
      data: {
        id: 2,
        first_name: "Janet",
        last_name: "Weaver",
        avatar: "https://example.com/2.jpg",
      },
    }.to_json
  end

  post "/api/users" do
    content_type "application/json"
    status 201
    body = request.body.read
    parsed = begin
        body.empty? ? {} : JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    if parsed.is_a?(Array)
      response = parsed
    else
      response = parsed.transform_keys(&:to_sym).merge(
        id: "999",
        createdAt: Time.now.utc.iso8601(3),
      )
    end
    response.to_json
  end

  put "/api/users/2" do
    content_type "application/json"
    body = request.body.read
    parsed = begin
        body.empty? ? {} : JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    (parsed.transform_keys(&:to_sym).merge(id: "2", updatedAt: Time.now.utc.iso8601(3))).to_json
  end

  patch "/api/users/2" do
    content_type "application/json"
    body = request.body.read
    parsed = begin
        body.empty? ? {} : JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    (parsed.transform_keys(&:to_sym).merge(id: "2", updatedAt: Time.now.utc.iso8601(3))).to_json
  end

  delete "/api/users/2" do
    status 204
    body ""
  end

  delete "/api/users" do
    status 204
    body ""
  end

  post "/api/register" do
    content_type "application/json"
    status 200
    { id: 1, token: "QpwL5tke4Pnpja7X4" }.to_json
  end

  # --- set-cookie ---
  %w[get post put patch delete head].each do |meth|
    send(meth, "/setcookie") do
      headers["Set-Cookie"] = "something=value; path=/"
      content_type "text/plain"
      "OK"
    end
  end

  # --- redirect (302) ---
  # NiceHttp strips "scheme://host" (no port) from Location, so use "http://host/path" (no port).
  redirect_302 = proc do
    status 302
    headers["Location"] = "http://#{request.host}/redirect_target"
    content_type "text/plain"
    ""
  end
  get "/exampleRedirect", &redirect_302
  post "/exampleRedirect", &redirect_302
  put "/exampleRedirect", &redirect_302
  patch "/exampleRedirect", &redirect_302
  delete "/exampleRedirect", &redirect_302
  head "/exampleRedirect", &redirect_302

  %w[get post put patch delete head].each do |meth|
    send(meth, "/redirect_target") do
      content_type "text/plain"
      status 200
      "OK"
    end
  end

  # --- form-urlencoded (post /register returns 201 and body with decoded params) ---
  post "/register" do
    content_type "text/plain"
    status 201
    body_str = request.body.read
    # Echo back decoded form so "my firstname" appears in response
    decoded = URI.decode_www_form(body_str).to_h
    decoded.map { |k, v| "#{k}=#{v}" }.join("&")
  end

  # --- async (202 + polling + resource) ---
  get "/async" do
    operation_id = rand(100..999).to_s
    resource_id = operation_id.reverse
    OPERATION_POLLS[operation_id] = 0
    base = "#{request.scheme}://#{request.host}:#{request.port}"
    headers["Location"] = "#{base}/operation/#{operation_id}"
    content_type "application/json"
    status 202
    { result: "this is an async operation id: #{operation_id}" }.to_json
  end

  get "/operation/:id" do
    id = params["id"]
    OPERATION_POLLS[id] += 1
    poll = OPERATION_POLLS[id]
    resource_id = id.reverse
    if poll >= 5 # 4 "Ongoing" polls then Done so resp.async.seconds == 4
      status_json = "Done"
      perc = 100
    else
      status_json = "Ongoing"
      perc = 25
    end
    content_type "application/json"
    {
      percComplete: perc,
      resourceName: "/resource/#{resource_id}",
      status: status_json,
      operationId: id,
    }.to_json
  end

  get "/resource/:id" do
    content_type "application/json"
    { resourceId: params["id"], lolo: "lala" }.to_json
  end
end

FakeApi.run! if __FILE__ == $PROGRAM_NAME
