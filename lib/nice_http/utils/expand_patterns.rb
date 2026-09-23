module NiceHttpUtils
  PATTERN_SYMBOL = /\A!?\d+-?\d*:.+/
  SELECTOR_SYMBOL = /\A(?:[\w\s\-]+\|)+[\w\s\-]+\z/
  SHORTHANDS = [:uuid, :email, :iban, :luhn].freeze

  # A value NiceHttp expands before sending, or that validate_response checks as a pattern.
  # Plain strings are never patterns here, even when they look like "10:N" or "a|b".
  def self.pattern_value?(value)
    return true if pattern_symbol?(value)
    return true if value.is_a?(Range) || value.is_a?(Regexp)
    return true if defined?(DateTime) && value.is_a?(Class) && value == DateTime
    return true if defined?(Boolean) && value.is_a?(Module) && value == Boolean
    return true if checksum_array?(value)
    return true if one_pattern_array?(value)

    false
  end

  def self.contains_pattern?(obj)
    return true if pattern_value?(obj)

    case obj
    when Hash
      obj.any? { |_key, value| contains_pattern?(value) }
    when Array
      obj.any? { |value| contains_pattern?(value) }
    else
      false
    end
  end

  # Copy of expected where pattern placeholders are replaced by the actual value,
  # so compare_structure checks shape and leaves pattern checks to NiceHash.validate.
  def self.structure_without_patterns(expected, actual)
    if pattern_value?(expected)
      return actual.nil? ? expected : actual
    end

    case expected
    when Hash
      expected.each_with_object({}) do |(key, value), copy|
        child = actual.is_a?(Hash) ? actual[key] : nil
        copy[key] = structure_without_patterns(value, child)
      end
    when Array
      if expected.empty?
        expected
      else
        child = actual.is_a?(Array) ? actual[0] : nil
        [structure_without_patterns(expected[0], child)]
      end
    else
      expected
    end
  end

  # Copy a request without cloning Class or Module.
  # DateTime.clone is an anonymous class and Boolean.clone is an anonymous module,
  # so NiceHash.generate would no longer recognize them.
  def self.copy_request(obj)
    case obj
    when Hash
      obj.each_with_object({}) { |(key, value), copy| copy[key] = copy_request(value) }
    when Array
      obj.map { |value| copy_request(value) }
    else
      return obj if obj.is_a?(Module)

      obj.clone
    end
  rescue StandardError
    obj
  end

  # New hash or array. Strings, numbers, booleans, nil and procs are copied as they are.
  def self.expand_patterns(obj)
    case obj
    when Hash
      obj.each_with_object({}) { |(key, value), copy| copy[key] = expand_pattern_value(value) }
    when Array
      if pattern_value?(obj)
        generate_pattern(obj)
      else
        obj.map { |value| expand_pattern_value(value) }
      end
    else
      expand_pattern_value(obj)
    end
  end

  def self.expand_pattern_value(value)
    if pattern_value?(value)
      generate_pattern(value)
    elsif value.is_a?(Hash) || value.is_a?(Array)
      expand_patterns(value)
    else
      value
    end
  end

  def self.generate_pattern(value)
    NiceHash.generate({ pattern: value })[:pattern]
  end

  def self.pattern_symbol?(value)
    return false unless value.is_a?(Symbol)
    return true if SHORTHANDS.include?(value)

    text = value.to_s
    text.match?(PATTERN_SYMBOL) || text.match?(SELECTOR_SYMBOL)
  end

  def self.checksum_array?(value)
    value.is_a?(Array) && value.size.between?(1, 2) && [:iban, :luhn].include?(value[0])
  end

  def self.one_pattern_array?(value)
    return false unless value.is_a?(Array) && value.size == 1
    return false if checksum_array?(value)

    element = value[0]
    return false unless element.is_a?(Symbol)

    StringPattern.analyze(element, silent: true).is_a?(StringPattern::Pattern)
  rescue StandardError
    false
  end

  private_class_method :expand_pattern_value, :generate_pattern, :pattern_symbol?, :checksum_array?, :one_pattern_array?
end
