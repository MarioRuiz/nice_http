module NiceHttpHttpMethods

  ######################################################
  # Delete an existing resource
  # @param argument [Hash, String]  hash containing at least key :path or a string with the path
  #
  # @return [Hash] response
  #   Including at least the symbol keys:
  #     :data = the response data body.
  #     :message = plain text response.
  #     :code = code response (200=ok,500=wrong...).
  #   All keys in response are lowercase.
  #   data, message and code can also be accessed as attributes like .message .code .data.
  #   In case of fatal error returns { fatal_error: "the error description", code: nil, message: nil, data: '' }
  # @example
  #   resp = @http.delete(Requests::Customer.remove_session)
  #   assert resp.code == 204
  ######################################################
  def delete(argument)
    begin
      if argument.kind_of?(String)
        argument = { :path => argument }
      end
      path, data, headers_t = manage_request(argument)
      @start_time = Time.now if @start_time.nil?
      if argument.kind_of?(Hash)
        arg = argument
        if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response)
          data = ""
          if arg[:mock_response].keys.include?(:data)
            data = arg[:mock_response][:data]
            if data.kind_of?(Hash) #to json
              begin
                require "json"
                data = data.to_json
              rescue
                @logger.fatal "There was a problem converting to json: #{data}"
              end
            end
          end
          @logger.warn "Pay attention!!! This is a mock response:"
          @start_time_net = Time.now if @start_time_net.nil?
          manage_response(arg[:mock_response], data.to_s)
          return @response
        end
      end

      begin
        @start_time_net = Time.now if @start_time_net.nil?
        if data.to_s == ""
          resp = @http.delete(path, headers_t)
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
              resp = @http.delete(path, headers_t)
            end
          end
        else
          request = Net::HTTP::Delete.new(path, headers_t)
          request.body = data
          resp = @http.request(request)
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
              request = Net::HTTP::Delete.new(path, headers_t)
              request.body = data
              resp = @http.request(request)
            end
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
          resp, data = @http.delete(path, headers_t)
        end
      end
      manage_response(resp, data)

      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil, data: "" }
    end
  end
end
