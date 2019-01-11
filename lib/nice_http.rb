require 'logger'
require 'nice_hash'
require_relative 'nice_http/utils'

class NiceHttp
  class << self
    attr_accessor :host, :port, :ssl, :headers, :debug, :log, :proxy_host, :proxy_port, 
                  :last_request, :last_response, :request_id, :use_mocks, :connections,
                  :active, :auto_redirect
  end
  @host = nil
  @port = 80
  @ssl = false
  @headers  = {}
  @debug = false
  @log = :fix_file
  @proxy_host = nil
  @proxy_port = nil
  @last_request=nil
  @last_response=nil
  @request_id=""
  @use_mocks = false
  @connections = []
  @active=0
  @auto_redirect = true
  
  attr_reader :host, :port, :ssl, :debug, :log, :proxy_host, :proxy_port, :response, :num_redirects
  attr_accessor :headers, :cookies, :use_mocks, :auto_redirect, :logger

  def self.defaults=(par = {})
    @host = par[:host] if par.key?(:host)
    @port = par[:port] if par.key?(:port)
    @ssl = par[:ssl] if par.key?(:ssl)
    @headers = par[:headers] if par.key?(:headers)
    @debug = par[:debug] if par.key?(:debug)
    @log = par[:log] if par.key?(:log)
    @proxy_host = par[:proxy_host] if par.key?(:proxy_host)
    @proxy_port = par[:proxy_port] if par.key?(:proxy_port)
    @proxy_port = par[:use_mocks] if par.key?(:use_mocks)
    @auto_redirect = par[:auto_redirect] if par.key?(:auto_redirect)
  end

  ######################################################
  #  input:
  #    no parameters:
  #         By default will access how is setup on defaults
  #    one parameter:
  #         String
  #             "https://www.example.com"
  #             "example.com:8999"
  #             "localhost:8322"
  #         Hash containing these possible keys
  #             host -- example.com. (default blank screen)
  #             port -- port for the connection. 80 (default)
  #             ssl -- true, false (default)
  #             headers -- hash with the header key:values
  #             debug -- true, false (default)
  #             log -- :no, :screen, :file, :fix_file (default).
  #                 A string with a path can be supplied.
  #                 If :fix_file: nice_http.log
  #                 In case :file it will be generated a log file with name: nice_http_YY-mm-dd-HHMMSS.log
  #             proxy_host
  #             proxy_port
  ######################################################
  def initialize(args = {})
    require 'net/http'
    require 'net/https'
    @host = NiceHttp.host
    @port = NiceHttp.port
    @ssl = NiceHttp.ssl
    @headers = NiceHttp.headers
    @debug = NiceHttp.debug
    @log = NiceHttp.log
    @proxy_host = NiceHttp.proxy_host
    @proxy_port = NiceHttp.proxy_port
    @use_mocks = NiceHttp.use_mocks
    @auto_redirect=false #set it up at the end of initialize
    auto_redirect = NiceHttp.auto_redirect
    @num_redirects=0

    #todo: set only the cookies for the current domain
    #key: path, value: hash with key is the name of the cookie and value the value
    # we set the default value for non existing keys to empty Hash {} so in case of merge there is no problem
    @cookies=Hash.new {|h, k| h[k] = {}} 
    
    begin
      if args.is_a?(String)
        uri = URI.parse(args)
        @host = uri.host unless uri.host.nil?
        @port = uri.port unless uri.port.nil?
        @ssl = true if !uri.scheme.nil? && (uri.scheme == 'https')
      elsif args.is_a?(Hash) && !args.keys.empty?
        @host = args[:host] if args.keys.include?(:host)
        @port = args[:port] if args.keys.include?(:port)
        @ssl = args[:ssl] if args.keys.include?(:ssl)
        @headers = args[:headers] if args.keys.include?(:headers)
        @debug = args[:debug] if args.keys.include?(:debug)
        @log = args[:log] if args.keys.include?(:log)
        @proxy_host = args[:proxy_host] if args.keys.include?(:proxy_host)
        @proxy_port = args[:proxy_port] if args.keys.include?(:proxy_port)
        @use_mocks = args[:use_mocks] if args.keys.include?(:use_mocks)
        @auto_redirect = args[:auto_redirect] if args.keys.include?(:auto_redirect)
      end

      if @host.to_s!="" and (@host.include?("http:") or @host.include?("https:"))
        uri = URI.parse(@host)
        @host = uri.host unless uri.host.nil?
        @port = uri.port unless uri.port.nil?
        @ssl = true if !uri.scheme.nil? && (uri.scheme == 'https')
      end

      if @host.nil? or @host.to_s=="" or @port.nil? or @port.to_s==""
        message = "It was not possible to create the http connection!!!\n"
        message += "Wrong host or port, remember to supply http:// or https:// in case you specify an url to create the http connection, for example:\n"
        message += "http = NiceHttp.new('http://example.com')"
        raise message
      end

      if !@proxy_host.nil? && !@proxy_port.nil?
        @http = Net::HTTP::Proxy(@proxy_host, @proxy_port).new(@host, @port)
        @http.use_ssl = @ssl
        @http.set_debug_output $stderr if @debug
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @http.start
      else
        @http = Net::HTTP.new(@host, @port)
        @http.use_ssl = @ssl
        @http.set_debug_output $stderr if @debug
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @http.start
      end

      if @log.kind_of?(String)
        @logger = Logger.new File.new(@log, "w")
      elsif @log==:fix_file
        @logger = Logger.new File.new("nice_http.log", "w")
      elsif @log==:file
        @logger = Logger.new File.new("nice_http_#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.log", 'w')
      elsif @log==:screen
        @logger = Logger.new STDOUT
      elsif @log==:no
        @logger = Logger.new nil
      end
      @logger.level = Logger::INFO
      
      @message_server="(#{self.object_id}):"
  
        log_message="(#{self.object_id}): Http connection created. host:#{@host},  port:#{@port},  ssl:#{@ssl}, mode:#{@mode}, proxy_host: #{@proxy_host.to_s()}, proxy_port: #{@proxy_port.to_s()} "

        @logger.info(log_message)
        @message_server+=" Http connection: "
        if @ssl then
          @message_server+="https://"
        else
          @message_server+="http://"
        end
        @message_server+="#{@host}:#{@port}"
        if @proxy_host.to_s!="" then
          @message_server+=" proxy:#{@proxy_host}:#{@proxy_port}"
        end
        @auto_redirect = auto_redirect
    rescue Exception => stack
      if @logger.nil?
        puts stack
        @logger = Logger.new nil
      else
        @logger.fatal stack
      end
    end

    NiceHttp.active+=1
    NiceHttp.connections.push(self)

  end

      ######################################################
      # Get data from path
      #  input:
      #     1 argument
      #       Hash containing at least key :path
      #     1 argument
      #       path (string)
      #  output:
      #    response -> Hash including at least the symbol keys:
      #       :data = the response data body
      #       :message = plain text response
      #       :code = code response (200=ok,500=wrong...)
      #     *All keys in response are lowercase
      #     data, message and code can also be accessed as attributes like .message .code .data, for example:
      #         resp=@http.get(Requests::Customer.get_profile)
      #         assert resp.code==200
      ######################################################
      def get(arg)
        begin
          path, data, headers_t=manage_request(arg)
          @start_time = Time.now if @start_time.nil?
          if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response) then
            data=""
            if arg[:mock_response].keys.include?(:data) then
              data=arg[:mock_response][:data]
              if data.kind_of?(Hash) #to json
                begin
                  require 'json'
                  data=data.to_json
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
            if path.start_with?("http:") or path.start_with?("https:") then #server included on path problably because of a redirection to a different server
              require 'uri'
              uri = URI.parse(path)
              ssl=false
              ssl=true if path.include?("https:")
  
  
              server="http://"
              server="https://" if path.include?("https:")
              if uri.port!=443 then
                server+="#{uri.host}:#{uri.port}"
              else
                server+="#{uri.host}"
              end
  
              http_redir=nil
              NiceHttp.connections.each {|conn|
                if conn.host == uri.host and conn.port==uri.port then
                  http_redir=conn
                  break
                end
              }
  
              if !http_redir.nil?
                path, data, headers_t=manage_request(arg)
                http_redir.cookies.merge!(@cookies)
                http_redir.headers.merge!(headers_t)
                resp=http_redir.get(path.gsub(server, "")) #todo: remove only the server at the begining in case in query is the server it will be replaced when it should not be
                @response=http_redir.response
              else
                @logger.warn "It seems like the http connection cannot redirect to #{server} because there is no active connection for that server. You need to create previously one."
              end
  
            else
              @start_time_net = Time.now if @start_time_net.nil?
              resp=@http.get(path, headers_t)
              data=resp.body
              manage_response(resp, data)
            end
          rescue Exception => stack
            @logger.warn stack
            @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
            @http.finish()
            @http.start()
            @start_time_net = Time.now if @start_time_net.nil?
            resp=@http.get(path)
            data=resp.body
            manage_response(resp, data)
          end
          if @auto_redirect and @response[:code].to_i>=300 and @response[:code].to_i<400 and @response.include?(:location) then
            if @num_redirects<=30 then
              @num_redirects+=1
              current_server="http"
              current_server+="s" if @ssl==true
              current_server+="://#{@host}"
              location=@response[:location].gsub(current_server, "")
              @logger.info "(#{@num_redirects}) Redirecting NiceHttp to #{location}"
              get(location)
            else
              @logger.fatal "(#{@num_redirects}) Maximum number of redirections for a single request reached. Be sure everything is correct, it seems there is a non ending loop"
              @num_redirects=0
            end
          else
            @num_redirects=0
          end
          return @response
        rescue Exception => stack
          @logger.fatal stack
          return :error
        end
      end

      ######################################################
      # Post data to path
      #  input:
      #     1 argument
      #       Hash containing at least keys :data, :path
      #     3 arguments
      #       path (string)
      #       data (json data for example)
      #       additional_headers (Hash key=>value)
      #  output:
      #    response -> Hash including at least the symbol keys:
      #       :data = the response data body
      #       :message = plain text response
      #       :code = code response (200=ok,500=wrong...)
      #     *All keys in response are lowercase
      #     data, message and code can also be accessed as attributes like .message .code .data, for example:
      #         resp=@http.post(Requests::Customer.update_customer)
      #         assert resp.code==201
      ######################################################
      def post(*arguments)
        begin
          path, data, headers_t=manage_request(*arguments)
          @start_time = Time.now if @start_time.nil?
          if arguments.size>0 and arguments[0].kind_of?(Hash) then
            arg=arguments[0]
            if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response) then
              data=""
              if arg[:mock_response].keys.include?(:data) then
                data=arg[:mock_response][:data]
                if data.kind_of?(Hash) #to json
                  begin
                    require 'json'
                    data=data.to_json
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
            if headers_t["Content-Type"] == "multipart/form-data" then
              require 'net/http/post/multipart'
              headers_t.each {|key, value|
                arguments[0][:data].add_field(key, value) #add to Headers
              }
              resp=@http.request(arguments[0][:data])
            else
              resp=@http.post(path, data, headers_t)
              data=resp.body
            end
          rescue Exception => stack
            @logger.warn stack
            @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
            @http.finish()
            @http.start()
            @start_time_net = Time.now if @start_time_net.nil?
            resp, data=@http.post(path, data, headers_t)
          end
          manage_response(resp, data)
          if @auto_redirect and @response[:code].to_i>=300 and @response[:code].to_i<400 and @response.include?(:location) then
            if @num_redirects<=30 then
              @num_redirects+=1
              current_server="http"
              current_server+="s" if @ssl==true
              current_server+="://#{@host}"
              location=@response[:location].gsub(current_server, "")
              @logger.info "(#{@num_redirects}) Redirecting NiceHttp to #{location}"
              get(location)
            else
              @logger.fatal "(#{@num_redirects}) Maximum number of redirections for a single request reached. Be sure everything is correct, it seems there is a non ending loop"
              @num_redirects=0
            end
          else
            @num_redirects=0
          end
          return @response
        rescue Exception => stack
          @logger.warn stack
          return :error
        end
  
      end


      ######################################################
      # Put data to path
      #  input:
      #     1 argument
      #       Hash containing at least keys :data, :path
      #     3 arguments
      #       path (string)
      #       data (json data for example)
      #       additional_headers (Hash key=>value)
      #  output:
      #    response -> Hash including at least the symbol keys:
      #       :data = the response data body
      #       :message = plain text response
      #       :code = code response (200=ok,500=wrong...)
      #     *All keys in response are lowercase
      #     data, message and code can also be accessed as attributes like .message .code .data, for example:
      #         resp=@http.put(Requests::Customer.remove_phone)
      #         assert resp.code==200
      ######################################################
      def put(*arguments)
        begin
          path, data, headers_t=manage_request(*arguments)
          @start_time = Time.now if @start_time.nil?
          if arguments.size>0 and arguments[0].kind_of?(Hash) then
            arg=arguments[0]
            if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response) then
              data=""
              if arg[:mock_response].keys.include?(:data) then
                data=arg[:mock_response][:data]
                if data.kind_of?(Hash) #to json
                  begin
                    require 'json'
                    data=data.to_json
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
            resp=@http.send_request("PUT", path, data, headers_t)
            data=resp.body
          rescue Exception => stack
            @logger.warn stack
            @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
            @http.finish()
            @http.start()
            @start_time_net = Time.now if @start_time_net.nil?
            resp, data=@http.send_request("PUT", path, data, headers_t)
          end
          manage_response(resp, data)
  
          return @response
        rescue Exception => stack
          @logger.fatal stack, self
          return :error
        end
  
      end

  
      ######################################################
      # Patch data to path
      #  input:
      #     1 argument
      #       Hash containing at least keys :data, :path
      #     3 arguments
      #       path (string)
      #       data (json data for example)
      #       additional_headers (Hash key=>value)
      #  output:
      #    response -> Hash including at least the symbol keys:
      #       :data = the response data body
      #       :message = plain text response
      #       :code = code response (200=ok,500=wrong...)
      #     *All keys in response are lowercase
      #     data, message and code can also be accessed as attributes like .message .code .data, for example:
      #         resp=@http.patch(Requests::Customer.unrelease_account)
      #         assert resp.code==200
      ######################################################
      def patch(*arguments)
        begin
          path, data, headers_t=manage_request(*arguments)
          @start_time = Time.now if @start_time.nil?
          if arguments.size>0 and arguments[0].kind_of?(Hash) then
            arg=arguments[0]
            if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response) then
              data=""
              if arg[:mock_response].keys.include?(:data) then
                data=arg[:mock_response][:data]
                if data.kind_of?(Hash) #to json
                  begin
                    require 'json'
                    data=data.to_json
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
            resp=@http.patch(path, data, headers_t)
            data=resp.body
          rescue Exception => stack
            @logger.warn stack
            @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
            @http.finish()
            @http.start()
            @start_time_net = Time.now if @start_time_net.nil?
            resp, data=@http.patch(path, data, headers_t)
          end
          manage_response(resp, data)
          if @auto_redirect and @response[:code].to_i>=300 and @response[:code].to_i<400 and @response.include?(:location) then
            if @num_redirects<=30 then
              @num_redirects+=1
              current_server="http"
              current_server+="s" if @ssl==true
              current_server+="://#{@host}"
              location=@response[:location].gsub(current_server, "")
              @logger.info "(#{@num_redirects}) Redirecting NiceHttp to #{location}"
              get(location)
            else
              @logger.fatal "(#{@num_redirects}) Maximum number of redirections for a single request reached. Be sure everything is correct, it seems there is a non ending loop"
              @num_redirects=0
            end
          else
            @num_redirects=0
          end
          return @response
        rescue Exception => stack
          @logger.fatal stack
          return :error
        end
  
      end


      ######################################################
      # Delete an existing resource
      #  input:
      #     1 argument
      #       Hash containing at least key :path
      #     1 argument
      #       String giving the path
      #  output:
      #    response -> Hash including at least the symbol keys:
      #       :data = the response data body
      #       :message = plain text response
      #       :code = code response (200=ok,500=wrong...)
      #     *All keys in response are lowercase
      #     data, message and code can also be accessed as attributes like .message .code .data, for example:
      #         resp=@http.delete(Requests::Customer.remove_session)
      #         assert resp.code==204
      ######################################################
      def delete(argument)
        begin
          if argument.kind_of?(String) then
            argument={:path => argument}
          end
          path, data, headers_t=manage_request(argument)
          @start_time = Time.now if @start_time.nil?
          if argument.kind_of?(Hash) then
            arg=argument
            if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response) then
              data=""
              if arg[:mock_response].keys.include?(:data) then
                data=arg[:mock_response][:data]
                if data.kind_of?(Hash) #to json
                  begin
                    require 'json'
                    data=data.to_json
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
            resp=@http.delete(path, headers_t)
            data=resp.body
          rescue Exception => stack
            @logger.warn stack
            @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
            @http.finish()
            @http.start()
            @start_time_net = Time.now if @start_time_net.nil?
            resp, data=@http.delete(path)
          end
          manage_response(resp, data)
  
          return @response
        rescue Exception => stack
          @logger.fatal stack
          return :error
        end
  
      end

      ######################################################
      # Implementation of the http HEAD method.
      # Asks for the response identical to the one that would correspond to a GET request, but without the response body. 
      # This is useful for retrieving meta-information written in response headers, without having to transport the entire content.
      #  input:
      #     1 argument
      #       Hash containing at least key :path
      #     1 argument
      #       String giving the path
      #  output:
      #    response -> Hash including the symbol keys:
      #       :message = plain text response
      #       :code = code response (200=ok,500=wrong...)
      #     *All keys in response are lowercase
      ######################################################
      def head(argument)
        begin
          if argument.kind_of?(String) then
            argument={:path => argument}
          end
          path, data, headers_t=manage_request(argument)
          @start_time = Time.now if @start_time.nil?
          if argument.kind_of?(Hash) then
            arg=argument
            if @use_mocks and arg.kind_of?(Hash) and arg.keys.include?(:mock_response) then
              data=""
              if arg[:mock_response].keys.include?(:data) then
                data=arg[:mock_response][:data]
                if data.kind_of?(Hash) #to json
                  begin
                    require 'json'
                    data=data.to_json
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
            resp=@http.head(path, headers_t)
            data=resp.body
          rescue Exception => stack
            @logger.warn stack
            @logger.warn "The connection seems to be closed in the host machine. Trying to reconnect"
            @http.finish()
            @http.start()
            @start_time_net = Time.now if @start_time_net.nil?
            resp, data=@http.head(path)
          end
          manage_response(resp, data)
          return @response
        rescue Exception => stack
          @logger.fatal stack
          return :error
        end
      end


      ######################################################
      # Close HTTP connection
      ######################################################
      def close
        begin
          pos=0
          found=false
          NiceHttp.connections.each {|conn|
            if conn.object_id == self.object_id then
              found=true
              break
            end
            pos+=1
          }
          if found
            NiceHttp.connections.delete_at(pos)
          end
  
          unless @closed
            if !@http.nil? then
              @http.finish()
              @http=nil
                @logger.info "the HTTP connection was closed: #{@message_server}"
            else
              @http=nil
              @logger.fatal "It was not possible to close the HTTP connection: #{@message_server}"
            end
            @closed=true
          else
            @logger.warn "It was not possible to close the HTTP connection, already closed: #{@message_server}"
          end
        rescue Exception => stack
          @logger.fatal stack
        end
        NiceHttp.active-=1
      end


      ######################################################
      # private method to manage Request
      #   input:
      #     3 args: path, data, headers
      #     1 arg:  Hash containg at least keys :path and :data
      #   output:
      #     path, data, headers
      ######################################################
      def manage_request(*arguments)
        require 'json'
        begin
          content_type_included=false
          path=""
          data=""
  
          @response=Hash.new()
          headers_t=@headers.dup()
          cookies_to_set_str=""
          if arguments.size==3 then
            path=arguments[0]
          elsif arguments.size==1 and arguments[0].kind_of?(Hash) then
            path=arguments[0][:path]
          elsif arguments.size==1 and arguments[0].kind_of?(String) then
            path=arguments[0].to_s()
          end
          @cookies.each {|cookie_path, cookies_hash|
            cookie_path="" if cookie_path=="/"
            path_to_check=path
            if path=="/" or path[-1]!="/" then
              path_to_check+="/"
            end
            if path_to_check.scan(/^#{cookie_path}\//).size>0 then
              cookies_hash.each {|key, value|
                cookies_to_set_str+="#{key}=#{value}; "
              }
            end
          }
          headers_t["Cookie"]=cookies_to_set_str
  
          method_s=caller[0].to_s().scan(/:in `(.*)'/).join
  
          if arguments.size==3 then
            data=arguments[1]
            if arguments[2].kind_of?(Hash) then
              headers_t.merge!(arguments[2])
            end
          elsif arguments.size==1 and arguments[0].kind_of?(Hash) then
            if arguments[0][:data].nil? then
              if arguments[0].keys.include?(:data) then
                data=""
              elsif arguments[0].keys.include?(:data_examples) and 
                arguments[0][:data_examples].kind_of?(Array) then
                data=arguments[0][:data_examples][0] #the first example by default
              else
                data=""
              end
  
            else
              data=arguments[0][:data]
            end
            if arguments[0].include?(:headers) then
              headers_t.merge!(arguments[0][:headers])
            end
  
            if headers_t["Content-Type"].to_s()=="" and headers_t["content-type"].to_s()=="" and 
              headers_t[:"content-type"].to_s()=="" and headers_t[:"Content-Type"].to_s()=="" then
              content_type_included=false
            elsif headers_t["content-type"].to_s()!="" then
              content_type_included=true
              headers_t["Content-Type"]=headers_t["content-type"]
            elsif headers_t[:"content-type"].to_s()!="" then
              content_type_included=true
              headers_t["Content-Type"]=headers_t[:"content-type"]
              headers_t.delete(:"content-type")
            elsif headers_t[:"Content-Type"].to_s()!="" then
              content_type_included=true
              headers_t["Content-Type"]=headers_t[:"Content-Type"]
              headers_t.delete(:"Content-Type")
            elsif headers_t["Content-Type"].to_s()!="" then
              content_type_included=true
            end

            if !content_type_included and data.kind_of?(Hash)
              headers_t['Content-Type'] = 'application/json'
              content_type_included=true
            end
            
            if content_type_included and (!headers_t["Content-Type"][/text\/xml/].nil? or 
              !headers_t["Content-Type"]["application/soap+xml"].nil? or 
              !headers_t["Content-Type"][/application\/jxml/].nil?) then
              if arguments[0].include?(:values) then
                arguments[0][:values].each {|key, value|
                  data=NiceHttpUtils.set_value_xml_tag(key.to_s(), data, value.to_s(), true)
                }
              end
            elsif content_type_included and !headers_t["Content-Type"][/application\/json/].nil? and data.to_s()!="" then
              require 'json'
              if data.kind_of?(String) then
                if arguments[0].include?(:values) then
                  arguments[0][:values].each {|key, value|
                    data.gsub!(/(( *|^)"?#{key.to_s()}"? *: *")(.*)(" *, *$)/, '\1' + value+ '\4') # "key":"value", or key:"value",
                    data.gsub!(/(( *|^)"?#{key.to_s()}"? *: *")(.*)(" *$)/, '\1' + value+ '\4') # "key":"value" or key:"value"
                    data.gsub!(/(( *|^)"?#{key.to_s()}"? *: *[^"])([^"].*)([^"] *, *$)/, '\1' + value+ '\4') # "key":456, or key:456,
                    data.gsub!(/(( *|^)"?#{key.to_s()}"? *: *[^"])([^"].*)([^"] * *$)/, '\1' + value+ '\4') # "key":456 or key:456
                  }
                end
              elsif data.kind_of?(Hash) then
                data_n=Hash.new()
                data.each {|key, value|
                  data_n[key.to_s()]=value
                }
                if arguments[0].include?(:values) then
                  #req[:values][:loginName] or req[:values]["loginName"]
                  new_values_hash=Hash.new()
                  arguments[0][:values].each {|kv, vv|
                    if data_n.keys.include?(kv.to_s()) then
                      new_values_hash[kv.to_s()]=vv
                    end
                  }
                  data_n.merge!(new_values_hash)
                end
                data=data_n.to_json()
              elsif data.kind_of?(Array) then
                data_arr=Array.new()
                data.each_with_index {|row, indx|
                  unless row.kind_of?(Hash) then
                    @logger.fatal("Wrong format on request application/json, be sure is a Hash, Array of Hashes or JSON string")
                    return :error, :error, :error
                  end
                  data_n=Hash.new()
                  row.each {|key, value|
                    data_n[key.to_s()]=value
                  }
                  if arguments[0].include?(:values) then
                    #req[:values][:loginName] or req[:values]["loginName"]
                    new_values_hash=Hash.new()
                    if arguments[0][:values].kind_of?(Hash) then #values[:mykey][3]
                      arguments[0][:values].each {|kv, vv|
                        if data_n.keys.include?(kv.to_s()) and !vv[indx].nil? then
                          new_values_hash[kv.to_s()]=vv[indx]
                        end
                      }
                    elsif arguments[0][:values].kind_of?(Array) then #values[5][:mykey]
                      if !arguments[0][:values][indx].nil? then
                        arguments[0][:values][indx].each {|kv, vv|
                          if data_n.keys.include?(kv.to_s()) then
                            new_values_hash[kv.to_s()]=vv
                          end
                        }
                      end
                    else
                      @logger.fatal("Wrong format on request application/json when supplying values, the data is an array of Hashes but the values supplied are not")
                      return :error, :error, :error
                    end
                    data_n.merge!(new_values_hash)
                  end
                  data_arr.push(data_n)
                }
                data=data_arr.to_json()
              else
                @logger.fatal("Wrong format on request application/json, be sure is a Hash, Array of Hashes or JSON string")
                return :error, :error, :error
              end
            elsif content_type_included and arguments[0].include?(:values) then
              if arguments[0][:values].kind_of?(Hash) and arguments[0][:values].keys.size>0 then
                if !headers_t.nil? and headers_t.kind_of?(Hash) and headers_t["Content-Type"]!="application/x-www-form-urlencoded" and headers_t["content-type"]!="application/x-www-form-urlencoded" then
                  @logger.warn(":values key given without a valid content-type or data for request. No values modified on the request")
                end
              end
            end
          elsif arguments.size==1 and arguments[0].kind_of?(String) then
            #path=arguments[0].to_s()
            data=""
          else
            @logger.fatal("Invalid number of arguments or wrong arguments in #{method_s}")
            return :error, :error, :error
          end
          if headers_t.keys.include?("Content-Type") and !headers_t["Content-Type"]["multipart/form-data"].nil? and headers_t["Content-Type"]!=["multipart/form-data"] then #only for the case raw multipart request
            encoding="UTF-8"
            data_s=""
          else
            encoding=data.to_s().scan(/encoding='(.*)'/i).join
            if encoding.to_s()=="" then
              encoding=data.to_s().scan(/charset='(.*)'/i).join
            end
            if encoding.to_s()=="" and headers_t.include?("Content-Type") then
              encoding=headers_t["Content-Type"].scan(/charset='?(.*)'?/i).join
              if encoding.to_s()=="" then
                encoding=headers_t["Content-Type"].scan(/encoding='?(.*)'?/i).join
              end
            end
  
            begin
              data_s=JSON.pretty_generate(JSON.parse(data))
            rescue
              data_s=data
            end
            data_s=data_s.to_s().gsub("<", "&lt;")
          end
          if headers_t.keys.include?("Accept-Encoding")
            headers_t["Accept-Encoding"].gsub!("gzip","")#removed so the response is in plain text
          end
  
          headers_ts=""
          headers_t.each {|key, val| headers_ts+=key.to_s + ":" + val.to_s() + ", "}
          message="#{method_s} REQUEST: \npath= " + path.to_s() + "\n"
          message+="headers= " + headers_ts.to_s() + "\n"
          message+="data= " + data_s.to_s() + "\n"
          message=@message_server+"\n"+message
          if path.to_s().scan(/^https?:\/\//).size>0 and path.to_s().scan(/^https?:\/\/#{@host}/).size==0 then
            # the path is for another server than the current
          else
            NiceHttp.last_request=message
            @logger.info(message)
          end
  
          if data.to_s()!="" and encoding.to_s().upcase!="UTF-8" and encoding!="" then
            data=data.to_s().encode(encoding, "UTF-8")
          end
          return path, data, headers_t
        rescue Exception => stack
          @logger.fatal(stack)
          @logger.fatal("manage_request Error on method #{method_s} . path:#{path.to_s()}. data:#{data.to_s()}. headers:#{headers_t.to_s()}")
          return :error
        end
      end

      ######################################################
      # private method to manage Response
      #   input:
      #     resp
      #     data
      #   output:
      #     @response updated
      ######################################################
      def manage_response(resp, data)
        require 'json'
        begin
          if @start_time.kind_of?(Time)
            @response[:time_elapsed_total]=Time.now-@start_time
            @start_time = nil
          else
            @response[:time_elapsed_total]=nil
          end
          if @start_time_net.kind_of?(Time)
            @response[:time_elapsed]=Time.now-@start_time_net
            @start_time_net = nil
          else
            @response[:time_elapsed]=nil
          end
          begin
            # this is to be able to access all keys as symbols
            new_resp=Hash.new()
            resp.each {|key, value|
              if key.kind_of?(String) then
                new_resp[key.to_sym]=value
              end
            }
            new_resp.each {|key, value|
              resp[key]=value
            }
          rescue
          end
          #for mock_responses to be able to add outside of the header like content-type for example
          if resp.kind_of?(Hash) and !resp.has_key?(:header) then
            resp[:header]={}
          end
          if resp.kind_of?(Hash)
            resp.each {|k, v|
              if k!=:code and k!=:message and k!=:data and k!=:'set-cookie' and k!=:header
                resp[:header][k]=v
              end
            }
            resp[:header].each {|k, v|
              resp.delete(k) if resp.has_key?(k)
            }
          end
  
          method_s=caller[0].to_s().scan(/:in `(.*)'/).join
          if resp.header.kind_of?(Hash) and (resp.header["content-type"].to_s()=="application/x-deflate" or resp.header[:"content-type"].to_s()=="application/x-deflate") then
            data=Zlib::Inflate.inflate(data)
          end
          encoding_response=""
          if resp.header.kind_of?(Hash) and (resp.header["content-type"].to_s()!="" or resp.header[:"content-type"].to_s()!="") then
            encoding_response=resp.header["content-type"].scan(/;charset=(.*)/i).join if resp.header.has_key?("content-type")
            encoding_response=resp.header[:"content-type"].scan(/;charset=(.*)/i).join if resp.header.has_key?(:"content-type")
          end
          if encoding_response.to_s()=="" then
            encoding_response="UTF-8"
          end
  
          if encoding_response.to_s()!="" and encoding_response.to_s().upcase!="UTF-8" then
            data.encode!("UTF-8", encoding_response.to_s())
          end
          if encoding_response!="" and encoding_response.to_s().upcase!="UTF-8" then
            @response[:message]=resp.message.to_s().encode("UTF-8", encoding_response.to_s())
            #todo: response data in here for example is convert into string, verify if that is correct or needs to maintain the original data type (hash, array...)
            resp.each {|key, val| @response[key]=val.to_s().encode("UTF-8", encoding_response.to_s())}
          else
            @response[:message]=resp.message
            resp.each {|key, val| @response[key]=val}
          end
          if !defined?(Net::HTTP::Post::Multipart) or (defined?(Net::HTTP::Post::Multipart) and !data.kind_of?(Net::HTTP::Post::Multipart))
            @response[:data]=data
          else
            @response[:data]=""
          end
  
          @response[:code]=resp.code
  
          unless @response.nil? then
            message="\nRESPONSE: \n" + @response[:code].to_s()+ ":" + @response[:message].to_s()
            if @debug then
              NiceHttp.last_response=message
              @response.each {|key, value|
                if value.to_s()!="" then
                  value_orig=value
                  if key.kind_of?(Symbol) then
                    if key==:code or key==:data or key==:header or key==:message then
                      if key==:data then
                        begin
                          JSON.parse(value_orig)
                          data_s=JSON.pretty_generate(JSON.parse(value_orig))
                        rescue
                          data_s=value_orig
                        end
                        NiceHttp.last_response+="\nresponse." + key.to_s() + " = '" + data_s.gsub("<", "&lt;") + "'\n"
                        if value_orig != value then
                          message+="\nresponse." + key.to_s() + " = '" + value.gsub("<", "&lt;") + "'\n"
                        else
                          message+="\nresponse." + key.to_s() + " = '" + data_s.gsub("<", "&lt;") + "'\n"
                        end
                      else
                        NiceHttp.last_response+="\nresponse." + key.to_s() + " = '" + value.to_s().gsub("<", "&lt;") + "'"
                        message+="\nresponse." + key.to_s() + " = '" + value.to_s().gsub("<", "&lt;") + "'"
                      end
                    else
                      NiceHttp.last_response+="\nresponse[:" + key.to_s() + "] = '" + value.to_s().gsub("<", "&lt;") + "'"
                      message+="\nresponse[:" + key.to_s() + "] = '" + value.to_s().gsub("<", "&lt;") + "'"
                    end
                  elsif !@response.include?(key.to_sym)
                    NiceHttp.last_response+="\nresponse['" + key.to_s() + "'] = '" + value.to_s().gsub("<", "&lt;") + "'"
                    message+="\nresponse['" + key.to_s() + "'] = '" + value.to_s().gsub("<", "&lt;") + "'"
                  end
                end
              }
  
            end
            @logger.info message
            if @response.kind_of?(Hash) then
              if @response.keys.include?(:requestid) then
                @headers["requestId"]=@response[:requestid]
                NiceHttp.request_id=@response[:requestid]
                @logger.info "requestId was found on the response header and it has been added to the headers for the next request"
              end
            end
          end
  
          if resp[:'set-cookie'].to_s()!="" then
            if resp.kind_of?(Hash) then #mock_response
              cookies_to_set=resp[:'set-cookie'].to_s().split(", ")
            else #Net::Http
              cookies_to_set=resp.get_fields('set-cookie')
            end
            cookies_to_set.each {|cookie|
              cookie_pair=cookie.split('; ')[0].split("=")
              cookie_path=cookie.scan(/; path=([^;]+)/i).join
              @cookies[cookie_path]=Hash.new() unless @cookies.keys.include?(cookie_path)
              @cookies[cookie_path][cookie_pair[0]]=cookie_pair[1]
            }
  
              @logger.info "set-cookie added to Cookie header as required"
  
              if @headers.has_key?("X-CSRFToken") then
                csrftoken=resp[:"set-cookie"].to_s().scan(/csrftoken=([\da-z]+);/).join
                if csrftoken.to_s()!="" then
                  @headers["X-CSRFToken"]=csrftoken
                  @logger.info "X-CSRFToken exists on headers and has been overwritten"
                end
              else
                csrftoken=resp[:"set-cookie"].to_s().scan(/csrftoken=([\da-z]+);/).join
                if csrftoken.to_s()!="" then
                  @headers["X-CSRFToken"]=csrftoken
                  @logger.info "X-CSRFToken added to header as required"
                end
  
              end
          end
  
        rescue Exception => stack
          @logger.fatal stack
          @logger.fatal "manage_response Error on method #{method_s} "
        end
      end
      
      private :manage_request, :manage_response
end

