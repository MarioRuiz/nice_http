require "logger"
require "nice_hash"
require_relative "nice_http/methods/get"
require_relative "nice_http/methods/post"
require_relative "nice_http/methods/head"
require_relative "nice_http/methods/put"
require_relative "nice_http/methods/delete"
require_relative "nice_http/methods/patch"
require_relative "nice_http/methods/send_request"
require_relative "nice_http/manage/create_stats"
require_relative "nice_http/manage/request"
require_relative "nice_http/manage/response"
require_relative "nice_http/manage/set_stats"
require_relative "nice_http/manage/wait_async_operation"
require_relative "nice_http/utils/basic_authentication"
require_relative "nice_http/utils/get_value_xml_tag"
require_relative "nice_http/utils/set_value_xml_tag"
require_relative "nice_http/reset"
require_relative "nice_http/add_stats"
require_relative "nice_http/defaults"
require_relative "nice_http/inherited"
require_relative "nice_http/save_stats"
require_relative "nice_http/close"
require_relative "nice_http/initialize"

######################################################
# Attributes you can access using NiceHttp.the_attribute:  
#   :host, :port, :ssl, :timeout, :headers, :debug, :log, :log_headers, :proxy_host, :proxy_port,  
#   :last_request, :last_response, :request_id, :use_mocks, :connections,  
#   :active, :auto_redirect, :values_for, :create_stats, :stats, :capture, :captured, :request, :requests,
#   :async_wait_seconds, :async_header, :async_completed, :async_resource, :async_status
#
# @attr [String] host The host to be accessed
# @attr [Integer] port The port number
# @attr [Boolean] ssl If you use ssl or not
# @attr [Integer] timeout Max time to wait until connected to the host or getting a response.
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
# @attr [String] log_file path and file name where the logs will be stored. (only reader)
# @attr [Symbol] log_headers. :all, :partial, :none (default :all) If :all will log all the headers. If :partial will log the last 10 characters. If :none no headers.
# @attr [String] proxy_host the proxy host to be used
# @attr [Integer] proxy_port the proxy port to be used
# @attr [String] last_request The last request with all the content sent
# @attr [String] last_response Only in case :debug is true, the last response with all the content
# @attr [Hash] request The last request with all the content sent
# @attr [Hash] requests The defaults for all requests. keys: :headers and :data
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
# @attr [Integer] async_wait_seconds Number of seconds to wait until the async request is completed
# @attr [String] async_header The header to check if the async request is completed
# @attr [String] async_completed The value of the async_header to check if the async request is completed
# @attr [String] async_resource The resource to check if the async request is completed
# @attr [String] async_status The status to check if the async request is completed
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
    attr_accessor :host, :port, :ssl, :timeout, :headers, :debug, :log_path, :log, :proxy_host, :proxy_port, :log_headers,
                  :last_request, :last_response, :request, :request_id, :use_mocks, :connections,
                  :active, :auto_redirect, :log_files, :values_for, :create_stats, :stats, :capture, :captured, :requests,
                  :async_wait_seconds, :async_header, :async_completed, :async_resource, :async_status
  end

  at_exit do
    if self.create_stats
      self.save_stats
    end
  end

  reset!

  attr_reader :host, :port, :ssl, :timeout, :debug, :log, :log_path, :proxy_host, :proxy_port, :response, :num_redirects, :log_file
  attr_accessor :headers, :cookies, :use_mocks, :auto_redirect, :logger, :values_for, :log_headers,
                :async_wait_seconds, :async_header, :async_completed, :async_resource, :async_status

  private :manage_request, :manage_response
end
