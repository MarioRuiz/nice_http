require "nice_http"

RSpec.describe NiceHttp, "#get" do
  before do
    NiceHttp.log_files = Hash.new()
    @http = NiceHttp.new("https://reqres.in")
  end

  it "accepts path as string parameter" do
    resp = @http.get "/api/users?page=2"
    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  it "accepts Hash with key path" do
    resp = @http.get({path: "/api/users?page=2"})
    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  it "returns error in case no path in hash" do
    resp = @http.get({})
    expect(resp.class).to eq Hash
    expect(resp.fatal_error).to match /no[\w\s]+path/i
    expect(resp.code).to eq nil
    expect(resp.message).to eq nil
    expect(resp.data).to eq nil
  end

  it "returns the mock response if specified" do
    @http.use_mocks = true
    request = {
      path: "/api/users?page=2",
      mock_response: {
        code: 100,
        message: "mock",
        data: {example: "mock"},
      },
    }
    resp = @http.get(request)
    expect(resp.class).to eq Hash
    expect(resp.code).to eq 100
    expect(resp.message).to eq "mock"
    expect(resp.data.json).to eq ({example: "mock"})
  end

  it "redirects when auto_redirect is true and http code is 30x" do
    server = "https://samples.auth0.com/"
    path = "/authorize?client_id=kbyuFDidLLm280LIwVFiazOqjO3ty8KH&response_type=code"

    http = NiceHttp.new(server)
    http.auto_redirect = true
    resp = http.get(path)

    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
    server = "https://samples.auth0.com/"
    path = "/authorize?client_id=kbyuFDidLLm280LIwVFiazOqjO3ty8KH&response_type=code"

    http = NiceHttp.new(server)
    http.auto_redirect = false
    resp = http.get(path)
    expect(resp.code).to eq 302
    expect(resp.message).to eq "Found"
  end

  it "handles correctly when http or https is on path" do
    resp = @http.get "https://reqres.in/api/users?page=2"
    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  # todo: I need to find another ws, this one is not including set-cookie anymore
  xit "set the cookies when required" do
    server = "https://samples.auth0.com/"
    path = "/authorize?client_id=kbyuFDidLLm280LIwVFiazOqjO3ty8KH&response_type=code"

    http = NiceHttp.new(server)
    http.auto_redirect = true
    resp = http.get(path)
    expect(resp.key?(:'set-cookie')).to eq true
    expect(http.cookies["/"].key?("auth0")).to eq true
  end

  it "detects wrong json when supplying wrong mock_response data" do
    request = {
      path: "/api/users?page=2",
      mock_response: {
        code: 200,
        message: "OK",
        data: {a: "Android\xAE"},
      },
    }
    @http.use_mocks = true
    resp = @http.get request
    content = File.read("./nice_http.log")
    expect(content).to match /There was a problem converting to json/
  end

  it 'returns on headers the time_request and time_response' do
    started = Time.now
    resp = @http.get "/api/users?delay=1"
    finished = Time.now
    expect(resp.time_request >= started)
    expect(resp.time_request <= finished)
    expect(resp.time_response >= finished)
  end

end
