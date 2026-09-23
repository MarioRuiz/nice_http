require "nice_http"

RSpec.describe "reconnect" do
  before do
    NiceHttp.log_files = {}
    @http = NiceHttp.new(TEST_SERVER_URL)
  end

  def stub_once(method_name)
    counter = { n: 0 }
    @http.instance_variable_get(:@http).define_singleton_method(method_name) do |*_args|
      counter[:n] += 1
      raise IOError, "closed" if counter[:n] == 1

      { code: "200", message: "OK", header: { "content-type" => "text/plain" }, body: "retried-body" }
    end
    counter
  end

  it "keeps the body when PUT is retried" do
    counter = stub_once(:send_request)
    resp = @http.put({ path: "/api/users/2", data: { name: "ada" } })
    expect(counter[:n]).to eq 2
    expect(resp.data).to eq "retried-body"
  end

  it "keeps the body when PATCH is retried" do
    counter = stub_once(:patch)
    resp = @http.patch({ path: "/api/users/2", data: { name: "ada" } })
    expect(counter[:n]).to eq 2
    expect(resp.data).to eq "retried-body"
  end

  it "keeps the body when DELETE is retried" do
    counter = stub_once(:delete)
    resp = @http.delete("/api/users/2")
    expect(counter[:n]).to eq 2
    expect(resp.data).to eq "retried-body"
  end

  it "keeps the body when HEAD is retried" do
    counter = stub_once(:head)
    resp = @http.head("/api/users")
    expect(counter[:n]).to eq 2
    expect(resp.data).to eq "retried-body"
  end
end
