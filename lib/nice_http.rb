require "logger"
require "nice_hash"
require_relative "nice_http/utils"
require_relative "nice_http/manage_request"
require_relative "nice_http/manage_response"
require_relative "nice_http/http_methods"

######################################################
# Attributes you can access using NiceHttp.the_attribute:  
#   :host, :port, :ssl, :headers, :debug, :log, :log_headers, :proxy_host, :proxy_port,  
#   :last_request, :last_response, :request_id, :use_mocks, :connections,  
#   :active, :auto_redirect, :values_for, :create_stats, :stats, :capture, :captured
#
# @attr [String] host The host to be accessed
# @attr [Integer] port The port number
# @attr [Boolean] ssl If you use ssl or not
# @attr [Hash] headers Contains the headers you will be using on your connection
# @attr [Boolean] debug In case true shows all the details of the communication with the host
# @attr [String] log_path The path where the logs will be stored. By default empty string.
# @attr [String, Symbol] log :fix_file, :no, :screen, :file, "path and file name".  
#   :fix_file, will log the communication on nice_http.log. (default).  
#   :no, will not generate any logs.  
#   :screen, will print the logs on the screen.  
#   :file, will be generated a log file with name: nice_http_YY-mm-dd-HHMMSS.log.  
#   :file_run, will generate a log file with the name where the object was created and extension .log, fex: myfile.rb.log  
#   String the path and file name where the logs will be stored.
# @attr [Symbol] log_headers. :all, :partial, :none (default :all) If :all will log all the headers. If :partial will log the last 10 characters. If :none no headers.
# @attr [String] proxy_host the proxy host to be used
# @attr [Integer] proxy_port the proxy port to be used
# @attr [String] last_request The last request with all the content sent
# @attr [String] last_response Only in case :debug is true, the last response with all the content
# @attr [String] request_id If the response includes a requestId, will be stored here
# @attr [Boolean] use_mocks If true, in case the request hash includes a :mock_response key, it will be used as the response instead
# @attr [Array] connections It will include all the active connections (NiceHttp instances)
# @attr [Integer] active Number of active connections
# @attr [Boolean] auto_redirect If true, NiceHttp will take care of the auto redirections when required by the responses
# @attr [Hash] response Contains the full response hash
# @attr [Integer] num_redirects Number of consecutive redirections managed
# @attr [Hash] headers The updated headers of the communication
# @attr [Hash] cookies Cookies set. The key is the path (String) where cookies are set and the value a Hash with pairs of cookie keys and values, example:  
#   { '/' => { "cfid" => "d95adfas2550255", "amddom.settings" => "doom" } }
# @attr [Logger] logger An instance of the Logger class where logs will be stored. You can access on anytime to store specific data, for example:  
#   my_http.logger.info "add this to the log file"  
#   @see https://ruby-doc.org/stdlib-2.5.0/libdoc/logger/rdoc/Logger.html
# @attr [Hash] values_for The default values to set on the data in case not specified others
# @attr [Boolean] create_stats If true, NiceHttp will create stats of the http communication and store them on NiceHttp.stats hash
# @attr [Hash] stats It contains detailed stats of the http communication
# @attr [Boolean] capture If true, NiceHttp will store all requests and responses on NiceHttp.captured as strings
# @attr [Array] captured It contains all the http requests and responses if NiceHttp.capture is set to true
######################################################
class NiceHttp
  include NiceHttpManageRequest
  include NiceHttpManageResponse
  include NiceHttpHttpMethods

  Error = Class.new StandardError

  InfoMissing = Class.new Error do
    attr_reader :attribute

    def initialize(attribute, message = "")
      @attribute = attribute
      message += "It was not possible to create the http connection!!!\n"
      message += "Wrong #{attribute}. "
      message += "Remember to supply http:// or https:// in case you specify an url to create the http connection, for example:\n"
      message += "http = NiceHttp.new('http://example.com')"
      super message
    end
  end

  class << self
    attr_accessor :host, :port, :ssl, :headers, :debug, :log_path, :log, :proxy_host, :proxy_port, :log_headers,
                  :last_request, :last_response, :request_id, :use_mocks, :connections,
                  :active, :auto_redirect, :log_files, :values_for, :create_stats, :stats, :capture, :captured
  end

  at_exit do
    if self.create_stats
      self.save_stats
    end
  end

  ######################################################
  # to reset to the original defaults
  ######################################################
  def self.reset!
    @host = nil
    @port = 80
    @ssl = false
    @headers = {}
    @values_for = {}
    @debug = false
    @log = :fix_file
    @log_path = ''
    @log_headers = :all
    @proxy_host = nil
    @proxy_port = nil
    @last_request = nil
    @last_response = nil
    @request_id = ""
    @use_mocks = false
    @connections = []
    @active = 0
    @auto_redirect = true
    @log_files = {}
    @create_stats = false
    @stats = {
      all: {
        num_requests: 0,
        started: nil,
        finished: nil,
        real_time_elapsed: 0,
        time_elapsed: {
          total: 0,
          maximum: 0,
          minimum: 1000000,
          average: 0,
        },
        method: {},
      },
      path: {},
      name: {},
    }
    @capture = false
    @captured = []
  end
  reset!

  ######################################################
  # If inheriting from NiceHttp class
  ######################################################
  def self.inherited(subclass)
    subclass.reset!
  end

  attr_reader :host, :port, :ssl, :debug, :log, :log_path, :proxy_host, :proxy_port, :response, :num_redirects
  attr_accessor :headers, :cookies, :use_mocks, :auto_redirect, :logger, :values_for, :log_headers

  ######################################################
  # Change the default values for NiceHttp supplying a Hash
  #
  # @param par [Hash] keys: :host, :port, :ssl, :headers, :debug, :log, :log_path, :proxy_host, :proxy_port, :use_mocks, :auto_redirect, :values_for, :create_stats, :log_headers, :capture
  ######################################################
  def self.defaults=(par = {})
    @host = par[:host] if par.key?(:host)
    @port = par[:port] if par.key?(:port)
    @ssl = par[:ssl] if par.key?(:ssl)
    @headers = par[:headers].dup if par.key?(:headers)
    @values_for = par[:values_for].dup if par.key?(:values_for)
    @debug = par[:debug] if par.key?(:debug)
    @log_path = par[:log_path] if par.key?(:log_path)
    @log = par[:log] if par.key?(:log)
    @log_headers = par[:log_headers] if par.key?(:log_headers)
    @proxy_host = par[:proxy_host] if par.key?(:proxy_host)
    @proxy_port = par[:proxy_port] if par.key?(:proxy_port)
    @use_mocks = par[:use_mocks] if par.key?(:use_mocks)
    @auto_redirect = par[:auto_redirect] if par.key?(:auto_redirect)
    @create_stats = par[:create_stats] if par.key?(:create_stats)
    @capture = par[:capture] if par.key?(:capture)
  end

  ######################################################
  # To add specific stats  
  # The stats will be added to NiceHttp.stats[:specific]
  #
  # @param name [Symbol] name to group your specific stats
  # @param state [Symbol] state of the name supplied to group your specific stats
  # @param started [Time] when the process you want the stats started
  # @param finished [Time] when the process you want the stats finished
  # @param item [Object] (Optional) The item to be added to :items key to store all items in an array
  #
  # @example
  #   started = Time.now
  #   @http.send_request Requests::Customer.add_customer
  #   30.times do
  #      resp = @http.get(Requests::Customer.get_customer)
  #      break if resp.code == 200
  #      sleep 0.5
  #   end
  #   NiceHttp.add_stats(:customer, :create, started, Time.now)
  ######################################################
  def self.add_stats(name, state, started, finished, item = nil)
    self.stats[:specific] ||= {}
    self.stats[:specific][name] ||= { num: 0, started: started, finished: started, real_time_elapsed: 0, time_elapsed: { total: 0, maximum: 0, minimum: 100000, average: 0 } }
    self.stats[:specific][name][:num] += 1

    if started < self.stats[:specific][name][:finished]
      self.stats[:specific][name][:real_time_elapsed] += (finished - self.stats[:specific][name][:finished])
    else
      self.stats[:specific][name][:real_time_elapsed] += (finished - started)
    end
    self.stats[:specific][name][:finished] = finished

    time_elapsed = self.stats[:specific][name][:time_elapsed]
    time_elapsed[:total] += finished - started
    if time_elapsed[:maximum] < (finished - started)
      time_elapsed[:maximum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_maximum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_maximum] = Thread.current.name
      end
    end
    if time_elapsed[:minimum] > (finished - started)
      time_elapsed[:minimum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_minimum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_minimum] = Thread.current.name
      end
    end
    time_elapsed[:average] = time_elapsed[:total] / self.stats[:specific][name][:num]

    self.stats[:specific][name][state] ||= { num: 0, started: started, finished: started, real_time_elapsed: 0, time_elapsed: { total: 0, maximum: 0, minimum: 1000, average: 0 }, items: [] }
    self.stats[:specific][name][state][:num] += 1
    if started < self.stats[:specific][name][state][:finished]
      self.stats[:specific][name][state][:real_time_elapsed] += (finished - self.stats[:specific][name][state][:finished])
    else
      self.stats[:specific][name][state][:real_time_elapsed] += (finished - started)
    end

    self.stats[:specific][name][state][:finished] = finished

    self.stats[:specific][name][state][:items] << item unless item.nil? or self.stats[:specific][name][state][:items].include?(item)
    time_elapsed = self.stats[:specific][name][state][:time_elapsed]
    time_elapsed[:total] += finished - started
    if time_elapsed[:maximum] < (finished - started)
      time_elapsed[:maximum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_maximum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_maximum] = Thread.current.name
      end
    end
    if time_elapsed[:minimum] > (finished - started)
      time_elapsed[:minimum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_minimum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_minimum] = Thread.current.name
      end
    end
    time_elapsed[:average] = time_elapsed[:total] / self.stats[:specific][name][state][:num]
  end

  ######################################################
  # It will save the NiceHttp.stats on different files, each key of the hash in a different file.
  #
  # @param file_name [String] path and file name to be used to store the stats.  
  #   In case no one supplied it will be used the value in NiceHttp.log and it will be saved on YAML format.  
  #   In case extension is .yaml will be saved on YAML format.  
  #   In case extension is .json will be saved on JSON format.
  #
  # @example
  #    NiceHttp.save_stats
  #    NiceHttp.save_stats('./stats/my_stats.yaml')
  #    NiceHttp.save_stats('./stats/my_stats.json')
  ######################################################
  def self.save_stats(file_name = "")
    if file_name == ""
      if self.log.is_a?(String)
        file_name = self.log
      else
        file_name = "./#{self.log_path}nice_http.log"
      end
    end
    require "fileutils"
    FileUtils.mkdir_p File.dirname(file_name)
    if file_name.match?(/\.json$/)
      require "json"
      self.stats.keys.each do |key|
        File.open("#{file_name.gsub(/.json$/, "_stats_")}#{key}.json", "w") { |file| file.write(self.stats[key].to_json) }
      end
    else
      require "yaml"
      self.stats.keys.each do |key|
        File.open("#{file_name.gsub(/.\w+$/, "_stats_")}#{key}.yaml", "w") { |file| file.write(self.stats[key].to_yaml) }
      end
    end
  end

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

    #todo: set only the cookies for the current domain
    #key: path, value: hash with key is the name of the cookie and value the value
    # we set the default value for non existing keys to empty Hash {} so in case of merge there is no problem
    @cookies = Hash.new { |h, k| h[k] = {} }

    if args.is_a?(String)
      uri = URI.parse(args)
      @host = uri.host unless uri.host.nil?
      @port = uri.port unless uri.port.nil?
      @ssl = true if !uri.scheme.nil? && (uri.scheme == "https")
      @prepath = uri.path unless uri.path == "/"
    elsif args.is_a?(Hash) && !args.keys.empty?
      @host = args[:host] if args.keys.include?(:host)
      @port = args[:port] if args.keys.include?(:port)
      @ssl = args[:ssl] if args.keys.include?(:ssl)
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
      unless @log_path.to_s == ''
        log_filename.gsub!(Dir.pwd,'.')
        dpath = @log_path.split("/")
        dfile = log_filename.split("/")
        log_filenamepath = ''
        dfile.each_with_index do |d,i|
          if d==dpath[i]
            log_filenamepath<<"#{d}/"
          else
            log_filename = @log_path + "#{log_filename.gsub(/^#{log_filenamepath}/,'')}"
            break
          end
        end
        log_filename = "./#{log_filename}" unless log_filename[0..1]=='./'
        log_filename = ".#{log_filename}" unless log_filename[0]=='.'

        unless File.exist?(log_filename)
          require 'fileutils'
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
    raise InfoMissing, :debug unless @debug.is_a?(TrueClass) or @debug.is_a?(FalseClass)
    raise InfoMissing, :auto_redirect unless auto_redirect.is_a?(TrueClass) or auto_redirect.is_a?(FalseClass)
    raise InfoMissing, :use_mocks unless @use_mocks.is_a?(TrueClass) or @use_mocks.is_a?(FalseClass)
    raise InfoMissing, :headers unless @headers.is_a?(Hash)
    raise InfoMissing, :values_for unless @values_for.is_a?(Hash)
    raise InfoMissing, :log_headers unless [:all, :none, :partial].include?(@log_headers)

    begin
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

      @message_server = "(#{self.object_id}):"

      log_message = "(#{self.object_id}): Http connection created. host:#{@host},  port:#{@port},  ssl:#{@ssl}, mode:#{@mode}, proxy_host: #{@proxy_host.to_s()}, proxy_port: #{@proxy_port.to_s()} "

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
    end
  end

  ######################################################
  # Close HTTP connection
  ######################################################
  def close
    begin
      pos = 0
      found = false
      self.class.connections.each { |conn|
        if conn.object_id == self.object_id
          found = true
          break
        else
          pos += 1
        end
      }
      if found
        self.class.connections.delete_at(pos)
      end

      unless @closed
        if !@http.nil?
          @http.finish()
          @http = nil
          @logger.info "the HTTP connection was closed: #{@message_server}"
        else
          @http = nil
          @logger.fatal "It was not possible to close the HTTP connection: #{@message_server}"
        end
        @closed = true
      else
        @logger.warn "It was not possible to close the HTTP connection, already closed: #{@message_server}"
      end
    rescue Exception => stack
      @logger.fatal stack
    end
    self.class.active -= 1
  end

  private :manage_request, :manage_response
end
