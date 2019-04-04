module NiceHttpManageResponse

  ######################################################
  # private method to manage Response
  #   input:
  #     resp
  #     data
  #   output:
  #     @response updated
  ######################################################
  def manage_response(resp, data)
    @finish_time = Time.now
    require "json"
    @prev_response = Hash.new() if @prev_response.nil?
    begin
      if @start_time.kind_of?(Time)
        @response[:time_elapsed_total] = @finish_time - @start_time
      else
        @response[:time_elapsed_total] = nil
      end
      if @start_time_net.kind_of?(Time)
        @response[:time_elapsed] = @finish_time - @start_time_net
        @start_time_net = nil
      else
        @response[:time_elapsed] = nil
      end

      create_stats(resp) if @create_stats

      begin
        # this is to be able to access all keys as symbols
        new_resp = Hash.new()
        resp.each { |key, value|
          if key.kind_of?(String)
            new_resp[key.to_sym] = value
          end
        }
        new_resp.each { |key, value|
          resp[key] = value
        }
      rescue
      end
      #for mock_responses to be able to add outside of the header like content-type for example
      if resp.kind_of?(Hash) and !resp.has_key?(:header)
        resp[:header] = {}
      end

      #todo: check this. not sure if this is valid anymore since resp it will be a hash only when mock_response
      if resp.kind_of?(Hash)
        resp.each { |k, v|
          if k != :code and k != :message and k != :data and k != :'set-cookie' and k != :header
            resp[:header][k] = v
          end
        }
        resp[:header].each { |k, v|
          resp.delete(k) if resp.has_key?(k)
        }
      end

      method_s = caller[0].to_s().scan(/:in `(.*)'/).join
      if resp.header.kind_of?(Hash) and (resp.header["content-type"].to_s() == "application/x-deflate" or resp.header[:"content-type"].to_s() == "application/x-deflate")
        data = Zlib::Inflate.inflate(data)
      end
      encoding_response = ""
      if resp.header.kind_of?(Hash) and (resp.header["content-type"].to_s() != "" or resp.header[:"content-type"].to_s() != "")
        encoding_response = resp.header["content-type"].scan(/;charset=(.*)/i).join if resp.header.has_key?("content-type")
        encoding_response = resp.header[:"content-type"].scan(/;charset=(.*)/i).join if resp.header.has_key?(:"content-type")
      end
      if encoding_response.to_s() == ""
        encoding_response = "UTF-8"
      end

      if encoding_response.to_s() != "" and encoding_response.to_s().upcase != "UTF-8"
        data.encode!("UTF-8", encoding_response.to_s())
      end

      if encoding_response != "" and encoding_response.to_s().upcase != "UTF-8"
        @response[:message] = resp.message.to_s().encode("UTF-8", encoding_response.to_s())
        #todo: response data in here for example is convert into string, verify if that is correct or needs to maintain the original data type (hash, array...)
        resp.each { |key, val| @response[key.to_sym] = val.to_s().encode("UTF-8", encoding_response.to_s()) }
      else
        @response[:message] = resp.message
        resp.each { |key, val|
          @response[key.to_sym] = val
        }
      end

      if !defined?(Net::HTTP::Post::Multipart) or (defined?(Net::HTTP::Post::Multipart) and !data.kind_of?(Net::HTTP::Post::Multipart))
        @response[:data] = data
      else
        @response[:data] = ""
      end

      @response[:code] = resp.code
      message = "\nRESPONSE: \n " + @response[:code].to_s() + ":" + @response[:message].to_s()
      if @debug or @prev_response[:'content-type'] != @response[:'content-type'] or @prev_response[:'content-length'] != @response[:'content-length'] or
         @prev_response[:data] != @response[:data] or @prev_response[:code] != @response[:code] or @prev_response[:message] != @response[:message]
        self.class.last_response = message if @debug
        @response.each { |key, value|
          if value.to_s() != ""
            value_orig = value
            if key.kind_of?(Symbol)
              if key == :code or key == :data or key == :header or key == :message
                if key == :data and !@response[:'content-type'].to_s.include?("text/html")
                  begin
                    JSON.parse(value_orig)
                    data_s = JSON.pretty_generate(JSON.parse(value_orig))
                  rescue
                    data_s = value_orig
                  end
                  if @debug
                    self.class.last_response += "\n " + key.to_s() + ": '" + data_s.gsub("<", "&lt;") + "'\n"
                  end
                  if value_orig != value
                    message += "\n " + key.to_s() + ": '" + value.gsub("<", "&lt;") + "'\n"
                  else
                    message += "\n " + key.to_s() + ": '" + data_s.gsub("<", "&lt;") + "'\n"
                  end
                else
                  if @debug
                    self.class.last_response += "\n " + key.to_s() + ": '" + value.to_s().gsub("<", "&lt;") + "'"
                    message += "\n " + key.to_s() + ": '" + value.to_s().gsub("<", "&lt;") + "'"
                  end
                end
              else
                if @debug
                  self.class.last_response += "\n " + key.to_s() + ": '" + value.to_s().gsub("<", "&lt;") + "'"
                end
                message += "\n " + key.to_s() + ": '" + value.to_s().gsub("<", "&lt;") + "'"
              end
            elsif !@response.include?(key.to_sym)
              if @debug
                self.class.last_response += "\n " + key.to_s() + ": '" + value.to_s().gsub("<", "&lt;") + "'"
              end
              message += "\n " + key.to_s() + ": '" + value.to_s().gsub("<", "&lt;") + "'"
            end
          end
        }
      else
        message += "\n Same as the last response."
      end
      @logger.info message
      if @response.kind_of?(Hash)
        if @response.keys.include?(:requestid)
          @headers["requestId"] = @response[:requestid]
          self.class.request_id = @response[:requestid]
          @logger.info "requestId was found on the response header and it has been added to the headers for the next request"
        end
      end

      if resp[:'set-cookie'].to_s() != ""
        if resp.kind_of?(Hash) #mock_response
          cookies_to_set = resp[:'set-cookie'].to_s().split(", ")
        else #Net::Http
          cookies_to_set = resp.get_fields("set-cookie")
        end
        cookies_to_set.each { |cookie|
          cookie_pair = cookie.split("; ")[0].split("=")
          cookie_path = cookie.scan(/; path=([^;]+)/i).join
          @cookies[cookie_path] = Hash.new() unless @cookies.keys.include?(cookie_path)
          @cookies[cookie_path][cookie_pair[0]] = cookie_pair[1]
        }

        @logger.info "set-cookie added to Cookie header as required"

        if @headers.has_key?("X-CSRFToken")
          csrftoken = resp[:"set-cookie"].to_s().scan(/csrftoken=([\da-z]+);/).join
          if csrftoken.to_s() != ""
            @headers["X-CSRFToken"] = csrftoken
            @logger.info "X-CSRFToken exists on headers and has been overwritten"
          end
        else
          csrftoken = resp[:"set-cookie"].to_s().scan(/csrftoken=([\da-z]+);/).join
          if csrftoken.to_s() != ""
            @headers["X-CSRFToken"] = csrftoken
            @logger.info "X-CSRFToken added to header as required"
          end
        end
      end
      @prev_response = @response
    rescue Exception => stack
      @logger.fatal stack
      @logger.fatal "manage_response Error on method #{method_s} "
    end

    @start_time = nil
  end

  private

  def set_stats(hash)
    unless hash.key?(:num_requests)
      # to add to the end the previous keys so num_requests and time_elapsed come first
      keys = hash.keys
      hash.keys.each do |k|
        hash.delete(k)
      end

      hash[:num_requests] = 0
      hash[:started] = @start_time
      hash[:finished] = @start_time
      hash[:real_time_elapsed] = 0
      hash[:time_elapsed] = {
        total: 0,
        maximum: 0,
        minimum: 100000,
        average: 0,
      }

      # to add to the end the previous keys so num_requests and time_elapsed come first
      keys.each do |k|
        hash[k] = {}
      end
    end
    hash[:num_requests] += 1
    hash[:started] = hash[:finished] = @start_time if hash[:started].nil?

    if @start_time < hash[:finished]
      hash[:real_time_elapsed] += (@finish_time - hash[:finished])
    else
      hash[:real_time_elapsed] += (@finish_time - @start_time)
    end
    hash[:finished] = @finish_time

    hash[:time_elapsed][:total] += @response[:time_elapsed]
    hash[:time_elapsed][:maximum] = @response[:time_elapsed] if @response[:time_elapsed] > hash[:time_elapsed][:maximum]
    hash[:time_elapsed][:minimum] = @response[:time_elapsed] if @response[:time_elapsed] < hash[:time_elapsed][:minimum]
    hash[:time_elapsed][:average] = hash[:time_elapsed][:total] / hash[:num_requests]
  end

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
