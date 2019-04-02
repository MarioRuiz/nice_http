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
        expect(klass.stats[:all][:method]["GET"].keys).to eq ([:num_requests, :time_elapsed, :response])
        expect(klass.stats[:all][:method]["GET"][:time_elapsed][:total]).to be > 0
      end

      it "creates correctly the http response stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        http2 = klass.new("http://www.google.com")
        resp = http2.post "/"
        expect(klass.stats[:all][:method]["GET"][:response].keys).to eq (["200"])
        expect(klass.stats[:all][:method]["GET"][:response]["200"].keys).to eq ([:num_requests, :time_elapsed])
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
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"].keys).to eq ([:num_requests, :time_elapsed, :response])
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:time_elapsed][:total]).to be > 0
      end

      it "creates correctly the http response stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get "/"
        resp = http.post "/"
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:response].keys).to eq (["200"])
        expect(klass.stats[:path]["example.com:80"]["/"][:method]["GET"][:response]["200"].keys).to eq ([:num_requests, :time_elapsed])
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
        expect(klass.stats[:name]["exam_name"][:method]["GET"].keys).to eq ([:num_requests, :time_elapsed, :response])
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:time_elapsed][:total]).to be > 0
      end

      it "creates correctly the http response stats" do
        klass.create_stats = true
        http = klass.new("http://example.com")
        resp = http.get({path: "/", name: "exam_name"})
        resp = http.post({path: "/", name: "exam_name"})
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:response].keys).to eq (["200"])
        expect(klass.stats[:name]["exam_name"][:method]["GET"][:response]["200"].keys).to eq ([:num_requests, :time_elapsed])
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
        expect(klass.stats[:specific][:example].keys).to eq ([:num, :time_elapsed, :correct])
        expect(klass.stats[:specific][:example][:time_elapsed].keys).to eq ([:total, :maximum, :minimum, :average])
        expect(klass.stats[:specific][:example][:correct].keys).to eq ([:num, :time_elapsed, :items])
        expect(klass.stats[:specific][:example][:correct][:time_elapsed].keys).to eq ([:total, :maximum, :minimum, :average])
      end
    end
  end
end
