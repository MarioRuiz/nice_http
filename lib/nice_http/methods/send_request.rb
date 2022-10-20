module NiceHttpHttpMethods

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
