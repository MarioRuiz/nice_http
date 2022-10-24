class NiceHttp
  ######################################################
  # to reset to the original defaults
  ######################################################
  def self.reset!
    @host = nil
    @port = 80
    @ssl = false
    @timeout = nil
    @headers = {}
    @values_for = {}
    @debug = false
    @log = :fix_file
    @log_path = ""
    @log_headers = :all
    @proxy_host = nil
    @proxy_port = nil
    @last_request = nil
    @request = nil
    @requests = nil
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
    @async_wait_seconds = 0
    @async_header = "location"
    @async_completed = ""
    @async_resource = ""
    @async_status = ""
  end
end