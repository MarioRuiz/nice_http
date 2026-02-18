class NiceHttp
  ######################################################
  # Validates that a response body matches an expected structure (keys and nesting).
  # Uses NiceHash.compare_structure. Best for JSON responses.
  #
  # @param resp [Hash] Response object (e.g. from get/post). Must have :data (body string or Hash/Array).
  # @param expected_structure [Hash, Array] Structure with expected keys and nesting (values can be placeholders).
  # @param options [Hash] Optional. :include_diff => true to add a diff in the result when validation fails.
  # @return [Hash] { ok: true } when structure matches, or { ok: false } or { ok: false, diff: Hash } when it does not.
  # @example
  #   resp = http.get("/api/users/1")
  #   result = NiceHttp.validate_response(resp, { user: { name: "xxx", id: 1 } })
  #   expect(result[:ok]).to be true
  # @example
  #   result = NiceHttp.validate_response(resp, expected, include_diff: true)
  #   puts result[:diff] unless result[:ok]
  ######################################################
  def self.validate_response(resp, expected_structure, options = {})
    data = resp.is_a?(Hash) ? resp[:data] : resp.data
    parsed = if data.is_a?(String)
        begin
          require "json"
          JSON.parse(data.to_s)
        rescue JSON::ParserError
          return { ok: false, error: "response data is not valid JSON" }
        end
      elsif data.is_a?(Hash) || data.is_a?(Array)
        data
      else
        return { ok: false, error: "response data is missing or not JSON" }
      end

    # Normalize to symbol keys so compare_structure/diff match typical expected_structure (symbol keys)
    parsed = deep_symbolize(parsed) if parsed.is_a?(Hash) || parsed.is_a?(Array)

    ok = NiceHash.compare_structure(expected_structure, parsed)

    result = { ok: ok }
    if !ok && options[:include_diff]
      result[:diff] = NiceHash.diff(expected_structure, parsed)
    end
    result
  end

  def self.deep_symbolize(obj)
    case obj
    when Hash
      obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = deep_symbolize(v) }
    when Array
      obj.map { |e| deep_symbolize(e) }
    else
      obj
    end
  end
  private_class_method :deep_symbolize
end
