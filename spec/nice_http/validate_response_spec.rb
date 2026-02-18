# frozen_string_literal: true

require "ostruct"
require "nice_http"

RSpec.describe NiceHttp do
  describe ".validate_response" do
    it "returns ok: true when response structure matches expected" do
      resp = { data: '{"name":"Alice","id":1}' }
      expected = { name: "xxx", id: 1 }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
      expect(result).not_to have_key(:diff)
    end

    it "returns ok: false when response structure does not match" do
      resp = { data: '{"name":"Alice"}' }
      expected = { name: "xxx", id: 1 }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be false
    end

    it "includes diff when include_diff: true and structure does not match" do
      resp = { data: '{"name":"Alice"}' }
      expected = { name: "xxx", id: 1 }
      result = described_class.validate_response(resp, expected, include_diff: true)
      expect(result[:ok]).to be false
      expect(result[:diff]).to be_a(Hash)
    end

    it "accepts response with method-style data access" do
      resp = OpenStruct.new(data: '{"user":"test"}')
      expected = { user: "xxx" }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
    end

    it "returns error when data is not valid JSON" do
      resp = { data: "not json {" }
      expected = {}
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be false
      expect(result[:error]).to include("not valid JSON")
    end

    it "returns error when data is missing" do
      resp = {}
      expected = {}
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be false
      expect(result[:error]).to be_present
    end

    it "accepts nested expected structure" do
      resp = { data: '{"user":{"name":"Bob","age":30}}' }
      expected = { user: { name: "xxx", age: 1 } }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
    end

    it "accepts response with data as Hash (no JSON string)" do
      resp = { data: { user: "test", id: 1 } }
      expected = { user: "xxx", id: 1 }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
    end

    it "accepts expected_structure as Array" do
      resp = { data: '[{"a":1},{"a":2}]' }
      expected = [{ a: 1 }]
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
    end

    it "does not include diff when ok is true and include_diff: true" do
      resp = { data: '{"name":"Alice","id":1}' }
      expected = { name: "xxx", id: 1 }
      result = described_class.validate_response(resp, expected, include_diff: true)
      expect(result[:ok]).to be true
      expect(result).not_to have_key(:diff)
    end
  end
end
