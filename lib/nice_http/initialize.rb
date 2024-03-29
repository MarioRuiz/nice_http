class NiceHttp
  ######################################################
  # Creates a new http connection.
  #
  # @param args [] If no parameter supplied, by default will access how is setup on defaults
  # @example
  #   http = NiceHttp.new()
  # @param args [String]. The url to create the connection.
  # @example
  #   http = NiceHttp.new("https://www.example.com")
  # @example
  #   http = NiceHttp.new("example.com:8999")
  # @example
  #   http = NiceHttp.new("localhost:8322")
  # @param args [Hash] containing these possible keys:
  #             host -- example.com. (default blank screen)
  #             port -- port for the connection. 80 (default)
  #             ssl -- true, false (default)
  #             timeout -- integer or nil (default)
  #             headers -- hash with the headers
  #             values_for -- hash with the values_for
  #             debug -- true, false (default)
  #             log_path -- string with path for the logs, empty string (default)
  #             log -- :no, :screen, :file, :fix_file (default).
  #             log_headers -- :all, :none, :partial (default).
  #                 A string with a path can be supplied.
  #                 If :fix_file: nice_http.log
  #                 In case :file it will be generated a log file with name: nice_http_YY-mm-dd-HHMMSS.log
  #             proxy_host
  #             proxy_port
  #             async_wait_seconds -- integer (default 0)
  #             async_header -- string (default 'location')
  #             async_completed -- string (default empty string)
  #             async_resource -- string (default empty string)
  #             async_status -- string (default empty string)
  # @example
  #   http2 = NiceHttp.new( host: "reqres.in", port: 443, ssl: true )
  # @example
  #   my_server = {host: "example.com",
  #                port: 80,
  #                headers: {"api-key": "zdDDdjkck"}
  #               }
  #   http3 = NiceHttp.new my_server
  ######################################################
  def initialize(args = {})
    require "net/http"
    require "net/https"
    @host = self.class.host
    @port = self.class.port
    @prepath = ""
    @ssl = self.class.ssl
    @timeout = self.class.timeout
    @headers = self.class.headers.dup
    @values_for = self.class.values_for.dup
    @debug = self.class.debug
    @log = self.class.log
    @log_path = self.class.log_path
    @log_headers = self.class.log_headers
    @proxy_host = self.class.proxy_host
    @proxy_port = self.class.proxy_port
    @use_mocks = self.class.use_mocks
    @auto_redirect = false #set it up at the end of initialize
    auto_redirect = self.class.auto_redirect
    @num_redirects = 0
    @create_stats = self.class.create_stats
    @capture = self.class.capture
    @async_wait_seconds = self.class.async_wait_seconds
    @async_header = self.class.async_header
    @async_completed = self.class.async_completed
    @async_resource = self.class.async_resource
    @async_status = self.class.async_status
    
    #todo: set only the cookies for the current domain
    #key: path, value: hash with key is the name of the cookie and value the value
    # we set the default value for non existing keys to empty Hash {} so in case of merge there is no problem
    @cookies = Hash.new { |h, k| h[k] = {} }

    if args.is_a?(String) # 'http://www.example.com'
      uri = URI.parse(args)
      @host = uri.host unless uri.host.nil?
      @port = uri.port unless uri.port.nil?
      @ssl = true if !uri.scheme.nil? && (uri.scheme == "https")
      @prepath = uri.path unless uri.path == "/"
    elsif args.is_a?(Hash) && !args.keys.empty?
      @host = args[:host] if args.keys.include?(:host)
      @port = args[:port] if args.keys.include?(:port)
      @ssl = args[:ssl] if args.keys.include?(:ssl)
      @timeout = args[:timeout] if args.keys.include?(:timeout)
      @headers = args[:headers].dup if args.keys.include?(:headers)
      @values_for = args[:values_for].dup if args.keys.include?(:values_for)
      @debug = args[:debug] if args.keys.include?(:debug)
      @log = args[:log] if args.keys.include?(:log)
      @log_path = args[:log_path] if args.keys.include?(:log_path)
      @log_headers = args[:log_headers] if args.keys.include?(:log_headers)
      @proxy_host = args[:proxy_host] if args.keys.include?(:proxy_host)
      @proxy_port = args[:proxy_port] if args.keys.include?(:proxy_port)
      @use_mocks = args[:use_mocks] if args.keys.include?(:use_mocks)
      auto_redirect = args[:auto_redirect] if args.keys.include?(:auto_redirect)
      @async_wait_seconds = args[:async_wait_seconds] if args.keys.include?(:async_wait_seconds)
      @async_header = args[:async_header] if args.keys.include?(:async_header)
      @async_completed = args[:async_completed] if args.keys.include?(:async_completed)
      @async_resource = args[:async_resource] if args.keys.include?(:async_resource)
      @async_status = args[:async_status] if args.keys.include?(:async_status)      
    end

    log_filename = ""
    if @log.kind_of?(String) or @log == :fix_file or @log == :file or @log == :file_run
      if @log.kind_of?(String)
        log_filename = @log.dup
        unless log_filename.start_with?(".")
          if caller.first.start_with?(Dir.pwd)
            folder = File.dirname(caller.first.scan(/(.+):\d/).join)
          else
            folder = File.dirname("#{Dir.pwd}/#{caller.first.scan(/(.+):\d/).join}")
          end
          folder += "/" unless log_filename.start_with?("/") or log_filename.match?(/^\w+:/)
          log_filename = folder + log_filename
        end
        require "fileutils"
        FileUtils.mkdir_p File.dirname(log_filename)
        unless Dir.exist?(File.dirname(log_filename))
          @logger = Logger.new nil
          raise InfoMissing, :log, "Wrong directory specified for logs.\n"
        end
      elsif @log == :fix_file
        log_filename = "nice_http.log"
      elsif @log == :file
        log_filename = "nice_http_#{Time.now.strftime("%Y-%m-%d-%H%M%S")}.log"
      elsif @log == :file_run
        log_filename = "#{caller.first.scan(/(.+):\d/).join}.log"
      end
      if Thread.current.name.to_s != ""
        log_filename.gsub!(/\.log$/, "_#{Thread.current.name}.log")
      end
      unless @log_path.to_s == ""
        log_filename.gsub!(Dir.pwd, ".")
        dpath = @log_path.split("/")
        dfile = log_filename.split("/")
        log_filenamepath = ""
        dfile.each_with_index do |d, i|
          if d == dpath[i]
            log_filenamepath << "#{d}/"
          else
            log_filename = @log_path + "#{log_filename.gsub(/^#{log_filenamepath}/, "")}"
            break
          end
        end
        log_filename = "./#{log_filename}" unless log_filename[0..1] == "./"
        log_filename = ".#{log_filename}" unless log_filename[0] == "."

        unless File.exist?(log_filename)
          require "fileutils"
          FileUtils.mkdir_p(File.dirname(log_filename))
        end
      end

      if self.class.log_files.key?(log_filename) and File.exist?(log_filename)
        @logger = self.class.log_files[log_filename]
      else
        begin
          f = File.new(log_filename, "w")
          f.sync = true
          @logger = Logger.new f
        rescue Exception => stack
          @logger = Logger.new nil
          raise InfoMissing, :log
        end
        self.class.log_files[log_filename] = @logger
      end
    elsif @log == :screen
      @logger = Logger.new STDOUT
    elsif @log == :no
      @logger = Logger.new nil
    else
      raise InfoMissing, :log
    end
    @log_file = log_filename
    @logger.level = Logger::INFO    

    if @host.to_s != "" and (@host.start_with?("http:") or @host.start_with?("https:"))
      uri = URI.parse(@host)
      @host = uri.host unless uri.host.nil?
      @port = uri.port unless uri.port.nil?
      @ssl = true if !uri.scheme.nil? && (uri.scheme == "https")
      @prepath = uri.path unless uri.path == "/"
    end
    raise InfoMissing, :port if @port.to_s == ""
    raise InfoMissing, :host if @host.to_s == ""
    raise InfoMissing, :ssl unless @ssl.is_a?(TrueClass) or @ssl.is_a?(FalseClass)
    raise InfoMissing, :timeout unless @timeout.is_a?(Integer) or @timeout.nil?
    raise InfoMissing, :debug unless @debug.is_a?(TrueClass) or @debug.is_a?(FalseClass)
    raise InfoMissing, :auto_redirect unless auto_redirect.is_a?(TrueClass) or auto_redirect.is_a?(FalseClass)
    raise InfoMissing, :use_mocks unless @use_mocks.is_a?(TrueClass) or @use_mocks.is_a?(FalseClass)
    raise InfoMissing, :headers unless @headers.is_a?(Hash)
    raise InfoMissing, :values_for unless @values_for.is_a?(Hash)
    raise InfoMissing, :log_headers unless [:all, :none, :partial].include?(@log_headers)
    raise InfoMissing, :async_wait_seconds unless @async_wait_seconds.is_a?(Integer) or @async_wait_seconds.nil?
    raise InfoMissing, :async_header unless @async_header.is_a?(String) or @async_header.nil?
    raise InfoMissing, :async_completed unless @async_completed.is_a?(String) or @async_completed.nil?
    raise InfoMissing, :async_resource unless @async_resource.is_a?(String) or @async_resource.nil?
    raise InfoMissing, :async_status unless @async_status.is_a?(String) or @async_status.nil?
    
    begin
      if !@proxy_host.nil? && !@proxy_port.nil?
        @http = Net::HTTP::Proxy(@proxy_host, @proxy_port).new(@host, @port)
        @http.use_ssl = @ssl
        @http.set_debug_output $stderr if @debug
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        unless @timeout.nil?
          @http.open_timeout = @timeout
          @http.read_timeout = @timeout
        end
        @http.start
      else
        @http = Net::HTTP.new(@host, @port)
        @http.use_ssl = @ssl
        @http.set_debug_output $stderr if @debug
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        unless @timeout.nil?
          @http.open_timeout = @timeout
          @http.read_timeout = @timeout
        end
        @http.start
      end

      @message_server = "(#{self.object_id}):"

      log_message = "(#{self.object_id}): Http connection created. host:#{@host},  port:#{@port},  ssl:#{@ssl}, timeout:#{@timeout}, mode:#{@mode}, proxy_host: #{@proxy_host.to_s()}, proxy_port: #{@proxy_port.to_s()} "

      @logger.info(log_message)
      @message_server += " Http connection: "
      if @ssl
        @message_server += "https://"
      else
        @message_server += "http://"
      end
      @message_server += "#{@host}:#{@port}"
      if @proxy_host.to_s != ""
        @message_server += " proxy:#{@proxy_host}:#{@proxy_port}"
      end
      @auto_redirect = auto_redirect
      # for the case we have headers following nice_hash implementation
      @headers_orig = @headers.dup
      @headers = @headers.generate

      self.class.active += 1
      self.class.connections.push(self)
    rescue Exception => stack
      puts stack
      @logger.fatal stack
      raise stack
    end
  end
end
