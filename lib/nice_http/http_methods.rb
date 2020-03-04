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
  def get(arg, save_data: '')
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
          if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
            @logger.warn "Not authorized. Trying to generate a new token."
            @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
            resp = @http.get(path, headers_t)
          end
          data = resp.body
          manage_response(resp, data)
        end
      rescue Exception => stack
        @logger.warn stack
        @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
        @http.finish()
        @http.start()
        @start_time_net = Time.now if @start_time_net.nil?
        resp = @http.get(path)
        data = resp.body
        manage_response(resp, data)
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
      if save_data!=''
        require 'pathname'
        pn_get = Pathname.new(path)

        if Dir.exist?(save_data)
          save = save_data + "/" + pn_get.basename.to_s
        elsif save_data[-1]=="/"
          save = save_data + pn_get.basename.to_s
        else
          save = save_data
        end
        if Dir.exist?(Pathname.new(save).dirname)
          File.open(save, 'wb') { |fp| fp.write(@response.data) }
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
          if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
            @logger.warn "Not authorized. Trying to generate a new token."
            @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
            resp = @http.post(path, data, headers_t)
          end
          data = resp.body
        end
      rescue Exception => stack
        @logger.warn stack
        @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
        @http.finish()
        @http.start()
        @start_time_net = Time.now if @start_time_net.nil?
        resp, data = @http.post(path, data, headers_t)
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

  ######################################################
  # Put data to path
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
  #   resp = @http.put(Requests::Customer.remove_phone)
  ######################################################
  def put(*arguments)
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
        resp = @http.send_request("PUT", path, data, headers_t)
        if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
          @logger.warn "Not authorized. Trying to generate a new token."
          @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
          resp = @http.send_request("PUT", path, data, headers_t)
        end
        data = resp.body
      rescue Exception => stack
        @logger.warn stack
        @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
        @http.finish()
        @http.start()
        @start_time_net = Time.now if @start_time_net.nil?
        resp, data = @http.send_request("PUT", path, data, headers_t)
      end
      manage_response(resp, data)

      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil, data: "" }
    end
  end

  ######################################################
  # Patch data to path
  #
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
  #   resp = @http.patch(Requests::Customer.unrelease_account)
  ######################################################
  def patch(*arguments)
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
        resp = @http.patch(path, data, headers_t)
        if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
          @logger.warn "Not authorized. Trying to generate a new token."
          @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
          resp = @http.patch(path, data, headers_t)
        end
        data = resp.body
      rescue Exception => stack
        @logger.warn stack
        @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
        @http.finish()
        @http.start()
        @start_time_net = Time.now if @start_time_net.nil?
        resp, data = @http.patch(path, data, headers_t)
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
          if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
            @logger.warn "Not authorized. Trying to generate a new token."
            @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
            resp = @http.delete(path, headers_t)
          end
        else
          request = Net::HTTP::Delete.new(path, headers_t)
          request.body = data
          resp = @http.request(request)
          if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
            @logger.warn "Not authorized. Trying to generate a new token."
            @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
            request = Net::HTTP::Delete.new(path, headers_t)
            request.body = data
            resp = @http.request(request)
          end
        end
        data = resp.body
      rescue Exception => stack
        @logger.warn stack
        @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
        @http.finish()
        @http.start()
        @start_time_net = Time.now if @start_time_net.nil?
        resp, data = @http.delete(path)
      end
      manage_response(resp, data)

      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil, data: "" }
    end
  end

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
        if resp.code == 401 and @headers_orig.values.map(&:class).include?(Proc)
          @logger.warn "Not authorized. Trying to generate a new token."
          @headers_orig.each { |k,v| headers_t[k] = v.call if v.is_a?(Proc)}
          resp = @http.head(path, headers_t)
        end
        data = resp.body
      rescue Exception => stack
        @logger.warn stack
        @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
        @http.finish()
        @http.start()
        @start_time_net = Time.now if @start_time_net.nil?
        resp, data = @http.head(path)
      end
      manage_response(resp, data)
      return @response
    rescue Exception => stack
      @logger.fatal stack
      return { fatal_error: stack.to_s, code: nil, message: nil }
    end
  end

  ######################################################
  # It will send the request depending on the :method declared on the request hash  
  # Take a look at https://github.com/MarioRuiz/Request-Hash
  #
  # @param request_hash [Hash] containing at least key :path and :method. The methods that are accepted are: :get, :head, :post, :put, :delete, :patch
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
  #   resp = @http.send_request Requests::Customer.remove_session
  #   assert resp.code == 204
  ######################################################
  def send_request(request_hash)
    unless request_hash.is_a?(Hash) and request_hash.key?(:method) and request_hash.key?(:path) and
           request_hash[:method].is_a?(Symbol) and
           [:get, :head, :post, :put, :delete, :patch].include?(request_hash[:method])
      message = "send_request: it needs to be supplied a Request Hash that includes a :method and :path. "
      message += "Supported methods: :get, :head, :post, :put, :delete, :patch"
      @logger.fatal message
      return { fatal_error: message, code: nil, message: nil }
    else
      case request_hash[:method]
      when :get
        resp = get request_hash
      when :post
        resp = post request_hash
      when :head
        resp = head request_hash
      when :put
        resp = put request_hash
      when :delete
        resp = delete request_hash
      when :patch
        resp = patch request_hash
      end
      return resp
    end
  end
end
