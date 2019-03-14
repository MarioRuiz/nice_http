require "nice_http"
require "English"

RSpec.describe NiceHttp do
  let(:klass) { Class.new NiceHttp }

  describe "reset!" do
    it "resets to original default values" do
      klass.host = "example.com"
      klass.port = 433
      klass.ssl = true
      klass.headers = { uno: "one" }
      klass.debug = true
      klass.log = :screen
      klass.proxy_host = "example.com"
      klass.proxy_port = 8080
      klass.last_request = {}
      klass.last_response = {}
      klass.request_id = "3344"
      klass.use_mocks = true
      klass.connections = [1, 1]
      klass.active = 1
      klass.auto_redirect = false
      klass.values_for = { one: 1 }

      klass.reset!

      expect(klass.host).to eq nil
      expect(klass.port).to eq 80
      expect(klass.ssl).to eq false
      expect(klass.headers).to eq ({})
      expect(klass.debug).to eq false
      expect(klass.log).to eq :fix_file
      expect(klass.proxy_host).to eq nil
      expect(klass.proxy_port).to eq nil
      expect(klass.last_request).to eq nil
      expect(klass.last_response).to eq nil
      expect(klass.request_id).to eq ""
      expect(klass.use_mocks).to eq false
      expect(klass.connections).to eq []
      expect(klass.active).to eq 0
      expect(klass.auto_redirect).to eq true
      expect(klass.values_for).to eq ({})
    end
  end

  describe "port" do
    it "uses the class port by default" do
      klass.host = "localhost"
      klass.port = 8888
      expect(klass.new.port).to eq 8888
    end
    it "uses the URI default when provided a URI and the URI has one" do
      klass.port = 8888
      expect(klass.new("https://example.com").port).to eq 443
      expect(klass.new("lol://localhost").port).to eq 8888
    end
    it "can be provided an explicit port" do
      klass.port = 8888
      klass.host = "localhost"
      expect(klass.new(port: 443).port).to eq 443
    end
    it 'raises an error when it can\'t figure out the port' do
      klass.port = nil
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :port
      expect(err.message).to match /wrong port/i
    end
  end

  describe "host" do
    it "uses the class host by default" do
      klass.host = "localhost"
      klass.port = 8888
      expect(klass.new.host).to eq "localhost"
    end
    it "uses the URI default when provided a URI and the URI has one" do
      klass.port = 8888
      klass.host = "localhost"
      expect(klass.new("https://example.com").host).to eq "example.com"
    end
    it "can be provided an explicit host" do
      klass.port = 443
      klass.host = "localhost"
      expect(klass.new(host: "example.com").host).to eq "example.com"
    end
    it 'raises an error when it can\'t figure out the host' do
      klass.host = nil
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :host
      expect(err.message).to match /wrong host/i
    end
  end

  describe "ssl" do
    it "uses the class ssl by default" do
      klass.ssl = true
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.ssl).to eq true
    end
    it "uses the URI default when provided a URI and the URI has one" do
      klass.port = 8888
      klass.host = "localhost"
      klass.ssl = false
      expect(klass.new("https://example.com").ssl).to eq true
    end
    it "can be provided an explicit ssl" do
      klass.port = 443
      klass.host = "localhost"
      klass.ssl = false
      expect(klass.new(host: "example.com", ssl: true).ssl).to eq true
    end
    it 'raises an error when it can\'t figure out the ssl' do
      klass.ssl = nil
      klass.host = "localhost"
      klass.port = 8888
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :ssl
      expect(err.message).to match /wrong ssl/i
    end
  end

  describe "debug" do
    it "uses the class debug by default" do
      klass.debug = true
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.debug).to eq true
    end
    it "can be provided an explicit debug" do
      klass.port = 443
      klass.host = "localhost"
      klass.debug = false
      expect(klass.new(debug: true).debug).to eq true
    end
    it 'raises an error when it can\'t figure out the debug' do
      klass.debug = nil
      klass.host = "localhost"
      klass.port = 8888
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :debug
      expect(err.message).to match /wrong debug/i
    end
  end
  describe "auto_redirect" do
    it "uses the class auto_redirect by default" do
      klass.auto_redirect = false
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.auto_redirect).to eq false
    end
    it "can be provided an explicit auto_redirect" do
      klass.port = 443
      klass.host = "localhost"
      klass.auto_redirect = true
      expect(klass.new(auto_redirect: false).debug).to eq false
    end
    it 'raises an error when it can\'t figure out the auto_redirect' do
      klass.auto_redirect = nil
      klass.host = "example.com"
      klass.port = 443
      klass.new rescue err = $ERROR_INFO
      expect(err.class).to eq NiceHttp::InfoMissing
      expect(err.attribute).to eq :auto_redirect
      expect(err.message).to match /wrong auto_redirect/i
    end
  end

  describe "use_mocks" do
    it "uses the class use_mocks by default" do
      klass.use_mocks = true
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.use_mocks).to eq true
    end
    it "can be provided an explicit use_mocks" do
      klass.port = 443
      klass.host = "localhost"
      klass.use_mocks = false
      expect(klass.new(use_mocks: true).use_mocks).to eq true
    end
    it 'raises an error when it can\'t figure out the auto_redirect' do
      klass.use_mocks = nil
      klass.host = "example.com"
      klass.port = 443
      klass.new rescue err = $ERROR_INFO
      expect(err.class).to eq NiceHttp::InfoMissing
      expect(err.attribute).to eq :use_mocks
      expect(err.message).to match /wrong use_mocks/i
    end
  end

  describe "headers" do
    it "uses the class headers by default" do
      klass.headers = { example: "test" }
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.headers).to eq klass.headers
    end
    it "can be provided an explicit headers" do
      klass.port = 443
      klass.host = "localhost"
      klass.headers = {}
      expect(klass.new(headers: { example: "test" }).headers).to eq ({ example: "test" })
    end
    it 'raises an error when it can\'t figure out the headers' do
      klass.headers = nil
      klass.host = "example.com"
      klass.port = 443
      klass.new rescue err = $ERROR_INFO
      expect(err.class).to eq NiceHttp::InfoMissing
      expect(err.attribute).to eq :headers
      expect(err.message).to match /wrong headers/i
    end
  end

  describe "values_for" do
    it "uses the class values_for by default" do
      klass.values_for = { example: "test" }
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.values_for).to eq klass.values_for
    end
    it "can be provided an explicit values_for" do
      klass.port = 443
      klass.host = "localhost"
      klass.values_for = {}
      expect(klass.new(values_for: { example: "test" }).values_for).to eq ({ example: "test" })
    end
    it 'raises an error when it can\'t figure out the values_for' do
      klass.values_for = nil
      klass.host = "example.com"
      klass.port = 443
      klass.new rescue err = $ERROR_INFO
      expect(err.class).to eq NiceHttp::InfoMissing
      expect(err.attribute).to eq :values_for
      expect(err.message).to match /wrong values_for/i
    end

    it "changes :data when supplied :values_for on class defaults" do
      klass.values_for = { name: "peter" }
      klass.host = "https://www.reqres.in"
      http = klass.new
      request = {
        path: "/api/users",
        data: { name: "morpheus", job: "leader" },
      }
      resp = http.post(request)
      expect(resp.code).to eq 201
      expect(resp.data.json(:name)).to eq "peter"
    end

    it "changes :data when supplied :values_for on new class instance" do
      klass.values_for = {}
      klass.host = "https://www.reqres.in"
      http = klass.new(values_for: { name: "juan" })
      request = {
        path: "/api/users",
        data: { name: "morpheus", job: "leader" },
      }
      resp = http.post(request)
      expect(resp.code).to eq 201
      expect(resp.data.json(:name)).to eq "juan"
    end

    it "changes :data when supplied :values_for on request instead of value on class" do
      klass.values_for = {}
      klass.host = "https://www.reqres.in"
      http = klass.new(values_for: { name: "juan" })
      request = {
        path: "/api/users",
        data: { name: "morpheus", job: "leader" },
      }
      request.values_for = { name: "John" }
      resp = http.post(request)
      expect(resp.code).to eq 201
      expect(resp.data.json(:name)).to eq "John"
      expect(klass.values_for).to eq ({})
    end
  end

  describe "log" do
    it "uses the class log by default" do
      klass.log = :screen
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.log).to eq :screen
    end
    it "can be provided an explicit log" do
      klass.port = 443
      klass.host = "localhost"
      klass.log = :screen
      expect(klass.new(log: :file).log).to eq (:file)
    end
    it 'raises an error when it can\'t figure out the log' do
      klass.log = nil
      klass.host = "example.com"
      klass.port = 443
      klass.new rescue err = $ERROR_INFO
      expect(err.class).to eq NiceHttp::InfoMissing
      expect(err.attribute).to eq :log
      expect(err.message).to match /wrong log/i
    end
  end

  describe "class defaults" do
    specify "port is 80" do
      expect(klass.port).to eq 80
    end
    specify "host is nil" do
      expect(klass.host).to eq nil
    end
    specify "ssl is false" do
      expect(klass.ssl).to eq false
    end
    specify "debug is false" do
      expect(klass.debug).to eq false
    end
    specify "auto_redirect is true" do
      expect(klass.auto_redirect).to eq true
    end
    specify "use_mocks is false" do
      expect(klass.use_mocks).to eq false
    end
    specify "headers is empty hash" do
      expect(klass.headers).to eq ({})
    end
    specify "headers is empty hash" do
      expect(klass.values_for).to eq ({})
    end
    specify "log is :fix_file" do
      expect(klass.log).to eq (:fix_file)
    end
    specify "I can set/get them with accessors" do
      expect { klass.port = 8888 }.to change { klass.port }.to(8888)
      expect { klass.host = "localhost" }.to change { klass.host }.to("localhost")
      expect { klass.ssl = true }.to change { klass.ssl }.to(true)
      expect { klass.debug = true }.to change { klass.debug }.to(true)
      expect { klass.auto_redirect = false }.to change { klass.auto_redirect }.to(false)
      expect { klass.use_mocks = true }.to change { klass.use_mocks }.to(true)
      expect { klass.headers = { example: "test" } }.to change { klass.headers }.to({ example: "test" })
      expect { klass.values_for = { example: "test" } }.to change { klass.values_for }.to({ example: "test" })
      expect { klass.log = :screen }.to change { klass.log }.to(:screen)
    end
    specify "I can set many at once with a hash" do
      expect { klass.defaults = { port: 8888 } }.to change { klass.port }.to(8888)
      expect { klass.defaults = { host: "localhost" } }.to change { klass.host }.to("localhost")
      expect { klass.defaults = { ssl: true } }.to change { klass.ssl }.to(true)
      expect { klass.defaults = { debug: true } }.to change { klass.debug }.to(true)
      expect { klass.defaults = { auto_redirect: false } }.to change { klass.auto_redirect }.to(false)
      expect { klass.defaults = { use_mocks: true } }.to change { klass.use_mocks }.to(true)
      expect { klass.defaults = { headers: { example: "test" } } }.to change { klass.headers }.to({ example: "test" })
      expect { klass.defaults = { values_for: { example: "test" } } }.to change { klass.values_for }.to({ example: "test" })
      expect { klass.defaults = { log: :screen } }.to change { klass.log }.to(:screen)
    end
    specify 'setting many at once doesn\'t override unprovided values' do
      expect { klass.defaults = { host: "http://whatevz.com" } }.to_not change { klass.port }
    end
  end

  describe "connections array" do
    it "returns the number of active connections" do
      klass.host = "https://www.example.com"
      http1 = klass.new
      http2 = klass.new
      expect(klass.active).to eq 2
      http1.close
      expect(klass.active).to eq 1
    end

    it "returns the connections on connections array" do
      klass.host = "https://www.example.com"
      http1 = klass.new
      http2 = klass.new
      expect(klass.connections.size).to eq 2
      expect(klass.connections[0]).to eq http1
      expect(klass.connections[1]).to eq http2
      http1.close
      expect(klass.connections.size).to eq 1
      expect(klass.connections[0]).to eq http2
    end
  end

  describe "log files" do
    it "logs to file specified" do
      klass.log = "./example.log"
      http = klass.new("https://example.com")
      http.logger.info "testing"
      content = File.read("./example.log")
      expect(content).to match /testing/
    end

    it "logs to file specified even when two connections pointing to same file" do
      klass.host = "https://example.com"
      http1 = klass.new({log: "./example.log"})
      http1.logger.info "testing"
      content = File.read("./example.log")
      expect(content).to match /testing/

      http2 = klass.new({log: http1.log})
      http2.logger.info "example2"
      content = File.read("./example.log")
      expect(content).to match /example2/


      http1.logger.info "testing2"
      content = File.read("./example.log")
      expect(content).to match /testing2/

      http1.close

      http2.logger.info "example3"
      content = File.read("./example.log")
      expect(content).to match /example3/

    end

    it "logs to nice_http.log when :fix_file specified" do
      klass.log = :fix_file
      http = klass.new("https://example.com")
      http.logger.info "testing"
      content = File.read("./nice_http.log")
      expect(content).to match /testing/
    end

    it "logs to file running.log when :file_run specified" do
      klass.log = :file_run
      http = klass.new("https://example.com")
      http.logger.info "testing XaXDo"
      content = File.read("./spec/nice_http/nice_http_spec.rb.log")
      expect(content).to match /testing XaXDo/
    end

    it "logs to nice_http_YY-mm-dd-HHMMSS.log when :file specified" do
      Dir.glob("./nice_http_*.log").each { |file| File.delete(file) }
      klass.log = :file
      http = klass.new("https://example.com")
      http.logger.info "testing"
      files = Dir["./nice_http_*.log"]
      expect(files.size).to eq 1

      content = File.read(files[0])
      expect(content).to match /testing/
    end

    it "doesn't create any log file when :no specified" do
      Dir.glob("./*.log").each { |file| File.delete(file) }
      klass.log = :no
      http = klass.new("https://example.com")
      http.logger.info "TESTING NO LOGS"
      files = Dir["./*.log"]
      expect(files.size).to eq 0
    end

    it "raises error if log file not possible to be created" do
      Dir.glob("./*.log").each { |file| File.delete(file) }
      klass.log = "./"
      klass.new("https://example.com") rescue err = $ERROR_INFO
      expect(err.class).to eq NiceHttp::InfoMissing
      expect(err.attribute).to eq :log
      expect(err.message).to match /wrong log/i
    end

    it "doesn't create any log file when exception on creating" do
      klass.log = "./"
      klass.new("https://example.com") rescue err = $ERROR_INFO
      files = Dir["./*.log"]
      expect(files.size).to eq 0
    end

    it "cannot close a connection that is already closed" do
      http = klass.new("https://example.com")
      http.close
      http.close
      content = File.read("./nice_http.log")
      expect(content).to match /It was not possible to close the HTTP connection, already closed/
    end
  end

  describe "proxys" do
    it "starts proxy supplied host and port" do
      klass.proxy_host = "example.com"
      klass.proxy_port = 80
      http = klass.new("http://example.com")
      resp = http.get "/"
      expect(resp.code).to eq 200

      http2 = klass.new("http://www.google.com")
      resp = http2.get "/"
      expect(resp.code).to eq 404
    end
  end

  describe "prepaths" do
    it "adds the prepath if supplied" do
      http = klass.new("https://reqres.in/api")
      resp = http.get "/users?page=2"
      expect(resp.code).to eq 200
    end
  end
end
