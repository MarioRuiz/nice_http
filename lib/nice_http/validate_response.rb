class NiceHttp
  ######################################################
  # Validates that a response body matches an expected structure (keys and nesting).
  # Uses NiceHash.compare_structure. Best for JSON responses.
  #
  # @param resp [Hash] Response object (e.g. from get/post). Must have :data (body string or Hash/Array).
  # @param expected_structure [Hash, Array] Structure with expected keys and nesting (values can be placeholders).
  # @param options [Hash] Optional. :include_diff => true adds a diff when validation fails.
  #   :explain => true adds NiceHash pattern errors when a pattern in expected_structure does not match.
  #   String keys in expected_structure are treated the same as symbol keys.
  #   Pattern checks run only when expected_structure contains pattern symbols, shorthands
  #   (:uuid, :email, :iban, :luhn), checksum pairs, a one-element pattern array, a Range, a Regexp, DateTime or Boolean.
  #   A plain string such as "10:N" stays a literal and is not validated as a pattern.
  # @return [Hash] { ok: true } when it matches, or { ok: false } with optional :diff and :explain.
  # @example
  #   resp = http.get("/api/users/1")
  #   result = NiceHttp.validate_response(resp, { user: { name: "xxx", id: 1 } })
  #   expect(result[:ok]).to be true
  # @example
  #   result = NiceHttp.validate_response(resp, expected, include_diff: true)
  #   puts result[:diff] unless result[:ok]
  # @example
  #   result = NiceHttp.validate_response(resp, { email: :email }, explain: true)
  #   result[:explain][:email][:message] unless result[:ok]
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

    # Normalize to symbol keys so compare_structure/diff match either string or symbol keys
    parsed = deep_symbolize(parsed) if parsed.is_a?(Hash) || parsed.is_a?(Array)
    expected = if expected_structure.is_a?(Hash) || expected_structure.is_a?(Array)
        deep_symbolize(expected_structure)
      else
        expected_structure
      end

    pattern_errors = {}
    if NiceHttpUtils.contains_pattern?(expected)
      comparable = NiceHttpUtils.structure_without_patterns(expected, parsed)
      ok = NiceHash.compare_structure(comparable, parsed)
      wrapped = NiceHash.validate({ root: expected }, { root: parsed }, only_patterns: true, explain: options[:explain] ? true : false)
      pattern_errors = wrapped.is_a?(Hash) && wrapped.key?(:root) ? wrapped[:root] : wrapped
      ok &&= pattern_errors.respond_to?(:empty?) && pattern_errors.empty?
    else
      ok = NiceHash.compare_structure(expected, parsed)
    end

    result = { ok: ok }
    if !ok && options[:include_diff]
      result[:diff] = NiceHash.diff(expected, parsed)
    end
    if !ok && options[:explain] && pattern_errors.respond_to?(:empty?) && !pattern_errors.empty?
      result[:explain] = pattern_errors
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
