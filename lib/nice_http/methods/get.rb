module NiceHttpHttpMethods

  ######################################################
  # Get data from path
  #
  # @param arg [Hash, String] hash containing at least key :path or a string with the path
  # @param save_data [String] the path or path and file name where we want to save the response data
  #
  # @return [Hash] response.
  #   Including at least the symbol keys:
  #     :data = the response data body.
  #     :message = plain text response.
  #     :code = code response (200=ok,500=wrong...).
  #   All keys in response are lowercase.
  #   data, message and code can also be accessed as attributes like .message .code .data.
  #   In case of fatal error returns { fatal_error: "the error description", code: nil, message: nil, data: '' }
  #
  # @example
  #   resp = @http.get(Requests::Customer.get_profile)
  #   assert resp.code == 200
  # @example
  #   resp = @http.get("/customers/1223")
  #   assert resp.message == "OK"
  # @example
  #   resp = @http.get("/assets/images/logo.png", save_data: './tmp/')
  # @example
  #   resp = @http.get("/assets/images/logo.png", save_data: './tmp/example.png')
  ######################################################
  def get(arg, save_data: "")
    begin
      path, data, headers_t = manage_request(arg)

      @start_time = Time.now if @start_time.nil?
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
      begin
        if path.start_with?("http:") or path.start_with?("https:") #server included on path problably because of a redirection to a different server
          require "uri"
          uri = URI.parse(path)
          ssl = false
          ssl = true if path.include?("https:")

          server = "http://"
          server = "https://" if path.start_with?("https:")
          if uri.port != 443
            server += "#{uri.host}:#{uri.port}"
          else
            server += "#{uri.host}"
          end

          http_redir = nil
          self.class.connections.each { |conn|
            if conn.host == uri.host and conn.port == uri.port
              http_redir = conn
              break
            end
          }

          if !http_redir.nil?
            path, data, headers_t = manage_request(arg)
            http_redir.cookies.merge!(@cookies)
            http_redir.headers.merge!(headers_t)
            #todo: remove only the server at the begining in case in query is the server it will be replaced when it should not be
            resp = http_redir.get(path.gsub(server, ""))
            @response = http_redir.response
          else
            @logger.warn "It seems like the http connection cannot redirect to #{server} because there is no active connection for that server. You need to create previously one."
          end
        else
          @start_time_net = Time.now if @start_time_net.nil?
          resp = @http.get(path, headers_t)
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
              resp = @http.get(path, headers_t)
            end
          end
          data = resp.body
          manage_response(resp, data)
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
          resp = @http.get(path, headers_t)
          data = resp.body
          manage_response(resp, data)
        end
      end
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
      if save_data != ""
        require "pathname"
        pn_get = Pathname.new(path)

        if Dir.exist?(save_data)
          save = save_data + "/" + pn_get.basename.to_s
        elsif save_data[-1] == "/"
          save = save_data + pn_get.basename.to_s
        else
          save = save_data
        end
        if Dir.exist?(Pathname.new(save).dirname)
          File.open(save, "wb") { |fp| fp.write(@response.data) }
        else
          @logger.fatal "The folder #{Pathname.new(save).dirname} doesn't exist"
        end
      end
      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil, data: "" }
    end
  end
end
