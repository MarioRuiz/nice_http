require "nice_http"

RSpec.describe NiceHttp, "#put" do
  before do
    NiceHttp.log_files = Hash.new()
    @http = NiceHttp.new("https://reqres.in")
  end

  it "accepts hash including keys :data and :path" do
    resp = @http.put({
      path: "/api/users/2",
      data: {name: "morpheus", job: "HR leader"},
    })
    expect(resp.code).to eq 200
    expect(resp.data.json(:job)).to eq "HR leader"
  end

  it "accepts parameters as array of path, data, headers" do
    resp = @http.put("/api/users/2", "{ 'name': 'morpheus', 'job': 'leader2' }", {})
    expect(resp.code).to eq 200
  end

  it "returns error in case no path" do
    resp = @http.put({data: {name: "morpheus", job: "leader"}})
    expect(resp.class).to eq Hash
    expect(resp.fatal_error).to match /no[\w\s]+path/i
    expect(resp.code).to eq nil
    expect(resp.message).to eq nil
    expect(resp.data).to eq nil
  end

  it "accepts data_examples array in case no data supplied" do
    resp = @http.put({
      path: "/api/users/2",
      data_examples: [{name: "doopy", job: "loope"}],
    })
    expect(resp.code).to eq 200
    expect(resp.data.json(:name)).to eq "doopy"
  end

  it "returns the mock response if specified" do
    @http.use_mocks = true
    request = {
      path: "/api/users/2",
      data: {name: "morpheus", job: "leader"},
      mock_response: {
        code: 100,
        message: "mock",
        data: {example: "mock"},
      },
    }
    resp = @http.put(request)
    expect(resp.class).to eq Hash
    expect(resp.code).to eq 100
    expect(resp.message).to eq "mock"
    expect(resp.data.json).to eq ({example: "mock"})
  end

  it "changes :data when supplied :values_for" do
    request = {
      path: "/api/users/2",
      data: {name: "morpheus", job: "leader"},
    }

    request.values_for = {name: "peter"}
    resp = @http.put(request)
    expect(resp.code).to eq 200
    expect(resp.data.json(:name)).to eq "peter"
  end

  it "changes :data when supplied nested keys on :values_for" do
    request = {
      path: "/api/users/2",
      data: {name: "morpheus", job: {position:"leader"}},
    }

    request.values_for = {'job.position': "worker"}
    resp = @http.put(request)
    expect(resp.code).to eq 200
    expect(resp.data.json(:position)).to eq "worker"
  end


  it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
    server = ENV['HOST_EXAMPLE_SINATRA']
    http = NiceHttp.new(server)
    http.auto_redirect = false
    req = {
      path: "/exampleRedirect",
      data: {example: "example"},
    }
    resp = http.put(req)
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
    resp = @http.put request
    content = File.read("./nice_http.log")
    expect(content).to match /There was a problem converting to json/
  end

  it 'accepts a json array on first level request' do
    request = {
      path: "/api/users",
      data: [20, 30, 40]
    }
    resp = @http.post(request)
    expect(resp.code).to eq 201
    expect(resp.data.json).to eq [20, 30, 40]
  end

  it "set the cookies when required" do
    server = ENV['HOST_EXAMPLE_SINATRA']
    http = NiceHttp.new(server)
    resp = http.put('/setcookie')
    expect(resp.key?(:'set-cookie')).to eq true
    expect(http.cookies["/"].key?("something")).to eq true
  end


  #todo: add tests for headers, encoding

end
