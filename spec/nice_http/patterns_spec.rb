require "nice_http"
require "uri"
require "fileutils"

RSpec.describe NiceHttp, "pattern values" do
  before do
    NiceHttp.log_files = {}
    @http = NiceHttp.new(TEST_SERVER_URL)
  end

  it "expands shorthands in the body and leaves literal strings" do
    resp = @http.post(
      path: "/api/users",
      data: {
        name: "ada",
        user_id: :uuid,
        email: "placeholder",
        iban: :iban,
        german_iban: [:iban, "DE"],
        card: :luhn,
        short_card: [:luhn, 15],
        job: :"leader|developer",
        age: 18..30,
        tags: [:"1:L"],
        code: "10:N",
        choice: "a|b",
      },
      values_for: { email: :email },
    )
    expect(resp.code).to eq 201
    body = resp.data.json
    expect(body[:name]).to eq "ada"
    expect(body[:code]).to eq "10:N"
    expect(body[:choice]).to eq "a|b"
    expect(StringPattern.valid_uuid?(body[:user_id])).to be true
    expect(StringPattern.valid_email?(body[:email])).to be true
    expect(body[:email]).not_to eq "placeholder"
    expect(body[:iban]).to start_with("ES")
    expect(StringPattern.valid_iban?(body[:iban])).to be true
    expect(body[:german_iban]).to start_with("DE")
    expect(StringPattern.valid_iban?(body[:german_iban])).to be true
    expect(body[:card].size).to eq 16
    expect(StringPattern.valid_luhn?(body[:card])).to be true
    expect(body[:short_card].size).to eq 15
    expect(StringPattern.valid_luhn?(body[:short_card])).to be true
    expect(%w[leader developer]).to include(body[:job])
    expect(body[:age]).to be_between(18, 30)
    expect(body[:tags]).to be_a(Array)
    expect(body[:tags].size).to be_between(1, 5)
    body[:tags].each do |tag|
      expect(StringPattern.valid?(text: tag, pattern: :"1:L")).to be true
    end
  end

  it "expands nested patterns, regexp, datetime and boolean, and keeps a plain symbol" do
    resp = @http.post({
      path: "/api/users",
      data: {
        role: :admin,
        user: { pin: :"4:N" },
        items: [{ sku: :"3:N", note: "keep" }],
        token: /[A-Z]{4}/,
        created: DateTime,
        active: Boolean,
      },
    })
    expect(resp.code).to eq 201
    body = resp.data.json
    expect(body[:role]).to eq "admin"
    expect(body[:user][:pin]).to match(/\A\d{4}\z/)
    expect(body[:items].size).to eq 1
    expect(body[:items][0][:sku]).to match(/\A\d{3}\z/)
    expect(body[:items][0][:note]).to eq "keep"
    expect(body[:token]).to match(/\A[A-Z]{4}\z/)
    expect(body[:created]).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+/)
    expect([true, false]).to include(body[:active])
  end

  it "expands an array of hashes" do
    resp = @http.post({
      path: "/api/users",
      data: [{ sku: :"3:N", note: "keep" }, { sku: :"3:N", note: "also" }],
    })
    expect(resp.code).to eq 201
    body = resp.data.json
    expect(body.size).to eq 2
    expect(body[0][:note]).to eq "keep"
    expect(body[1][:note]).to eq "also"
    body.each { |row| expect(row[:sku]).to match(/\A\d{3}\z/) }
  end

  it "generates a connection header once and a request header on every call" do
    uri = URI(TEST_SERVER_URL)
    http = NiceHttp.new(host: uri.host, port: uri.port, headers: { "X-Custom-Header" => :"10:N" })
    first = http.get({ path: "/echo_headers" }).data.json[:"X-Custom-Header"]
    second = http.get({ path: "/echo_headers" }).data.json[:"X-Custom-Header"]
    expect(first).to match(/\A\d{10}\z/)
    expect(second).to eq first
  end

  it "expands a request header on each call" do
    headers = { "X-Custom-Header" => :"12:N" }
    first = @http.get({ path: "/echo_headers", headers: headers })
    second = @http.get({ path: "/echo_headers", headers: headers })
    first_value = first.data.json[:"X-Custom-Header"]
    second_value = second.data.json[:"X-Custom-Header"]
    expect(first_value).to match(/\A\d{12}\z/)
    expect(second_value).to match(/\A\d{12}\z/)
    expect(second_value).not_to eq first_value
  end

  it "logs a mock response that has no content-type and still stores cookies" do
    log_file = "./tmp/missing_content_type.log"
    FileUtils.mkdir_p("./tmp")
    File.delete(log_file) if File.exist?(log_file)
    uri = URI(TEST_SERVER_URL)
    http = NiceHttp.new(host: uri.host, port: uri.port, log: log_file, use_mocks: true)
    resp = http.get({
      path: "/mock",
      mock_response: {
        code: "200",
        message: "OK",
        data: "hello",
        :"set-cookie" => "something=value; path=/",
      },
    })
    expect(resp.data).to eq "hello"
    expect(http.cookies["/"]).to have_key("something")
    log = File.read(log_file)
    expect(log).to include("hello")
    expect(log).not_to include("manage_response Error")
  end
end
