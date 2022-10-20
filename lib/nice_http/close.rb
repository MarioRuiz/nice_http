class NiceHttp
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
end
