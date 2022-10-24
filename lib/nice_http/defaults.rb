class NiceHttp
  ######################################################
  # Change the default values for NiceHttp supplying a Hash
  #
  # @param par [Hash] keys: :host, :port, :ssl, :timeout, :headers, :debug, :log, :log_path, :proxy_host, :proxy_port, :use_mocks, :auto_redirect, :values_for, :create_stats, :log_headers, :capture, :async_wait_seconds, :async_header, :async_completed, :async_resource, :async_status
  ######################################################
  def self.defaults=(par = {})
    @host = par[:host] if par.key?(:host)
    @port = par[:port] if par.key?(:port)
    @ssl = par[:ssl] if par.key?(:ssl)
    @timeout = par[:timeout] if par.key?(:timeout)
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
    @async_wait_seconds = par[:async_wait_seconds] if par.key?(:async_wait_seconds)
    @async_header = par[:async_header] if par.key?(:async_header)
    @async_completed = par[:async_completed] if par.key?(:async_completed)
    @async_resource = par[:async_resource] if par.key?(:async_resource)
    @async_status = par[:async_status] if par.key?(:async_status)    
  end
end
