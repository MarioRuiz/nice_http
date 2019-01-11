require 'nice_http'

RSpec.describe NiceHttp do
  before { NiceHttp.reset! }

  describe 'port' do
    it 'uses the class port by default' do
      NiceHttp.port = 123
      expect(NiceHttp.new.port).to eq 123
    end
    specify 'even if its class is a subclass of NiceHttp' do
      klass = Class.new(NiceHttp) { self.port = 9393 }
      expect(klass.new.port).to eq 9393
    end
    it 'uses the URI default when provided a URI' do
      NiceHttp.port = 123
      expect(NiceHttp.new('https://example.com').port).to eq 443
    end
    it 'can be provided an explicit port' do
      NiceHttp.port = 123
      expect(NiceHttp.new(port: 456).port).to eq 456
    end
  end

  describe 'class defaults' do
    specify 'port is 80' do
      expect(NiceHttp.port).to eq 80
    end
    specify 'I can set/get them with accessors' do
      expect { NiceHttp.port = 123 }
        .to change { NiceHttp.port }.to(123)
    end
    specify 'I can set many at once with a hash' do
      expect { NiceHttp.defaults = { port: 123 } }
        .to change { NiceHttp.port }.to(123)
    end
    specify 'setting many at once doesn\'t override unprovided values' do
      expect { NiceHttp.defaults = { host: 'http://whatevz.com' } }
        .to_not change { NiceHttp.port }
    end
    specify 'subclasses inherit the defaults' do
      expect(Class.new(NiceHttp).port).to eq 80
    end
  end
end
