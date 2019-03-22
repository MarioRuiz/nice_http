require "nice_http"

RSpec.describe NiceHttp, "#post" do
  before do
    @http = NiceHttp.new("https://www.reqres.in")
  end

  it "accepts hash including keys :data and :path" do
    resp = @http.post({
      path: "/api/users",
      data: {name: "morpheus", job: "leader"},
    })
    expect(resp.code).to eq 201
  end

  it "accepts parameters as array of path, data, headers" do
    resp = @http.post("/api/users", "{ 'name': 'morpheus', 'job': 'leader' }", {})
    expect(resp.code).to eq 201
  end

  it "returns error in case no path" do
    resp = @http.post({data: {name: "morpheus", job: "leader"}})
    expect(resp.class).to eq Hash
    expect(resp.fatal_error).to match /no[\w\s]+path/i
    expect(resp.code).to eq nil
    expect(resp.message).to eq nil
    expect(resp.data).to eq nil
  end

  it "accepts data_examples array in case no data supplied" do
    resp = @http.post({
      path: "/api/users",
      data_examples: [{name: "doopy", job: "loope"}],
    })
    expect(resp.code).to eq 201
    expect(resp.data.json(:name)).to eq "doopy"
  end

  it "returns the mock response if specified" do
    @http.use_mocks = true
    request = {
      path: "/api/users",
      data: {name: "morpheus", job: "leader"},
      mock_response: {
        code: 100,
        message: "mock",
        data: {example: "mock"},
      },
    }
    resp = @http.post(request)
    expect(resp.class).to eq Hash
    expect(resp.code).to eq 100
    expect(resp.message).to eq "mock"
    expect(resp.data.json).to eq ({example: "mock"})
  end

  it "changes :data when supplied :values_for" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: {name: "morpheus", job: "leader", lab: {doom: "one", beep: true}, products: [{one: 1, two: 2}, {one: 11, two: 22}]},
    }
    request.values_for = {name: "peter", doom: "two", one: "uno"}
    resp = @http.post(request)
    expect(resp.code).to eq 201
    expect(resp.data.json(:name)).to eq "peter"
    expect(resp.data.json(:doom)).to eq "two"
    expect(resp.data.json(:one)).to eq (["uno", "uno"])
  end

  it "redirects when auto_redirect is true and http code is 30x" do
    server = "http://examplesinatra--tcblues.repl.co/"
    http = NiceHttp.new(server)
    http.auto_redirect = true
    req = {
      path: "/exampleRedirect",
      data: {example: "example"},
    }
    resp = http.post(req)
    expect(resp.code).to eq 200
    expect(resp.message).to eq "OK"
  end

  it 'doesn\'t redirect when auto_redirect is false and http code is 30x' do
    server = "http://examplesinatra--tcblues.repl.co/"
    http = NiceHttp.new(server)
    http.auto_redirect = false
    req = {
      path: "/exampleRedirect",
      data: {example: "example"},
    }
    resp = http.post(req)
    expect(resp.code).to eq 303
  end

  it "accepts all kind of Content-Type" do
    # as symbol
    req = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: '{"name": "morpheus","job": "leader"}',
    }

    # as symbol
    resp = @http.post req
    expect(NiceHttp.last_request).to match /Content-Type:application\/json/

    req.headers = {"content-type": "application/json"}
    resp = @http.post req
    expect(NiceHttp.last_request).to match /Content-Type:application\/json/

    # as string
    req.headers = {"content-type" => "application/json"}
    resp = @http.post req
    expect(NiceHttp.last_request).to match /Content-Type:application\/json/

    # as string
    req.headers = {"Content-Type" => "application/json"}
    resp = @http.post req
    expect(NiceHttp.last_request).to match /Content-Type:application\/json/
  end

  it "implements json data by default if no content type supplied and a hash for data" do
    req = {
      path: "/api/users",
      data: {name: "morpheus", job: "leader"},
    }

    # not supplied content type by default
    resp = @http.post req
    expect(NiceHttp.last_request).to match /Content-Type:application\/json/
  end

  it "changes data to empty string if data is nil" do
    req = {
      path: "/api/users",
      data: nil,
    }
    resp = @http.post req
    expect(NiceHttp.last_request).to match /data:\s*$/
  end

  it "accepts values as an alias for values_for" do
    request = {
      path: "/api/users",
      data: {name: "morpheus", job: "leader"},
    }

    request[:values] = {name: "peter"}
    resp = @http.post(request)
    expect(resp.code).to eq 201
    expect(resp.data.json(:name)).to eq "peter"
  end

  it "change xml value when supplied values_for" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "text/xml"},
      data: "<name>morpheus</name><job>leader</job>",
    }

    request.values_for = {name: "peter"}
    resp = @http.post(request)
    expect(NiceHttp.last_request).to match /name>peter/
  end

  it "changes json string values when values_for supplied and json is a string" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: '{"name": "morpheus","job": "leader"}',
    }
    request.values_for = {name: "peter"}
    resp = @http.post(request)
    expect(NiceHttp.last_request).to match /"name": "peter"/
  end

  it "accepts an array as data" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: [
        {name: "morpheus", job: "leader"},
        {name: "peter", job: "vicepresident"},
      ],
    }
    resp = @http.post(request)
    expect(resp.code).to eq 201
    expect(resp.data.json(:name)).to eq ["morpheus", "peter"]
  end

  it "changes all values on array request when values_for" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: [
        {name: "morpheus", job: "leader"},
        {name: "peter", job: "vicepresident"},
      ],
    }
    request.values_for = {job: "dev"}
    resp = @http.post(request)
    expect(resp.code).to eq 201
    expect(resp.data.json(:job)).to eq ["dev", "dev"]
  end

  it "shows wrong format on request when not array of hashes" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: [
        {name: "morpheus", job: "leader"},
        {name: "peter", job: "vicepresident"},
        100,
      ],
    }
    resp = @http.post(request)
    content = File.read("./nice_http.log")
    expect(content).to match /Wrong format on request/
  end

  it "changes all values on array request when values_for is array of hashes" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: [
        {name: "morpheus", job: "leader"},
        {name: "peter", job: "vicepresident"},
      ],
    }
    request.values_for = [{job: "dev"}, {job: "cleaner"}]
    resp = @http.post(request)

    expect(resp.code).to eq 201
    expect(resp.data.json(:job)).to eq ["dev", "cleaner"]
  end

  it "shows wrong format on request when not array of hashes supplied for values_for" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: [
        {name: "morpheus", job: "leader"},
        {name: "peter", job: "vicepresident"},
      ],
    }
    request.values_for = "job"
    resp = @http.post(request)
    content = File.read("./nice_http.log")
    expect(content).to match /Wrong format on request/
  end

  it "shows wrong format on request when data is not a string, array or hash" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "application/json"},
      data: 33,
    }
    resp = @http.post(request)
    content = File.read("./nice_http.log")
    expect(content).to match /Wrong format on request/
  end

  it "shows wrong data format for given values_for" do
    request = {
      path: "/api/users",
      headers: {"Content-Type": "text"},
      data: "example",
    }
    request.values_for = {dog: 1}
    resp = @http.post(request)
    content = File.read("./nice_http.log")
    expect(content).to match /values_for key given without a valid content-type or data for request/
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
    resp = @http.post request
    content = File.read("./nice_http.log")
    expect(content).to match /There was a problem converting to json/
  end

  it "doesn't log request if the same as before" do
    request = {
      path: "/api/register",
      data: {
        email: "test@example.com",
        password: "example",
      },
    }
    resp = @http.post request
    resp = @http.post request
    resp = @http.post request
    content = File.read("./nice_http.log")
    expect(content).to match /Same headers and data as in the previous request/
  end

  it "doesn't log response if the same as before" do
    request = {
      path: "/api/register",
      data: {
        email: "test@example.com",
        password: "example",
      },
    }
    resp = @http.post request
    resp = @http.post request
    resp = @http.post request
    content = File.read("./nice_http.log")
    expect(content).to match /Same as the last response/
  end

  it "logs request and response when debug set to true" do
    File.delete("./nice_http_tmp.log") if File.exist?("./nice_http_tmp.log")
    @http = NiceHttp.new({host: "https://www.reqres.in", debug: true, log: "./nice_http_tmp.log"})

    request = {
      path: "/api/register",
      data: {
        email: "test@example.com",
        password: "example",
      },
    }
    resp = @http.post request
    resp = @http.post request
    resp = @http.post request
    content = File.read("./nice_http_tmp.log")
    expect(content).not_to match /Same as the last response/
    expect(content).not_to match /Same as the last request/
  end

  #todo: add tests encoding and cookies

end
