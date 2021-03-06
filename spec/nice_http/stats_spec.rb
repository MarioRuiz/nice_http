require "nice_http"
require "English"

RSpec.describe NiceHttp do
  let(:klass) { Class.new NiceHttp }

  describe "stats" do
    describe "all" do
      it "counts correctly the number of requests" do
        klass.create_stats = true
        expect(klass.stats[:all][:num_requests]).to eq 0
        http = klass.new("http://example.com")
        resp = http.get "/"
        expect(klass.stats[:all][:num_requests]).to eq 1
        http2 = klass.new("http://www.google.com")
        resp = http2.get "/"
        expect(klass.stats[:all][:num_requests]).to eq 2
      end
      it "counts correctly time_elapsed" do
        klass.create_stats = true
        expect(klass.stats[:all][:time_elapsed][:total]).to eq 0
        http = klass.new("http://example.com")
        resp = http.get "/"
        expect(klass.stats[:all][:time_elapsed][:total]).to eq resp[:time_elapsed]
        prev_time = resp[:time_elapsed]
        http2 = klass.new("http://www.google.com")
        resp = http2.get "/"
        expect(klass.stats[:all][:time_elapsed][:total]).to eq (resp[:time_elapsed] + prev_time)
        expect(klass.stats[:all][:time_elapsed][:maximum]).to be >= klass.stats[:all][:time_elapsed][:minimum]
        expect(klass.stats[:all][:time_elapsed][:minimum]).to be <= klass.stats[:all][:time_elapsed][:maximum]
        expect(klass.stats[:all][:time_elapsed][:minimum]).to be_between(klass.stats[:all][:time_elapsed][:minimum], klass.stats[:all][:time_elapsed][:maximum])
      end
      it "creates correctly the http method stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        http2 = klass.new("http://www.google.com")
        resp = http2.post "/"
        expect(klass.stats[:all][:method].keys).to eq (["GET", "POST"])
        expect(klass.stats[:all][:method]["GET"].keys).to eq ([:num_requests, :started, :finished, :real_time_elapsed, :time_elapsed, :response])
        expect(klass.stats[:all][:method]["GET"][:time_elapsed][:total]).to be > 0
      end

      it "creates correctly the http response stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        http2 = klass.new("http://www.google.com")
        resp = http2.post "/"
        expect(klass.stats[:all][:method]["GET"][:response].keys).to eq (["200"])
        expect(klass.stats[:all][:method]["GET"][:response]["200"].keys).to eq ([:num_requests, :started, :finished, :real_time_elapsed, :time_elapsed])
        expect(klass.stats[:all][:method]["GET"][:response]["200"][:time_elapsed][:total]).to be > 0
      end
    end
    describe "path" do
      it "counts correctly the number of requests" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        expect(klass.stats[:path]["example.com:80"]["/"][:num_requests]).to eq 1
        http2 = klass.new("http://www.google.com")
        resp = http2.get "/"
        expect(klass.stats[:path]["www.google.com:80"]["/"][:num_requests]).to eq 1
      end
      it "counts correctly time_elapsed" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        expect(klass.stats[:path]["example.com:80"]["/"][:time_elapsed][:total]).to eq resp[:time_elapsed]
        prev_time = resp[:time_elapsed]
        resp = http.get "/"
        expect(klass.stats[:path]["example.com:80"]["/"][:time_elapsed][:total]).to eq (resp[:time_elapsed] + prev_time)
        expect(klass.stats[:path]["example.com:80"]["/"][:time_elapsed][:maximum]).to be >= klass.stats[:all][:time_elapsed][:minimum]
        expect(klass.stats[:path]["example.com:80"]["/"][:time_elapsed][:minimum]).to be <= klass.stats[:all][:time_elapsed][:maximum]
        expect(klass.stats[:path]["example.com:80"]["/"][:time_elapsed][:minimum]).to be_between(klass.stats[:all][:time_elapsed][:minimum], klass.stats[:all][:time_elapsed][:maximum])
      end
      it "creates correctly the http method stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        resp = http.post "/"
        expect(klass.stats[:path]["example.com:80"]["/"][:method].keys).to eq (["GET", "POST"])
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"].keys).to eq ([:num_requests, :started, :finished, :real_time_elapsed, :time_elapsed, :response])
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:time_elapsed][:total]).to be > 0
      end

      it "creates correctly the http response stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        resp = http.post "/"
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:response].keys).to eq (["200"])
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:response]["200"].keys).to eq ([:num_requests, :started, :finished, :real_time_elapsed, :time_elapsed])
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:response]["200"][:time_elapsed][:total]).to be > 0
      end
    end
    describe "name" do
      it "counts correctly the number of requests" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:num_requests]).to eq 1
        resp = http.get({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:num_requests]).to eq 2
      end
      it "counts correctly time_elapsed" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:time_elapsed][:total]).to eq resp[:time_elapsed]
        prev_time = resp[:time_elapsed]
        resp = http.get({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:time_elapsed][:total]).to eq (resp[:time_elapsed] + prev_time)
        expect(klass.stats[:name]["exam_name"][:time_elapsed][:maximum]).to be >= klass.stats[:all][:time_elapsed][:minimum]
        expect(klass.stats[:name]["exam_name"][:time_elapsed][:minimum]).to be <= klass.stats[:all][:time_elapsed][:maximum]
        expect(klass.stats[:name]["exam_name"][:time_elapsed][:minimum]).to be_between(klass.stats[:all][:time_elapsed][:minimum], klass.stats[:all][:time_elapsed][:maximum])
      end
      it "creates correctly the http method stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.post({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:method].keys).to eq (["GET", "POST"])
        expect(klass.stats[:name]["exam_name"][:method]["GET"].keys).to eq ([:num_requests, :started, :finished, :real_time_elapsed, :time_elapsed, :response])
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:time_elapsed][:total]).to be > 0
      end

      it "creates correctly the http response stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.post({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:response].keys).to eq (["200"])
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:response]["200"].keys).to eq ([:num_requests, :started, :finished, :real_time_elapsed, :time_elapsed])
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:response]["200"][:time_elapsed][:total]).to be > 0
      end
    end

    describe "specific" do
      it "counts correctly the number of records" do
        klass.create_stats = true
        started = Time.now
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.get({path: "/", name: "exam_name"})
        klass.add_stats(:example, :correct, started, Time.now)
        expect(klass.stats[:specific][:example][:num]).to eq 1
        expect(klass.stats[:specific][:example][:correct][:num]).to eq 1
        started = Time.now
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.get({path: "/", name: "exam_name"})
        klass.add_stats(:example, :correct, started, Time.now)
        expect(klass.stats[:specific][:example][:num]).to eq 2
        expect(klass.stats[:specific][:example][:correct][:num]).to eq 2
        started = Time.now
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.get({path: "/", name: "exam_name"})
        klass.add_stats(:example, :correct, started, Time.now)
        expect(klass.stats[:specific][:example][:num]).to eq 3
        expect(klass.stats[:specific][:example][:correct][:num]).to eq 3
      end
      it "counts correctly time_elapsed" do
        klass.create_stats = true
        started = Time.now
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.get({path: "/", name: "exam_name"})
        finished = Time.now
        klass.add_stats(:example, :correct, started, finished)
        expect(klass.stats[:specific][:example][:time_elapsed][:total]).to eq (finished-started)
        expect(klass.stats[:specific][:example][:correct][:time_elapsed][:total]).to eq (finished-started)
      end
      it "creates correctly the hash" do
        klass.create_stats = true
        started = Time.now
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.post({path: "/", name: "exam_name"})
        klass.add_stats(:example, :correct, started, Time.now)
        expect(klass.stats[:specific][:example].keys).to eq ([:num, :started, :finished, :real_time_elapsed, :time_elapsed, :correct])
        expect(klass.stats[:specific][:example][:time_elapsed].keys).to eq ([:total, :maximum, :minimum, :average])
        expect(klass.stats[:specific][:example][:correct].keys).to eq ([:num, :started, :finished, :real_time_elapsed, :time_elapsed, :items])
        expect(klass.stats[:specific][:example][:correct][:time_elapsed].keys).to eq ([:total, :maximum, :minimum, :average])
      end
      it "creates correctly the hash with max and min and items" do
        klass.create_stats = true
        started = Time.now
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.post({path: "/", name: "exam_name"})
        klass.add_stats(:example, :correct, started, Time.now, "example")
        expect(klass.stats[:specific][:example].keys).to eq ([:num, :started, :finished, :real_time_elapsed, :time_elapsed, :correct])
        expect(klass.stats[:specific][:example][:time_elapsed].keys).to eq ([:total, :maximum, :minimum, :average, :item_maximum, :item_minimum])
        expect(klass.stats[:specific][:example][:correct].keys).to eq ([:num, :started, :finished, :real_time_elapsed, :time_elapsed, :items])
        expect(klass.stats[:specific][:example][:correct][:time_elapsed].keys).to eq ([:total, :maximum, :minimum, :average, :item_maximum, :item_minimum])
      end
    end
    describe "save_stats" do
      it 'generates the files when no file_name supplied' do
        klass.create_stats = true
        klass.log = './nice_http_tmp.log'
        #File.delete(klass.log) if File.exist?(klass.log)
        #File.delete('./nice_http_tmp_stats_all.yaml') if File.exist?('./nice_http_tmp_stats_all.yaml')
        http = klass.new("http://example.com")
        resp = http.get "/"
        klass.save_stats()
        expect(File.exist?('./nice_http_tmp_stats_all.yaml')).to eq true
      end

      it 'generates the files when file_name supplied and extension .yaml' do
        klass.create_stats = true
        File.delete('./nice_http_tmp_stats_all.yaml') if File.exist?('./nice_http_tmp_stats_all.yaml')
        http = klass.new("http://example.com")
        resp = http.get "/"
        klass.save_stats('./nice_http_tmp.yaml')
        expect(File.exist?('./nice_http_tmp_stats_all.yaml')).to eq true
      end

      it 'generates the files when file_name supplied and extension .json' do
        klass.create_stats = true
        File.delete('./nice_http_tmp_stats_all.json') if File.exist?('./nice_http_tmp_stats_all.json')
        http = klass.new("http://example.com")
        resp = http.get "/"
        klass.save_stats('./nice_http_tmp.json')
        expect(File.exist?('./nice_http_tmp_stats_all.json')).to eq true
      end

      it 'generates the stats files when log_path specified and :fix_file' do
        file = './tmp/logs/nice_http_stats_all.yaml'
        klass.create_stats = true
        klass.log_path = './tmp/logs/'
        klass.log = :fix_file
        File.delete(file) if File.exist?(file)
        http = klass.new("http://example.com")
        resp = http.get "/"
        klass.save_stats()
        expect(File.exist?(file)).to eq true
      end

      it 'generates the stats files when log_path specified and :file_run' do
        file = './tmp/logs/nice_http_stats_all.yaml'
        klass.create_stats = true
        klass.log_path = './tmp/logs/'
        klass.log = :file_run
        File.delete(file) if File.exist?(file)
        http = klass.new("http://example.com")
        resp = http.get "/"
        klass.save_stats()
        expect(File.exist?(file)).to eq true
      end

    end
  end
end
