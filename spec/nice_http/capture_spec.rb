require "nice_http"
require "English"

RSpec.describe NiceHttp do
  let(:klass) { Class.new NiceHttp }

  describe "capture" do
    it "captures the requests and responses" do
      klass.capture = true
      http = klass.new("http://example.com")
      http.get "/"
      expect(klass.captured.size).to eq 1
      expect(klass.captured.join).to match(/^\s*\w+\s+Request\s*$/i)
      expect(klass.captured.join).to match(/^\s*RESPONSE:/i)
      http2 = klass.new("http://www.google.com")
      http2.get "/"
      expect(klass.captured.join.scan(/^\s*\w+\s+Request\s*$/i).flatten.size).to eq 2
      expect(klass.captured.join.scan(/^\s*Response:/i).flatten.size).to eq 2
    end
    it "doesn't capture the requests and responses if capture set to false" do
      http = klass.new("http://example.com")
      http.get "/"
      expect(klass.captured.size).to eq 0
      klass.capture = true
      http = klass.new("http://example.com")
      http.get "/"
      expect(klass.captured.size).to eq 1
      expect(klass.captured.join).to match(/^\s*\w+\s+Request\s*$/i)
      expect(klass.captured.join).to match(/^\s*RESPONSE:/i)
      klass.capture = false
      http2 = klass.new("http://www.google.com")
      http2.get "/"
      expect(klass.captured.join.scan(/^\s*\w+\s+Request\s*$/i).flatten.size).to eq 1
      expect(klass.captured.join.scan(/^\s*Response:/i).flatten.size).to eq 1
    end
  end
end
