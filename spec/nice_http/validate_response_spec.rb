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
      expect(result[:error]).to be_a(String)
      expect(result[:error]).not_to be_empty
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

    it "accepts string keys in the expected structure" do
      resp = { data: '{"name":"Alice","id":1}' }
      expected = { "name" => "xxx", "id" => 1 }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
    end

    it "keeps a literal string that looks like a pattern as a structure placeholder" do
      resp = { data: '{"code":"10:N"}' }
      expected = { code: "10:N" }
      result = described_class.validate_response(resp, expected)
      expect(result[:ok]).to be true
      expect(result).not_to have_key(:explain)
    end

    it "accepts a response value that matches a pattern shorthand" do
      resp = { data: { email: "person@example.com" } }
      result = described_class.validate_response(resp, { email: :email })
      expect(result[:ok]).to be true
      expect(result).not_to have_key(:explain)
    end

    it "explains a pattern mismatch" do
      resp = { data: '{"email":"not-an-email"}' }
      result = described_class.validate_response(resp, { email: :email }, explain: true, include_diff: true)
      expect(result[:ok]).to be false
      expect(result[:explain]).to be_a(Hash)
      expect(result[:explain][:email]).to include(:message, :errors)
      expect(result[:diff]).to be_a(Hash)
    end

    it "omits explain when the pattern matches" do
      resp = { data: { email: "person@example.com" } }
      result = described_class.validate_response(resp, { email: :email }, explain: true)
      expect(result[:ok]).to be true
      expect(result).not_to have_key(:explain)
    end

    it "still fails when a pattern field is present and another key is missing" do
      resp = { data: '{"email":"person@example.com"}' }
      result = described_class.validate_response(resp, { email: :email, id: 1 })
      expect(result[:ok]).to be false
    end

    it "checks nested patterns, ranges, regexps and checksum pairs" do
      resp = {
        data: {
          user: { id: "550e8400-e29b-41d4-a716-446655440000" },
          age: 21,
          token: "AB12",
          iban: "DE89370400440532013000",
        },
      }
      expected = {
        user: { id: :uuid },
        age: 18..30,
        token: /[A-Z0-9]{4}/,
        iban: [:iban, "DE"],
      }
      expect(described_class.validate_response(resp, expected)[:ok]).to be true

      resp[:data][:age] = 90
      resp[:data][:iban] = "ES9121000418450200051332"
      result = described_class.validate_response(resp, expected, explain: true)
      expect(result[:ok]).to be false
      expect(result[:explain]).to have_key(:age)
      expect(result[:explain]).to have_key(:iban)
    end

    it "checks a pattern inside an array of hashes" do
      resp = { data: [{ code: "123" }, { code: "987" }] }
      result = described_class.validate_response(resp, [{ code: :"3:N" }])
      expect(result[:ok]).to be true

      resp = { data: [{ code: "12A" }] }
      result = described_class.validate_response(resp, [{ code: :"3:N" }], explain: true)
      expect(result[:ok]).to be false
      expect(result[:explain]).not_to be_empty
    end
  end
end
