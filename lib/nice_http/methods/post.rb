module NiceHttpHttpMethods

  ######################################################
  # Post data to path
  # @param arguments [Hash] containing at least keys :data and :path.
  #   In case :data not supplied and :data_examples array supplied, it will be taken the first example as :data.
  # @param arguments [Array<path, data, additional_headers>]
  #   path (string).
  #   data (json data for example).
  #   additional_headers (Hash key=>value).
  # @return [Hash] response
  #   Including at least the symbol keys:
  #     :data = the response data body.
  #     :message = plain text response.
  #     :code = code response (200=ok,500=wrong...).
  #   All keys in response are lowercase.
  #   data, message and code can also be accessed as attributes like .message .code .data.
  #   In case of fatal error returns { fatal_error: "the error description", code: nil, message: nil, data: '' }
  # @example
  #   resp = @http.post(Requests::Customer.update_customer)
  #   assert resp.code == 201
  # @example
  #   resp = http.post( {
  #                       path: "/api/users",
  #                       data: {name: "morpheus", job: "leader"}
  #                      } )
  #   pp resp.data.json
  ######################################################
  def post(*arguments)
    begin
      path, data, headers_t = manage_request(*arguments)
      @start_time = Time.now if @start_time.nil?
      if arguments.size > 0 and arguments[0].kind_of?(Hash)
        arg = arguments[0]
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
        if headers_t["Content-Type"] == "multipart/form-data"
          require "net/http/post/multipart"
          headers_t.each { |key, value|
            arguments[0][:data].add_field(key, value) #add to Headers
          }
          resp = @http.request(arguments[0][:data])
        elsif headers_t["Content-Type"].to_s.include?("application/x-www-form-urlencoded")
          encoded_form = URI.encode_www_form(arguments[0][:data])
          resp = @http.request_post(path, encoded_form, headers_t)
          data = resp.body
        else
          resp = @http.post(path, data, headers_t)
          #todo: do it also for forms and multipart
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
              resp = @http.post(path, data, headers_t)
            end
          end
          data = resp.body
        end
      rescue Exception => stack
        @logger.warn stack
        if !@timeout.nil? and (Time.now - @start_time_net) > @timeout
          @logger.warn "The connection seems to be closed in the host machine. Timeout."
          return { fatal_error: "Net::ReadTimeout", code: nil, message: nil, data: "" }
        else
          @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
          @http.finish()
          @http.start()
          @start_time_net = Time.now if @start_time_net.nil?
          @headers_orig.each { |k, v| headers_t[k] = v.call if v.is_a?(Proc) and headers_t.key?(k) }
          resp, data = @http.post(path, data, headers_t)
        end
      end
      manage_response(resp, data)
      if @auto_redirect and @response[:code].to_i >= 300 and @response[:code].to_i < 400 and @response.include?(:location)
        if @num_redirects <= 30
          @num_redirects += 1
          current_server = "http"
          current_server += "s" if @ssl == true
          current_server += "://#{@host}"
          location = @response[:location].gsub(current_server, "")
          @logger.info "(#{@num_redirects}) Redirecting NiceHttp to #{location}"
          get(location)
        else
          @logger.fatal "(#{@num_redirects}) Maximum number of redirections for a single request reached. Be sure everything is correct, it seems there is a non ending loop"
          @num_redirects = 0
        end
      else
        @num_redirects = 0
      end
      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil, data: "" }
    end
  end
end
