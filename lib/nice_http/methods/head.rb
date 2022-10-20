module NiceHttpHttpMethods

  ######################################################
  # Implementation of the http HEAD method.
  # Asks for the response identical to the one that would correspond to a GET request, but without the response body.
  # This is useful for retrieving meta-information written in response headers, without having to transport the entire content.
  # @param argument [Hash, String] hash containing at least key :path or directly an string with the path
  #
  # @return [Hash] response
  #   Including at least the symbol keys:
  #     :message = plain text response.
  #     :code = code response (200=ok,500=wrong...).
  #   All keys in response are lowercase.
  #   message and code can also be accessed as attributes like .message .code.
  #   In case of fatal error returns { fatal_error: "the error description", code: nil, message: nil }
  ######################################################
  def head(argument)
    begin
      if argument.kind_of?(String)
        argument = { :path => argument }
      end
      path, data, headers_t = manage_request(argument)
      @start_time = Time.now if @start_time.nil?
      if argument.kind_of?(Hash)
        arg = argument
        if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response)
          @logger.warn "Pay attention!!! This is a mock response:"
          @start_time_net = Time.now if @start_time_net.nil?
          manage_response(arg[:mock_response], "")
          return @response
        end
      end

      begin
        @start_time_net = Time.now if @start_time_net.nil?
        resp = @http.head(path, headers_t)
        if (resp.code == 401 or resp.code == 408) and @headers_orig.values.map(&:class).include?(Proc)
          try = false
          @headers_orig.each do |k, v|
            if v.is_a?(Proc) and headers_t.key?(k)
              try = true
              headers_t[k] = v.call
            end
          end
          if try
            @logger.warn "Not authorized. Trying to generate a new token."
            resp = @http.head(path, headers_t)
          end
        end
        data = resp.body
      rescue Exception => stack
        @logger.warn stack
        if !@timeout.nil? and (Time.now - @start_time_net) > @timeout
          @logger.warn "The connection seems to be closed in the host machine. Timeout."
          return { fatal_error: "Net::ReadTimeout", code: nil, message: nil, data: "" }
        else
          @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
          @http.finish()
          @http.start()
          @headers_orig.each { |k, v| headers_t[k] = v.call if v.is_a?(Proc) and headers_t.key?(k) }
          @start_time_net = Time.now if @start_time_net.nil?
          resp, data = @http.head(path, headers_t)
        end
      end
      manage_response(resp, data)
      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil }
    end
  end
end
