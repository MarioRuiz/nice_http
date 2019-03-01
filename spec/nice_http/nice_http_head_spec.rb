require "nice_http"

RSpec.describe NiceHttp, "#head" do
  before do
    @http = NiceHttp.new("https://www.reqres.in")
  end

  it "accepts path as string parameter" do
    resp = @http.head "/api/users?page=2"
    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  it "accepts Hash with key path" do
    resp = @http.head({ path: "/api/users?page=2" })
    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  it "returns error in case no path in hash" do
    resp = @http.head({})
    expect(resp.class).to eq Hash
    expect(resp.fatal_error).to match /no[\w\s]+path/i
    expect(resp.code).to eq nil
    expect(resp.message).to eq nil
  end

  it "returns the mock response if specified" do
    @http.use_mocks = true
    request = {
      path: "/api/users?page=2",
      mock_response: {
        code: 100,
        message: "mock",
      },
    }
    resp = @http.head(request)
    expect(resp.class).to eq Hash
    expect(resp.code).to eq 100
    expect(resp.message).to eq "mock"
  end

  it "set the cookies when required" do
    server = "https://samples.auth0.com/"
    path = "/authorize?client_id=kbyuFDidLLm280LIwVFiazOqjO3ty8KH&response_type=code"

    http = NiceHttp.new(server)
    http.auto_redirect = true
    resp = http.head(path)
    expect(resp.key?(:'set-cookie')).to eq true
    expect(http.cookies["/"].key?("auth0")).to eq true
  end

  it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
    server = "http://examplesinatra--tcblues.repl.co/"
    http = NiceHttp.new(server)
    http.auto_redirect = false
    req = {
      path: "/exampleRedirect",
      data: { example: "example" },
    }
    resp = http.head(req)
    expect(resp.code).to eq 303
  end
end
