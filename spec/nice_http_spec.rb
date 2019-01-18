require './lib/nice_http'
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

  describe 'class defaults' do
    specify 'port is 80' do
      expect(klass.port).to eq 80
    end
    specify 'I can set/get them with accessors' do
      expect { klass.port = 8888 }.to change { klass.port }.to(8888)
    end
    specify 'I can set many at once with a hash' do
      expect { klass.defaults = { port: 8888 } }.to change { klass.port }.to(8888)
    end
    specify 'setting many at once doesn\'t override unprovided values' do
      expect { klass.defaults = { host: 'http://whatevz.com' } }
        .to_not change { klass.port }
    end
  end
end
