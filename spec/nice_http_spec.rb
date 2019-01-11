require 'nice_http'

RSpec.describe NiceHttp do
  let(:klass) { Class.new NiceHttp }

  describe 'port' do
    it 'uses the class port by default' do
      klass.port = 123
      expect(klass.new.port).to eq 123
    end
    it 'uses the URI default when provided a URI and the URI has one' do
      klass.port = 123
      expect(klass.new('https://example.com').port).to eq 443
      expect(klass.new('lol://example.com').port).to eq 123
    end
    it 'can be provided an explicit port' do
      klass.port = 123
      expect(klass.new(port: 456).port).to eq 456
    end
  end

  describe 'class defaults' do
    specify 'port is 80' do
      expect(klass.port).to eq 80
    end
    specify 'I can set/get them with accessors' do
      expect { klass.port = 123 }.to change { klass.port }.to(123)
    end
    specify 'I can set many at once with a hash' do
      expect { klass.defaults = { port: 123 } }.to change { klass.port }.to(123)
    end
    specify 'setting many at once doesn\'t override unprovided values' do
      expect { klass.defaults = { host: 'http://whatevz.com' } }
        .to_not change { klass.port }
    end
  end
end
