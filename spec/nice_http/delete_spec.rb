require "nice_http"

RSpec.describe NiceHttp, "#delete" do
  before do
    NiceHttp.log_files = Hash.new()
    @http = NiceHttp.new("https://reqres.in")
  end

  it "accepts path as string parameter" do
    resp = @http.delete "/api/users/2"
    expect(resp.code).to eq 204
  end

  it "accepts Hash with key path" do
    resp = @http.delete({path: "/api/users/2"})
    expect(resp.code).to eq 204
  end

  it "returns error in case no path in hash" do
    resp = @http.delete({})
    expect(resp.class).to eq Hash
    expect(resp.fatal_error).to match /no[\w\s]+path/i
    expect(resp.code).to eq nil
    expect(resp.message).to eq nil
    expect(resp.data).to eq nil
  end

  it "returns the mock response if specified" do
    @http.use_mocks = true
    request = {
      path: "/api/users/2",
      mock_response: {
        code: 100,
        message: "mock",
        data: {example: "mock"},
      },
    }
    resp = @http.delete(request)
    expect(resp.class).to eq Hash
    expect(resp.code).to eq 100
    expect(resp.message).to eq "mock"
    expect(resp.data.json).to eq ({example: "mock"})
  end

  it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
    server = "https://examplesinatra--tcblues.repl.co/"
    http = NiceHttp.new(server)
    http.auto_redirect = false
    req = {
      path: "/exampleRedirect",
      data: {example: "example"},
    }
    resp = http.delete(req)
    expect(resp.code).to be_in('300'..'399')
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
    resp = @http.delete request
    content = File.read("./nice_http.log")
    expect(content).to match /There was a problem converting to json/
  end

  it "accepts data to be part of the request to send" do
    resp = @http.delete({path: "/api/users/2", data: [33]})
    expect(resp.code).to eq 204
  end

end
