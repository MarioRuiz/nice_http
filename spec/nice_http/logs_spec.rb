
require "nice_http"
require "English"

RSpec.describe NiceHttp, "#logs" do
  let(:klass) { Class.new NiceHttp }


  describe "log files" do
    it "logs to file specified" do
      klass.log = "./example.log"
      http = klass.new("https://example.com")
      http.logger.info "testing"
      content = File.read("./example.log")
      expect(content).to match /testing/
    end

    it "logs to file and log_path specified" do
      file = './tmp/example/example.log'
      File.delete(file) if File.exist?(file)
      klass.log_path = './tmp/example/'
      klass.log = "./example.log"
      http = klass.new("https://example.com")
      http.logger.info "testingxl"
      content = File.read(file)
      expect(content).to match /testingxl/
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

    it "logs to nice_http.log when :fix_file and file_path specified" do
      file = './tmp/example/nice_http.log'
      File.delete(file) if File.exist?(file)
      klass.log_path = './tmp/example/'
      klass.log = :fix_file
      http = klass.new("https://example.com")
      http.logger.info "testingxd"
      content = File.read(file)
      expect(content).to match /testingxd/
    end

    it "logs to file running.log when :file_run specified" do
      klass.log = :file_run
      http = klass.new("https://example.com")
      http.logger.info "testing XaXDo"
      content = File.read("./spec/nice_http/logs_spec.rb.log")
      expect(content).to match /testing XaXDo/
    end

    it "logs to file running.log when :file_run specified and file_path specified" do
      file = './tmp/example/spec/nice_http/logs_spec.rb.log'
      File.delete(file) if File.exist?(file)
      klass.log = :file_run
      klass.log_path = './tmp/example/'
      http = klass.new("https://example.com")
      http.logger.info "testing XaXDop"
      content = File.read(file)
      expect(content).to match /testing XaXDop/
    end

    it "logs to nice_http_YY-mm-dd-HHMMSS.log when :file specified" do
      Dir.glob("./*.log").each { |file| File.delete(file) }
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

    it 'logs data to relative path starting by name' do
      Dir.glob("./spec/nice_http/*.log").each { |file| File.delete(file) }
      klass.log = 'nice_http_example.log'
      klass.new("https://example.com")
      expect(File.exist?('./spec/nice_http/nice_http_example.log')).to eq true
    end

    it 'logs data to relative path starting by slash' do
      Dir.glob("./spec/nice_http/*.log").each { |file| File.delete(file) }
      klass.log = '/nice_http_example.log'
      klass.new("https://example.com")
      expect(File.exist?('./spec/nice_http/nice_http_example.log')).to eq true
    end

    it "cannot close a connection that is already closed" do
      http = klass.new("https://example.com")
      http.close
      http.close
      content = File.read("./nice_http.log")
      expect(content).to match /It was not possible to close the HTTP connection, already closed/
    end
  end
end