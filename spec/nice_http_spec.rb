require 'nice_http'
require 'English'

RSpec.describe NiceHttp do
  let(:klass) { Class.new NiceHttp }

  describe 'port' do
    it 'uses the class port by default' do
      klass.host = 'localhost'
      klass.port = 8888
      expect(klass.new.port).to eq 8888
    end
    it 'uses the URI default when provided a URI and the URI has one' do
      klass.port = 8888
      expect(klass.new('https://example.com').port).to eq 443
      expect(klass.new('lol://localhost').port).to eq 8888
    end
    it 'can be provided an explicit port' do
      klass.port = 8888
      klass.host = 'localhost'
      expect(klass.new(port: 443).port).to eq 443
    end
    it 'raises an error when it can\'t figure out the port' do
      klass.port = nil
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :port
      expect(err.message).to match /wrong port/i
    end
  end

  describe 'host' do
    it 'uses the class host by default' do
      klass.host = 'localhost'
      klass.port = 8888
      expect(klass.new.host).to eq 'localhost'
    end
    it 'uses the URI default when provided a URI and the URI has one' do
      klass.port = 8888
      klass.host = 'localhost'
      expect(klass.new('https://example.com').host).to eq 'example.com'
    end
    it 'can be provided an explicit host' do
      klass.port = 443
      klass.host = 'localhost'
      expect(klass.new(host: 'example.com').host).to eq 'example.com'
    end
    it 'raises an error when it can\'t figure out the host' do
      klass.host = nil
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :host
      expect(err.message).to match /wrong host/i
    end
  end

  describe 'ssl' do
    it 'uses the class ssl by default' do
      klass.ssl = true
      klass.host = "example.com"
      klass.port = 443
      expect(klass.new.ssl).to eq true
    end
    it 'uses the URI default when provided a URI and the URI has one' do
      klass.port = 8888
      klass.host = 'localhost'
      klass.ssl = false
      expect(klass.new('https://example.com').ssl).to eq true
    end
    it 'can be provided an explicit ssl' do
      klass.port = 443
      klass.host = 'localhost'
      klass.ssl = false
      expect(klass.new(host: 'example.com', ssl: true).ssl).to eq true
    end
    it 'raises an error when it can\'t figure out the ssl' do
      klass.ssl = nil
      klass.host = 'localhost'
      klass.port = 8888
      klass.new rescue err = $ERROR_INFO
      expect(err.attribute).to eq :ssl
      expect(err.message).to match /wrong ssl/i
    end
  end


  describe 'class defaults' do
    specify 'port is 80' do
      expect(klass.port).to eq 80
    end
    specify 'host is nil' do
      expect(klass.host).to eq nil
    end
    specify 'ssl is false' do
      expect(klass.ssl).to eq false
    end
    specify 'I can set/get them with accessors' do
      expect { klass.port = 8888 }.to change { klass.port }.to(8888)
      expect { klass.host = 'localhost' }.to change { klass.host }.to('localhost')
      expect { klass.ssl = true }.to change { klass.ssl }.to(true)
    end
    specify 'I can set many at once with a hash' do
      expect { klass.defaults = { port: 8888 } }.to change { klass.port }.to(8888)
      expect { klass.defaults = { host: 'localhost' } }.to change { klass.host }.to('localhost')
      expect { klass.defaults = { ssl: true } }.to change { klass.ssl }.to(true)
    end
    specify 'setting many at once doesn\'t override unprovided values' do
      expect { klass.defaults = { host: 'http://whatevz.com' } }
        .to_not change { klass.port }
    end
  end

  describe 'connections array' do
    it 'returns the number of active connections' do
      klass.host = 'https://www.example.com'
      http1 = klass.new
      http2 = klass.new
      expect(klass.active).to eq 2
      http1.close
      expect(klass.active).to eq 1
    end
    it 'returns the connections on connections array' do
      klass.host = 'https://www.example.com'
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

end
