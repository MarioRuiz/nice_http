module NiceHttpManageResponse
  private

  def create_stats(resp)
    # all
    set_stats(self.class.stats[:all])
    # all method
    unless self.class.stats[:all][:method].key?(@prev_request[:method])
      self.class.stats[:all][:method][@prev_request[:method]] = {
        response: {},
      }
    end
    set_stats(self.class.stats[:all][:method][@prev_request[:method]])
    # all method response
    unless self.class.stats[:all][:method][@prev_request[:method]][:response].key?(resp.code)
      self.class.stats[:all][:method][@prev_request[:method]][:response][resp.code] = {}
    end
    set_stats(self.class.stats[:all][:method][@prev_request[:method]][:response][resp.code])

    # server
    server = "#{@host}:#{@port}"
    unless self.class.stats[:path].key?(server)
      self.class.stats[:path][server] = {}
    end
    set_stats(self.class.stats[:path][server])
    # server path
    unless self.class.stats[:path][server].key?(@prev_request[:path])
      self.class.stats[:path][server][@prev_request[:path]] = { method: {} }
    end
    set_stats(self.class.stats[:path][server][@prev_request[:path]])
    # server path method
    unless self.class.stats[:path][server][@prev_request[:path]][:method].key?(@prev_request[:method])
      self.class.stats[:path][server][@prev_request[:path]][:method][@prev_request[:method]] = {
        response: {},
      }
    end
    set_stats(self.class.stats[:path][server][@prev_request[:path]][:method][@prev_request[:method]])
    # server path method response
    unless self.class.stats[:path][server][@prev_request[:path]][:method][@prev_request[:method]][:response].key?(resp.code)
      self.class.stats[:path][server][@prev_request[:path]][:method][@prev_request[:method]][:response][resp.code] = {}
    end
    set_stats(self.class.stats[:path][server][@prev_request[:path]][:method][@prev_request[:method]][:response][resp.code])

    if @prev_request.key?(:name)
      # name
      unless self.class.stats[:name].key?(@prev_request[:name])
        self.class.stats[:name][@prev_request[:name]] = { method: {} }
      end
      set_stats(self.class.stats[:name][@prev_request[:name]])
      # name method
      unless self.class.stats[:name][@prev_request[:name]][:method].key?(@prev_request[:method])
        self.class.stats[:name][@prev_request[:name]][:method][@prev_request[:method]] = {
          response: {},
        }
      end
      set_stats(self.class.stats[:name][@prev_request[:name]][:method][@prev_request[:method]])
      # name method response
      unless self.class.stats[:name][@prev_request[:name]][:method][@prev_request[:method]][:response].key?(resp.code)
        self.class.stats[:name][@prev_request[:name]][:method][@prev_request[:method]][:response][resp.code] = {}
      end
      set_stats(self.class.stats[:name][@prev_request[:name]][:method][@prev_request[:method]][:response][resp.code])
    end
  end
end
