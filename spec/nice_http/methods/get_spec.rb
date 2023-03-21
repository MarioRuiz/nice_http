require "nice_http"

RSpec.describe NiceHttp, "#get" do
  describe "no async" do
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
      resp = @http.get({ path: "/api/users?page=2" })
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
          data: { example: "mock" },
        },
      }
      resp = @http.get(request)
      expect(resp.class).to eq Hash
      expect(resp.code).to eq 100
      expect(resp.message).to eq "mock"
      expect(resp.data.json).to eq ({ example: "mock" })
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

    it "set the cookies when required" do
      server = "https://examplesinatra--tcblues.repl.co/"
      http = NiceHttp.new(server)
      resp = http.get("/setcookie")
      expect(resp.key?(:'set-cookie')).to eq true
      expect(http.cookies["/"].key?("something")).to eq true
    end

    it "detects wrong json when supplying wrong mock_response data" do
      request = {
        path: "/api/users?page=2",
        mock_response: {
          code: 200,
          message: "OK",
          data: { a: "Android\xAE" },
        },
      }
      @http.use_mocks = true
      resp = @http.get request
      content = File.read("./nice_http.log")
      expect(content).to match /There was a problem converting to json/
    end

    it "returns on headers the time_request and time_response" do
      started = Time.now
      resp = @http.get "/api/users?delay=1"
      finished = Time.now
      expect(resp.time_request >= started)
      expect(resp.time_request <= finished)
      expect(resp.time_response >= finished)
    end

    it "downloads into the specified folder" do
      Dir.mkdir("./tmp/") unless Dir.exist?("./tmp")
      File.delete("./tmp/slack-smart-bot.png") if File.exist?("./tmp/slack-smart-bot.png")

      http = NiceHttp.new("https://github.com")
      http.get("/MarioRuiz/slack-smart-bot/blob/master/slack-smart-bot.png", save_data: "./tmp/")
      expect(File.exist?("./tmp/slack-smart-bot.png")).to eq true
    end

    it "downloads into the specified folder finished not on slash" do
      Dir.mkdir("./tmp/") unless Dir.exist?("./tmp")
      File.delete("./tmp/slack-smart-bot.png") if File.exist?("./tmp/slack-smart-bot.png")

      http = NiceHttp.new("https://github.com")
      http.get("/MarioRuiz/slack-smart-bot/blob/master/slack-smart-bot.png", save_data: "./tmp")
      expect(File.exist?("./tmp/slack-smart-bot.png")).to eq true
    end

    it "downloads into the specified path" do
      Dir.mkdir("./tmp/") unless Dir.exist?("./tmp")
      File.delete("./tmp/logo2.png") if File.exist?("./tmp/logo2.png")
      http = NiceHttp.new("https://github.com")
      http.get("/MarioRuiz/slack-smart-bot/blob/master/slack-smart-bot.png", save_data: "./tmp/logo2.png")
      expect(File.exist?("./tmp/logo2.png")).to eq true
    end

    it "downloads a json into the specified path" do
      Dir.mkdir("./tmp/") unless Dir.exist?("./tmp")
      File.delete("./tmp/users.json") if File.exist?("./tmp/users.json")
      resp = @http.get("/api/users?page=2", save_data: "./tmp/users.json")
      expect(resp.code).to eq 200
      expect(resp.message).to eq "OK"
      expect(File.exist?("./tmp/users.json")).to eq true
    end

    it 'doens\'t save if path not reachable' do
      Dir.mkdir("./tmpx/") if Dir.exist?("./tmpx")
      File.delete("./tmp/slack-smart-bot.png") if File.exist?("./tmp/slack-smart-bot.png")
      http = NiceHttp.new("https://github.com")
      http.get("/MarioRuiz/slack-smart-bot/blob/master/slack-smart-bot.png", save_data: "./tmpx/")
      expect(File.exist?("./tmp/slack-smart-bot.png")).to eq false
    end
  end
  describe 'async' do
    before :each do
      NiceHttp.log_files = Hash.new()
      @http = NiceHttp.new(host: 'https://exampleSinatra.tcblues.repl.co', async_wait_seconds: 10, async_header: 'location', 
                           async_completed: 'percComplete', async_resource: 'resourceName', async_status: 'status')
    end
  
    it 'waits until async operation completed when time < than wait time' do
      started = Time.now
      resp = @http.get '/async'
      elapsed = Time.now - started
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      operation_id = resp.data.json(:result).scan(/id:\s(\d+)/).join
      resource_id = operation_id.reverse
      expect(resp.async.status).to eq 'Done'
      expect(resp.async.data.json.percComplete).to eq 100
      expect(resp.async.data.json.status).to eq 'Done'
      expect(resp.async.data.json.resourceName).to eq "/resource/#{resource_id}"
      expect(resp.async.status).to eq 'Done'
      expect(resp.async.resource.data.json.resourceId).to eq resource_id        
      expect(elapsed).to be < 10
      expect(resp.async.seconds).to eq 4
    end

    it "doesn't wait until async operation completed if time > than wait time" do
      @http.async_wait_seconds = 1
      resp = @http.get '/async'
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      operation_id = resp.data.json(:result).scan(/id:\s(\d+)/).join
      resource_id = operation_id.reverse
      expect(resp.async.status).to eq 'Ongoing'
      expect(resp.async.data.json.percComplete).to eq 25
      expect(resp.async.data.json.status).to eq 'Ongoing'
      expect(resp.async.data.json.resourceName).to eq "/resource/#{resource_id}"
      expect(resp.async.status).to eq 'Ongoing'
      expect(resp.async.resource.data.json.resourceId).to eq resource_id        
      expect(resp.async.seconds).to eq 1
    end

    it "doesn't wait for async operation if wait==0" do
      @http.async_wait_seconds = 0
      resp = @http.get '/async'
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      expect(resp.key?(:async)).to eq false
    end

    it "doesn't wait if async_header not found" do
      @http.async_header = 'wrong_header'
      resp = @http.get '/async'
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      expect(resp.key?(:async)).to eq false
    end

    it "waits until max time if async_completed not found" do
      @http.async_completed = 'wrong_completed'
      started = Time.now
      resp = @http.get '/async'
      elapsed = Time.now - started
      operation_id = resp.data.json(:result).scan(/id:\s(\d+)/).join
      resource_id = operation_id.reverse
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      expect(resp.async.data.json.status).to eq 'Done'
      expect(resp.async.data.json.resourceName).to eq "/resource/#{resource_id}"
      expect(resp.async.status).to eq 'Done'
      expect(resp.async.resource.data.json.resourceId).to eq resource_id
      expect(elapsed).to be >= 10
      expect(resp.async.seconds).to eq 10
    end

    it "doesn't return resource if async_resource not found" do
      @http.async_resource = 'wrong_resource'
      started = Time.now
      resp = @http.get '/async'
      elapsed = Time.now - started
      operation_id = resp.data.json(:result).scan(/id:\s(\d+)/).join
      resource_id = operation_id.reverse
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      expect(resp.async.data.json.status).to eq 'Done'
      expect(resp.async.data.json.resourceName).to eq "/resource/#{resource_id}"
      expect(resp.async.status).to eq 'Done'
      expect(resp.async.resource).to eq ({})
      expect(resp.async.seconds).to eq 4
    end

    it "doesn't return async_status if async_status not found" do
      @http.async_status = 'wrong_status'
      started = Time.now
      resp = @http.get '/async'
      elapsed = Time.now - started
      operation_id = resp.data.json(:result).scan(/id:\s(\d+)/).join
      resource_id = operation_id.reverse
      expect(resp.code).to eq 202
      expect(resp.data.json(:result)).to include 'this is an async operation'
      expect(resp.async.data.json.status).to eq 'Done'
      expect(resp.async.data.json.resourceName).to eq "/resource/#{resource_id}"
      expect(resp.async.resource.data.json.resourceId).to eq resource_id
      expect(resp.async.status).to eq ''
      expect(resp.async.seconds).to eq 4
    end

    
  end
end
